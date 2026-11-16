//
//  HomeViewModel.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 03/08/2025.
//
import SwiftUI
import Combine

class MarketViewModel: ObservableObject {
    @Published var statistics: [StatisticModel] = []
    
    @Published var allCoins: [CoinModel] = []
    @Published var portfolioCoins: [CoinModel] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var sortOption: SortOption = .holdings
    
    @Published var portfolioTotalValue: Double = 0
    @Published var portfolioTotalInvested: Double = 0
    @Published var portfolioTotalProfitLoss: Double = 0
    @Published var portfolioTotalProfitLossPercentage: Double = 0
    @Published var portfolioProfit24H: Double = 0
    @Published var portfolioProfitPercentage24H: Double = 0
    @Published var marketCategory: MarketCategory = .all
    @Published var watchlistCoinIDs: Set<String> = []
    @Published var transactions: [TransactionEntity] = []
    @Published var cashBalance: Double = 0.0
    
    enum MarketCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case gainers = "Gainers"
        case losers = "Losers"
        case topTen = "Top 10"
        var id: String { rawValue }
    }
    
    var displayedCoins: [CoinModel] {
        switch marketCategory {
        case .all:
            return allCoins
        case .gainers:
            return allCoins.filter { ($0.priceChangePercentage24H ?? 0) > 0 }
                .sorted(by: { ($0.priceChangePercentage24H ?? 0) > ($1.priceChangePercentage24H ?? 0) })
        case .losers:
            return allCoins.filter { ($0.priceChangePercentage24H ?? 0) < 0 }
                .sorted(by: { ($0.priceChangePercentage24H ?? 0) < ($1.priceChangePercentage24H ?? 0) })
        case .topTen:
            return Array(allCoins.prefix(10))
        }
    }
    
    var watchlistCoins: [CoinModel] {
        allCoins.filter { watchlistCoinIDs.contains($0.id) }
    }
    
    var topMovers: [CoinModel] {
        topGainers
    }
    
    var topGainers: [CoinModel] {
        allCoins
            .filter { ($0.priceChangePercentage24H ?? 0) > 0 }
            .sorted(by: { ($0.priceChangePercentage24H ?? 0) > ($1.priceChangePercentage24H ?? 0) })
            .prefix(6)
            .map { $0 }
    }
    
    var topLosers: [CoinModel] {
        allCoins
            .filter { ($0.priceChangePercentage24H ?? 0) < 0 }
            .sorted(by: { ($0.priceChangePercentage24H ?? 0) < ($1.priceChangePercentage24H ?? 0) })
            .prefix(6)
            .map { $0 }
    }
    
    private let coinDataService = CoinDataService()
    private let marketDataService = MarketDataService()
    private let portfolioDataService = PortfolioDataService()
    private let watchlistDataService = WatchlistDataService()
    private let transactionDataService = TransactionDataService()
    private let walletDataService = WalletDataService()
    private var cancellables = Set<AnyCancellable>()
    
    enum SortOption {
        case rank, rankReversed, holdings, holdingsReversed, price , priceReversed
    }
    
    init(isForPreview: Bool = false) {
        if !isForPreview {
            addSubscribers()
        }
    }
    
    func addSubscribers() {
        // updates allCoins
        $searchText
            .combineLatest(coinDataService.$allCoins, $sortOption)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .map(filterAndSortCoins)
            .sink { [weak self] (returnedCoins) in
                self?.allCoins = returnedCoins
            }
            .store(in: &cancellables)
        
        // updates watchlist from Core Data
        watchlistDataService.$savedEntities
            .sink { [weak self] (entities) in
                self?.watchlistCoinIDs = Set(entities.compactMap { $0.coinID })
            }
            .store(in: &cancellables)
        
        // updates transactions from Core Data
        transactionDataService.$savedTransactions
            .sink { [weak self] (transactions) in
                self?.transactions = transactions
            }
            .store(in: &cancellables)
        
        // updates cash wallet balance
        walletDataService.$cashBalance
            .sink { [weak self] balance in
                self?.cashBalance = balance
            }
            .store(in: &cancellables)
        
        // updates portfolioCoins with latest coins, entities, and transactions
        Publishers.CombineLatest3($allCoins, portfolioDataService.$savedEntities, transactionDataService.$savedTransactions)
            .map { [weak self] (allCoins, entities, txs) -> [CoinModel] in
                guard let self = self else { return [] }
                return self.mapAllCoinsToPortfolio(allCoins: allCoins, portfolioEntities: entities, transactions: txs)
            }
            .sink { [weak self] (returnedCoins) in
                guard let self = self else { return }
                let sorted = self.sortPortfolioCoinsIfNeeded(coins: returnedCoins)
                self.portfolioCoins = sorted
                self.updatePortfolioMetrics(coins: sorted)
            }
            .store(in: &cancellables)
        
        // updates marketData
        marketDataService.$marketData
            .combineLatest($portfolioCoins)
            .map(mapGlobalMarketData)
            .sink { [weak self] (returnedStats) in
                self?.statistics = returnedStats
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    // MARK: Helper func
    
    func updatePortfolio(coin: CoinModel, amount: Double) {
        let invested = amount * coin.currentPrice
        portfolioDataService.updatePortfolio(
            coin: coin,
            amount: amount,
            investedAmount: invested,
            averageBuyPrice: coin.currentPrice
        )
    }
    
    func deleteHolding(coin: CoinModel) {
        portfolioDataService.updatePortfolio(
            coin: coin,
            amount: 0,
            investedAmount: 0,
            averageBuyPrice: 0
        )
    }
    
    @discardableResult
    func executeOrder(coin: CoinModel, type: TransactionType, amount: Double, pricePerCoin: Double) -> Bool {
        guard amount > 0 else { return false }
        let existingHolding = portfolioCoins.first(where: { $0.id == coin.id })
        let currentHolding = existingHolding?.currentHoldings ?? 0
        let currentInvested = existingHolding?.investedAmount ?? (currentHolding * pricePerCoin)
        let totalCost = amount * pricePerCoin
        
        switch type {
        case .buy:
            // Check cash wallet balance
            guard walletDataService.deduct(amount: totalCost) else {
                return false
            }
            let newAmount = currentHolding + amount
            let newInvested = currentInvested + totalCost
            let newAvgPrice = newAmount > 0 ? (newInvested / newAmount) : pricePerCoin
            
            portfolioDataService.updatePortfolio(
                coin: coin,
                amount: newAmount,
                investedAmount: newInvested,
                averageBuyPrice: newAvgPrice
            )
            transactionDataService.addTransaction(coin: coin, type: .buy, amount: amount, pricePerCoin: pricePerCoin)
            return true
            
        case .sell:
            guard currentHolding >= amount else { return false }
            let newAmount = max(0, currentHolding - amount)
            
            if newAmount <= 0.00000001 {
                portfolioDataService.updatePortfolio(
                    coin: coin,
                    amount: 0,
                    investedAmount: 0,
                    averageBuyPrice: 0
                )
            } else {
                let currentAvgPrice = (currentHolding > 0 && currentInvested > 0) ? (currentInvested / currentHolding) : pricePerCoin
                let newInvested = newAmount * currentAvgPrice
                portfolioDataService.updatePortfolio(
                    coin: coin,
                    amount: newAmount,
                    investedAmount: newInvested,
                    averageBuyPrice: currentAvgPrice
                )
            }
            walletDataService.credit(amount: totalCost)
            transactionDataService.addTransaction(coin: coin, type: .sell, amount: amount, pricePerCoin: pricePerCoin)
            return true
            
        case .deposit, .withdraw:
            return false
        }
    }
    
    func depositCash(amount: Double) {
        guard amount > 0 else { return }
        walletDataService.deposit(amount: amount)
        transactionDataService.addCustomTransaction(
            coinID: "usd-cash",
            coinName: "USD Cash Deposit",
            coinSymbol: "USD",
            type: .deposit,
            amount: amount,
            pricePerCoin: 1.0,
            totalValue: amount
        )
    }
    
    @discardableResult
    func withdrawCash(amount: Double) -> Bool {
        guard amount > 0 && cashBalance >= amount else { return false }
        let success = walletDataService.withdraw(amount: amount)
        if success {
            transactionDataService.addCustomTransaction(
                coinID: "usd-cash",
                coinName: "USD Cash Withdrawal",
                coinSymbol: "USD",
                type: .withdraw,
                amount: amount,
                pricePerCoin: 1.0,
                totalValue: amount
            )
        }
        return success
    }
    
    func resetCashWallet(to amount: Double = 10_000.0) {
        walletDataService.resetBalance(amount: amount)
    }
    
    func deleteTransaction(_ entity: TransactionEntity) {
        let coinID = entity.coinID
        transactionDataService.deleteTransaction(entity: entity)
        if let coinID = coinID, let coin = allCoins.first(where: { $0.id == coinID }) {
            recalculatePortfolio(for: coin)
        }
    }
    
    func updateTransactionAndRecalculate(
        id: String,
        coin: CoinModel,
        type: TransactionType,
        amount: Double,
        pricePerCoin: Double,
        timestamp: Date
    ) {
        if transactions.contains(where: { $0.id == id }) {
            transactionDataService.updateTransaction(
                id: id,
                type: type,
                amount: amount,
                pricePerCoin: pricePerCoin,
                timestamp: timestamp
            )
        } else {
            transactionDataService.addTransaction(
                coin: coin,
                type: type,
                amount: amount,
                pricePerCoin: pricePerCoin,
                timestamp: timestamp
            )
        }
        
        recalculatePortfolio(for: coin)
    }
    
    func recalculatePortfolio(for coin: CoinModel) {
        let coinTxs = transactionDataService.savedTransactions.filter { $0.coinID == coin.id }
        if !coinTxs.isEmpty {
            var totalQty = 0.0
            var totalCost = 0.0
            let sortedTxs = coinTxs.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
            for tx in sortedTxs {
                let txType = (tx.transactionType ?? "").uppercased()
                if txType == "BUY" {
                    totalQty += tx.amount
                    totalCost += tx.totalValue
                } else if txType == "SELL" {
                    let fraction = totalQty > 0 ? min(1.0, tx.amount / totalQty) : 1.0
                    totalCost -= totalCost * fraction
                    totalQty = max(0, totalQty - tx.amount)
                }
            }
            
            let avgPrice = totalQty > 0 ? (totalCost / totalQty) : coin.currentPrice
            portfolioDataService.updatePortfolio(
                coin: coin,
                amount: totalQty,
                investedAmount: totalCost,
                averageBuyPrice: avgPrice
            )
            
            if let idx = portfolioCoins.firstIndex(where: { $0.id == coin.id }) {
                portfolioCoins[idx] = coin.updateHoldings(amount: totalQty, investedAmount: totalCost, averageBuyPrice: avgPrice)
            }
        }
    }
    
    func clearAllTransactions() {
        transactionDataService.clearAllTransactions()
    }
    
    func loadMockTransactionsForPreview() {
        let cal = Calendar.current
        let now = Date()
        let context = transactionDataService.context
        
        let txs: [(coinID: String, name: String, symbol: String, type: TransactionType, amount: Double, price: Double, daysAgo: Int)] = [
            ("bitcoin", "Bitcoin", "BTC", .buy, 0.5, 50_000.0, 14),
            ("ethereum", "Ethereum", "ETH", .buy, 4.0, 3_000.0, 10),
            ("solana", "Solana", "SOL", .buy, 25.0, 120.0, 8),
            ("bitcoin", "Bitcoin", "BTC", .sell, 0.25, 65_000.0, 5),
            ("ethereum", "Ethereum", "ETH", .sell, 2.0, 2_600.0, 3),
            ("solana", "Solana", "SOL", .sell, 15.0, 180.0, 1)
        ]
        
        var mockEntities: [TransactionEntity] = []
        for item in txs {
            let entity = TransactionEntity(context: context)
            entity.id = UUID().uuidString
            entity.coinID = item.coinID
            entity.coinName = item.name
            entity.coinSymbol = item.symbol
            entity.transactionType = item.type.rawValue
            entity.amount = item.amount
            entity.pricePerCoin = item.price
            entity.totalValue = item.amount * item.price
            entity.timestamp = cal.date(byAdding: .day, value: -item.daysAgo, to: now) ?? now
            mockEntities.append(entity)
        }
        
        self.transactions = mockEntities.reversed()
    }
    
    func transactions(for coinID: String) -> [TransactionEntity] {
        transactions.filter { $0.coinID == coinID }
    }
    
    func portfolioShare(for coin: CoinModel) -> Double {
        guard portfolioTotalValue > 0 else { return 0 }
        return (coin.currentHoldingsValue / portfolioTotalValue) * 100.0
    }
    
    func isWatchlisted(coin: CoinModel) -> Bool {
        watchlistCoinIDs.contains(coin.id)
    }
    
    func toggleWatchlist(coin: CoinModel) {
        watchlistDataService.toggleWatchlist(coin: coin)
        HapticManager.notification(type: .success)
    }
    
    private func updatePortfolioMetrics(coins: [CoinModel]) {
        let total = coins.map { $0.currentHoldingsValue }.reduce(0, +)
        let totalInvested = coins.map { $0.costBasis }.reduce(0, +)
        let profitLoss = total - totalInvested
        let profitLossPct = totalInvested > 0 ? ((total - totalInvested) / totalInvested) * 100.0 : 0.0
        
        let previous = coins.map { coin -> Double in
            let pct = (coin.priceChangePercentage24H ?? 0) / 100.0
            guard pct > -1 else { return 0 }
            return coin.currentHoldingsValue / (1.0 + pct)
        }.reduce(0, +)
        
        self.portfolioTotalValue = total
        self.portfolioTotalInvested = totalInvested
        self.portfolioTotalProfitLoss = profitLoss
        self.portfolioTotalProfitLossPercentage = profitLossPct
        self.portfolioProfit24H = total - previous
        self.portfolioProfitPercentage24H = previous > 0 ? ((total - previous) / previous) * 100.0 : 0.0
    }
    
    func reloadData() {
        isLoading = true
        coinDataService.getCoins()
        marketDataService.getData()
        HapticManager.notification(type: .success)
    }
    
    private func filterAndSortCoins(text: String, coins: [CoinModel], sort: SortOption) -> [CoinModel] {
        var filteredCoins = filterCoins(text: text, coins: coins)
        sortCoins(sort: sort, coins: &filteredCoins)
        return filteredCoins
    }
    
    private func sortCoins(sort: SortOption, coins: inout [CoinModel]) {
        switch sort {
        case .rank, .holdings:
            coins.sort(by: { $0.rank < $1.rank })
        case .rankReversed, .holdingsReversed:
            coins.sort(by: { $0.rank > $1.rank })
        case .price:
            coins.sort(by: { $0.currentPrice > $1.currentPrice })
        case .priceReversed:
            coins.sort(by: { $0.currentPrice < $1.currentPrice })
        }
    }
    
    // Will only sort if needed
    private func sortPortfolioCoinsIfNeeded(coins: [CoinModel]) -> [CoinModel] {
        switch sortOption {
        case .holdings:
            return coins.sorted(by: { $0.currentHoldingsValue > $1.currentHoldingsValue })
        case .holdingsReversed:
            return coins.sorted(by: { $0.currentHoldingsValue < $1.currentHoldingsValue })
        default:
            return coins
        }
    }
    
    // filter data based on searchText else return all Coins
    private func filterCoins(text: String, coins: [CoinModel]) -> [CoinModel] {
        guard !text.isEmpty else { return coins }
        
        let lowercasedText = text.lowercased()
        return coins.filter { (coin) -> Bool in
            return coin.name.lowercased().contains(lowercasedText) || coin.symbol.lowercased().contains(lowercasedText) || coin.id.lowercased().contains(lowercasedText)
        }
    }
    
    private func mapAllCoinsToPortfolio(
        allCoins: [CoinModel],
        portfolioEntities: [PortfolioEntity],
        transactions: [TransactionEntity]
    ) -> [CoinModel] {
        allCoins
            .compactMap { (coin) -> CoinModel? in
                guard let entity = portfolioEntities.first(where: { $0.coinID == coin.id }), entity.amount > 0 else {
                    return nil
                }
                var invested = entity.storedInvestedAmount
                var avgPrice = entity.storedAverageBuyPrice
                
                // If entity has no invested amount recorded yet, calculate from logged transactions
                if invested <= 0 {
                    let coinTxs = transactions.filter { $0.coinID == coin.id }
                    if !coinTxs.isEmpty {
                        var runQty = 0.0
                        var runCost = 0.0
                        let sortedTxs = coinTxs.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
                        for tx in sortedTxs {
                            let type = (tx.transactionType ?? "").uppercased()
                            if type == "BUY" {
                                runQty += tx.amount
                                runCost += tx.totalValue
                            } else if type == "SELL" {
                                let fraction = runQty > 0 ? min(1.0, tx.amount / runQty) : 1.0
                                runCost -= runCost * fraction
                                runQty = max(0, runQty - tx.amount)
                            }
                        }
                        if runQty > 0 && runCost > 0 {
                            invested = runCost
                            avgPrice = runCost / runQty
                        }
                    }
                    if invested <= 0 {
                        invested = entity.amount * coin.currentPrice
                        avgPrice = coin.currentPrice
                    }
                }
                
                return coin.updateHoldings(
                    amount: entity.amount,
                    investedAmount: invested,
                    averageBuyPrice: avgPrice
                )
            }
    }
    
    private func mapGlobalMarketData(marketDataModel: MarketDataModel?, portfolioCoins: [CoinModel]) -> [StatisticModel] {
        var stats: [StatisticModel] = []
        guard let data = marketDataModel else { return stats }
        
        let marketCap = StatisticModel(title: "Market Cap", value: data.marketCap, percentageChange: data.marketCapChangePercentage24HUsd)
        let volume = StatisticModel(title: "24h Volume", value: data.volume)
        let btcDominance = StatisticModel(title: "BTC Dominance", value: data.btcDominance)
        
        let portfolioValue = portfolioCoins
            .map { $0.currentHoldingsValue }
            .reduce(0, +)
        
        let previousValue = portfolioCoins
            .map { coin -> Double in
                let pct = (coin.priceChangePercentage24H ?? 0) / 100
                guard pct > -1 else {
                    return 0
                }
                return coin.currentHoldingsValue / (1 + pct)
            }
            .reduce(0, +)
        
        let percentageChange: Double? = previousValue > 0
            ? (portfolioValue - previousValue) / previousValue
            : nil
        
        let portfolio = StatisticModel(
            title: "Portfolio Value",
            value: portfolioValue.asCurrencyWith2Decimals(),
            percentageChange: percentageChange
        )
        
        stats.append(contentsOf: [marketCap, volume, btcDominance, portfolio])
        
        return stats
    }
}
// MARK: - Realized Profit & Loss Tracking Models
struct RealizedTradeInfo: Identifiable, Equatable {
    var id: String { transactionID }
    let transactionID: String
    let coinID: String
    let coinSymbol: String
    let coinName: String
    let realizedPnL: Double
    let realizedPercentage: Double
    let costBasis: Double
    let saleProceeds: Double
    let sellAmount: Double
    let sellPrice: Double
    let avgCostPerUnit: Double
    let isProfitable: Bool
}

struct RealizedPortfolioPnLSummary: Equatable {
    let totalRealizedPnL: Double
    let totalRealizedPercentage: Double
    let totalCostBasis: Double
    let totalProceeds: Double
    let totalClosedTrades: Int
    let profitableTradesCount: Int
    let lossTradesCount: Int
    let totalRealizedGains: Double
    let totalRealizedLosses: Double
    let tradeDetails: [String: RealizedTradeInfo]
    
    var winRate: Double {
        totalClosedTrades > 0 ? (Double(profitableTradesCount) / Double(totalClosedTrades)) * 100.0 : 0.0
    }
    
    var isProfitable: Bool {
        totalRealizedPnL >= 0
    }
}

// MARK: - Realized P&L Calculation Extension
extension MarketViewModel {
    
    var realizedPnLSummary: RealizedPortfolioPnLSummary {
        calculateRealizedPnL()
    }
    
    func realizedInfo(for transactionID: String) -> RealizedTradeInfo? {
        realizedPnLSummary.tradeDetails[transactionID]
    }
    
    private func calculateRealizedPnL() -> RealizedPortfolioPnLSummary {
        var tradeDetails: [String: RealizedTradeInfo] = [:]
        var totalRealizedPnL: Double = 0.0
        var totalCostBasis: Double = 0.0
        var totalProceeds: Double = 0.0
        var totalClosedTrades: Int = 0
        var profitableCount: Int = 0
        var lossCount: Int = 0
        var totalRealizedGains: Double = 0.0
        var totalRealizedLosses: Double = 0.0
        
        // Exclude USD cash deposits & withdrawals, only process crypto trades
        let cryptoTxs = transactions.filter {
            let type = ($0.transactionType ?? "").uppercased()
            return ($0.coinID ?? "") != "usd-cash" && (type == "BUY" || type == "SELL")
        }
        
        // Group by coinID
        let groupedByCoin = Dictionary(grouping: cryptoTxs, by: { $0.coinID ?? "" })
        
        for (coinID, coinTxs) in groupedByCoin {
            guard !coinID.isEmpty else { continue }
            // Sort chronologically ascending (oldest first)
            let sorted = coinTxs.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
            
            var runningQty: Double = 0.0
            var runningCost: Double = 0.0
            
            for tx in sorted {
                let type = (tx.transactionType ?? "").uppercased()
                let txId = tx.id ?? UUID().uuidString
                let amount = tx.amount
                let price = tx.pricePerCoin
                let totalValue = tx.totalValue > 0 ? tx.totalValue : (amount * price)
                
                if type == "BUY" {
                    runningQty += amount
                    runningCost += totalValue
                } else if type == "SELL" {
                    let saleProceeds = totalValue
                    let costBasis: Double
                    let avgCostPerUnit: Double
                    
                    if runningQty > 0.00000001 && runningCost > 0 {
                        avgCostPerUnit = runningCost / runningQty
                        costBasis = min(runningCost, amount * avgCostPerUnit)
                        
                        let fraction = min(1.0, amount / runningQty)
                        runningCost = max(0, runningCost - (runningCost * fraction))
                        runningQty = max(0, runningQty - amount)
                    } else {
                        // Fallback if coins were held without logged historical buy entries
                        if let portfolioCoin = portfolioCoins.first(where: { $0.id == coinID }),
                           let avgPrice = portfolioCoin.averageBuyPrice, avgPrice > 0 {
                            avgCostPerUnit = avgPrice
                            costBasis = amount * avgPrice
                        } else {
                            avgCostPerUnit = price
                            costBasis = saleProceeds
                        }
                    }
                    
                    let pnl = saleProceeds - costBasis
                    let pnlPercent = costBasis > 0 ? (pnl / costBasis) * 100.0 : 0.0
                    let isProfit = pnl >= 0
                    
                    let tradeInfo = RealizedTradeInfo(
                        transactionID: txId,
                        coinID: coinID,
                        coinSymbol: (tx.coinSymbol ?? "").uppercased(),
                        coinName: tx.coinName ?? "",
                        realizedPnL: pnl,
                        realizedPercentage: pnlPercent,
                        costBasis: costBasis,
                        saleProceeds: saleProceeds,
                        sellAmount: amount,
                        sellPrice: price,
                        avgCostPerUnit: avgCostPerUnit,
                        isProfitable: isProfit
                    )
                    
                    tradeDetails[txId] = tradeInfo
                    totalRealizedPnL += pnl
                    totalCostBasis += costBasis
                    totalProceeds += saleProceeds
                    totalClosedTrades += 1
                    
                    if pnl > 0.001 {
                        profitableCount += 1
                        totalRealizedGains += pnl
                    } else if pnl < -0.001 {
                        lossCount += 1
                        totalRealizedLosses += abs(pnl)
                    }
                }
            }
        }
        
        let overallPercentage = totalCostBasis > 0 ? (totalRealizedPnL / totalCostBasis) * 100.0 : 0.0
        
        return RealizedPortfolioPnLSummary(
            totalRealizedPnL: totalRealizedPnL,
            totalRealizedPercentage: overallPercentage,
            totalCostBasis: totalCostBasis,
            totalProceeds: totalProceeds,
            totalClosedTrades: totalClosedTrades,
            profitableTradesCount: profitableCount,
            lossTradesCount: lossCount,
            totalRealizedGains: totalRealizedGains,
            totalRealizedLosses: totalRealizedLosses,
            tradeDetails: tradeDetails
        )
    }
}

