//
//  HomeViewModel.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 03/08/2025.
//
import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var statistics: [StatisticModel] = []
    
    @Published var allCoins: [CoinModel] = []
    @Published var portfolioCoins: [CoinModel] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var sortOption: SortOption = .holdings
    
    @Published var portfolioTotalValue: Double = 0
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
        allCoins
            .filter { ($0.priceChangePercentage24H ?? 0) > 0 }
            .sorted(by: { ($0.priceChangePercentage24H ?? 0) > ($1.priceChangePercentage24H ?? 0) })
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
    
    init() {
        addSubscribers()
    }
    
    
    func addSubscribers() {
        // updates allCoins
        $searchText
            //using .combineLatest we are subcribing to 2 publisher at same time
            .combineLatest(coinDataService.$allCoins, $sortOption)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .map(filterAndSortCoins)
            .sink { [weak self] (returnedCoins) in
                self?.allCoins = returnedCoins
            }
            .store(in: &cancellables)
        
        // updates portfolioCoins
        $allCoins
            .combineLatest(portfolioDataService.$savedEntities)
            .map(mapAllCoinsToPortfolio)
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
    }
    
    // MARK: Helper func
    
    func updatePortfolio(coin: CoinModel, amount: Double) {
        portfolioDataService.updatePortfolio(coin: coin, amount: amount)
    }
    
    func deleteHolding(coin: CoinModel) {
        portfolioDataService.updatePortfolio(coin: coin, amount: 0)
    }
    
    @discardableResult
    func executeOrder(coin: CoinModel, type: TransactionType, amount: Double, pricePerCoin: Double) -> Bool {
        guard amount > 0 else { return false }
        let currentHolding = portfolioCoins.first(where: { $0.id == coin.id })?.currentHoldings ?? 0
        let totalCost = amount * pricePerCoin
        
        switch type {
        case .buy:
            // Check cash wallet balance
            guard walletDataService.deduct(amount: totalCost) else {
                return false
            }
            updatePortfolio(coin: coin, amount: currentHolding + amount)
            transactionDataService.addTransaction(coin: coin, type: .buy, amount: amount, pricePerCoin: pricePerCoin)
            return true
            
        case .sell:
            guard currentHolding >= amount else { return false }
            let newAmount = max(0, currentHolding - amount)
            updatePortfolio(coin: coin, amount: newAmount)
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
        transactionDataService.deleteTransaction(entity: entity)
    }
    
    func clearAllTransactions() {
        transactionDataService.clearAllTransactions()
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
        let previous = coins.map { coin -> Double in
            let pct = (coin.priceChangePercentage24H ?? 0) / 100.0
            guard pct > -1 else { return 0 }
            return coin.currentHoldingsValue / (1.0 + pct)
        }.reduce(0, +)
        
        self.portfolioTotalValue = total
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
    
    // MARK: - Lesson (inout usage)
    // Normally, if we return a new [CoinModel], it creates a fresh array → O(N) extra space.
    // Using `inout` modifies the passed array directly → O(1) extra space.
    // This is more efficient since no additional memory is allocated for a new array.

    //Before: private func sortCoins(sort: SortOption, coins: [CoinModel]) -> [CoinModel] {
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
    
    private func mapAllCoinsToPortfolio(allCoins: [CoinModel], portfolioEntities: [PortfolioEntity]) -> [CoinModel] {
        allCoins
            .compactMap { (coin) -> CoinModel? in
            guard let entity = portfolioEntities.first(where: { $0.coinID == coin.id }) else {
                return nil
            }
            return coin.updateHoldings(amount: entity.amount)
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
                // Guard against -100% (division by zero)
                guard pct > -1 else {
                    // Option A: treat as a total wipeout previously (previous = 0)
                    return 0
                    // Option B: skip coin (return 0 and rely on others)
                    // return 0
                    // Option C: treat as undefined and fallback to current (less accurate)
                    // return coin.currentHoldingsValue
                }
                return coin.currentHoldingsValue / (1 + pct)
            }
            .reduce(0, +)
        
        // Avoid dividing by zero when previousValue == 0
        let percentageChange: Double? = previousValue > 0
            ? (portfolioValue - previousValue) / previousValue
            : nil // or 0 if you prefer a defined default
        
        let portfolio = StatisticModel(
            title: "Portfolio Value",
            value: portfolioValue.asCurrencyWith2Decimals(),
            percentageChange: percentageChange
        )
        
        stats.append(contentsOf: [marketCap, volume, btcDominance, portfolio])
        
        return stats
    }
    
    
    }
