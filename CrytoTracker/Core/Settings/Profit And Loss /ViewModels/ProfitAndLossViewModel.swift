//
//  ProfitAndLossViewModel.swift
//  CoinPilot
//
//  Created by Antigravity on 18/11/2026.
//

import SwiftUI
import Combine

// MARK: - Coin P&L Summary Model
struct CoinPnLSummary: Identifiable {
    var id: String { coinID }
    let coinID: String
    let coinName: String
    let coinSymbol: String
    let coinModel: CoinModel?
    
    // Realized metrics
    let totalRealizedPnL: Double
    let totalRealizedPercentage: Double
    let totalRealizedCostBasis: Double
    let totalRealizedProceeds: Double
    let totalRealizedQty: Double
    let realizedBuyAvgPrice: Double
    let sellAvgPrice: Double
    let closedTradesCount: Int
    
    // Unrealized metrics
    let currentHoldings: Double
    let currentPrice: Double
    let unrealizedCostBasis: Double
    let currentHoldingsValue: Double
    let unrealizedPnL: Double
    let unrealizedPercentage: Double
    let buyAvgPrice: Double
    let hasOpenPosition: Bool
    
    var netPnL: Double {
        totalRealizedPnL + (hasOpenPosition ? unrealizedPnL : 0.0)
    }
    
    var netPercentage: Double {
        let totalCost = totalRealizedCostBasis + (hasOpenPosition ? unrealizedCostBasis : 0.0)
        return totalCost > 0 ? (netPnL / totalCost) * 100.0 : 0.0
    }
    
    var hasRealizedActivity: Bool {
        closedTradesCount > 0
    }
    
    var hasUnrealizedActivity: Bool {
        closedTradesCount <= 0
    }
    
    var isNetProfitable: Bool {
        netPnL >= 0
    }
    
    var isRealizedProfitable: Bool {
        totalRealizedPnL >= 0
    }
    
    var isUnrealizedProfitable: Bool {
        unrealizedPnL >= 0
    }
}

// MARK: - Profit & Loss ViewModel
@MainActor
final class ProfitAndLossViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var searchText: String = ""
    @Published var selectedCoinForDetail: CoinModel? = nil
    @Published var isSpinning: Bool = false
    
    // Synced data from MarketViewModel
    @Published var transactions: [TransactionEntity] = []
    @Published var portfolioCoins: [CoinModel] = []
    @Published var allCoins: [CoinModel] = []
    @Published var isLoading: Bool = false
    
    // MARK: - Dependencies & Cancellables
    
    private(set) weak var marketViewModel: MarketViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(marketViewModel: MarketViewModel? = nil) {
        if let vm = marketViewModel {
            setMarketViewModel(vm)
        }
    }
    
    // MARK: - MarketViewModel Binding
    
    func setMarketViewModel(_ vm: MarketViewModel) {
        guard self.marketViewModel !== vm else { return }
        self.marketViewModel = vm
        cancellables.removeAll()
        
        self.transactions = vm.transactions
        self.portfolioCoins = vm.portfolioCoins
        self.allCoins = vm.allCoins
        self.isLoading = vm.isLoading
        
        vm.$transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] txs in
                self?.transactions = txs
            }
            .store(in: &cancellables)
        
        vm.$portfolioCoins
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coins in
                self?.portfolioCoins = coins
            }
            .store(in: &cancellables)
        
        vm.$allCoins
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coins in
                self?.allCoins = coins
            }
            .store(in: &cancellables)
        
        vm.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Filtered Transactions
    
    var cryptoTransactions: [TransactionEntity] {
        transactions.filter {
            let type = ($0.transactionType ?? "").uppercased()
            return ($0.coinID ?? "") != "usd-cash" && (type == "BUY" || type == "SELL")
        }
    }
    
    // MARK: - Realized P&L Summary Access
    
    var realizedPnLSummary: RealizedPortfolioPnLSummary {
        marketViewModel?.realizedPnLSummary ?? RealizedPortfolioPnLSummary(
            totalRealizedPnL: 0,
            totalRealizedPercentage: 0,
            totalCostBasis: 0,
            totalProceeds: 0,
            totalClosedTrades: 0,
            profitableTradesCount: 0,
            lossTradesCount: 0,
            totalRealizedGains: 0,
            totalRealizedLosses: 0,
            tradeDetails: [:]
        )
    }
    
    var portfolioTotalProfitLoss: Double {
        marketViewModel?.portfolioTotalProfitLoss ?? 0.0
    }
    
    var portfolioTotalProfitLossPercentage: Double {
        marketViewModel?.portfolioTotalProfitLossPercentage ?? 0.0
    }
    
    var portfolioTotalValue: Double {
        marketViewModel?.portfolioTotalValue ?? 0.0
    }
    
    var portfolioTotalInvested: Double {
        marketViewModel?.portfolioTotalInvested ?? 0.0
    }
    
    // MARK: - Coin P&L Summaries Generation
    
    var allCoinPnLSummaries: [CoinPnLSummary] {
        let summary = realizedPnLSummary
        
        // Find all unique coin IDs from both transactions and current portfolio
        var orderedCoinIDs: [String] = []
        for tx in cryptoTransactions {
            if let id = tx.coinID, !id.isEmpty, !orderedCoinIDs.contains(id) {
                orderedCoinIDs.append(id)
            }
        }
        for pCoin in portfolioCoins where (pCoin.currentHoldings ?? 0) > 0 {
            if !orderedCoinIDs.contains(pCoin.id) {
                orderedCoinIDs.append(pCoin.id)
            }
        }
        
        return orderedCoinIDs.compactMap { coinID in
            let coinTxs = cryptoTransactions.filter { $0.coinID == coinID }
            let liveCoin = allCoins.first { $0.id.lowercased() == coinID.lowercased() }
            let portfolioCoin = portfolioCoins.first { $0.id.lowercased() == coinID.lowercased() }
            
            let name = liveCoin?.name ?? coinTxs.first?.coinName ?? coinID.capitalized
            let symbol = (liveCoin?.symbol ?? coinTxs.first?.coinSymbol ?? "").uppercased()
            
            // Realized metrics from summary
            let coinRealizedTrades = summary.tradeDetails.values.filter { $0.coinID == coinID }
            let realizedPnL = coinRealizedTrades.map { $0.realizedPnL }.reduce(0, +)
            let realizedCostBasis = coinRealizedTrades.map { $0.costBasis }.reduce(0, +)
            let realizedProceeds = coinRealizedTrades.map { $0.saleProceeds }.reduce(0, +)
            let realizedQty = coinRealizedTrades.map { $0.sellAmount }.reduce(0, +)
            let sellAvg = realizedQty > 0 ? (realizedProceeds / realizedQty) : 0.0
            let realizedBuyAvg = realizedQty > 0 ? (realizedCostBasis / realizedQty) : 0.0
            let realizedPct = realizedCostBasis > 0 ? (realizedPnL / realizedCostBasis) * 100.0 : 0.0
            let closedCount = coinRealizedTrades.count
            
            // Unrealized metrics from portfolio / holdings
            let holdings = portfolioCoin?.currentHoldings ?? 0.0
            let hasOpenPos = holdings > 0.00000001
            let curPrice = liveCoin?.currentPrice ?? portfolioCoin?.currentPrice ?? 0.0
            let holdingsVal = hasOpenPos ? (portfolioCoin?.currentHoldingsValue ?? (holdings * curPrice)) : 0.0
            let unCostBasis = hasOpenPos ? (portfolioCoin?.costBasis ?? (holdings * (portfolioCoin?.averageBuyPrice ?? curPrice))) : 0.0
            let unPnL = hasOpenPos ? (portfolioCoin?.profitLoss ?? (holdingsVal - unCostBasis)) : 0.0
            let unPct = hasOpenPos ? (portfolioCoin?.profitLossPercentage ?? (unCostBasis > 0 ? (unPnL / unCostBasis) * 100.0 : 0.0)) : 0.0
            let buyAvg = hasOpenPos ? (portfolioCoin?.averageBuyPrice ?? (holdings > 0 ? unCostBasis / holdings : curPrice)) : 0.0
            
            // Exclude coins with zero realized and zero open position
            guard closedCount > 0 || hasOpenPos else {
                return nil
            }
            
            return CoinPnLSummary(
                coinID: coinID,
                coinName: name,
                coinSymbol: symbol,
                coinModel: liveCoin ?? portfolioCoin,
                totalRealizedPnL: realizedPnL,
                totalRealizedPercentage: realizedPct,
                totalRealizedCostBasis: realizedCostBasis,
                totalRealizedProceeds: realizedProceeds,
                totalRealizedQty: realizedQty,
                realizedBuyAvgPrice: realizedBuyAvg,
                sellAvgPrice: sellAvg,
                closedTradesCount: closedCount,
                currentHoldings: holdings,
                currentPrice: curPrice,
                unrealizedCostBasis: unCostBasis,
                currentHoldingsValue: holdingsVal,
                unrealizedPnL: unPnL,
                unrealizedPercentage: unPct,
                buyAvgPrice: buyAvg,
                hasOpenPosition: hasOpenPos
            )
        }
    }
    
    var filteredCoinPnLList: [CoinPnLSummary] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return allCoinPnLSummaries }
        let lower = trimmed.lowercased()
        return allCoinPnLSummaries.filter {
            $0.coinName.lowercased().contains(lower) ||
            $0.coinSymbol.lowercased().contains(lower)
        }
    }
    
    // MARK: - Overall Portfolio Profitability
    
    var isOverallProfitable: Bool {
        (realizedPnLSummary.totalRealizedPnL + portfolioTotalProfitLoss) >= 0
    }
    
    // MARK: - Summary Card Aggregate Metrics
    
    var totalCryptoVolume: Double {
        cryptoTransactions
            .map { $0.totalValue }
            .reduce(0, +)
    }
    
    var totalBuyCount: Int {
        cryptoTransactions.filter { ($0.transactionType ?? "").uppercased() == "BUY" }.count
    }
    
    var totalSellCount: Int {
        cryptoTransactions.filter { ($0.transactionType ?? "").uppercased() == "SELL" }.count
    }
    
    var openHoldingsCount: Int {
        portfolioCoins.filter { ($0.currentHoldings ?? 0) > 0 }.count
    }
    
    var hasClosedTrades: Bool {
        realizedPnLSummary.totalClosedTrades > 0
    }
    
    var hasOpenPositions: Bool {
        openHoldingsCount > 0
    }
    
    var hasAnyActivity: Bool {
        hasClosedTrades || hasOpenPositions
    }
    
    var netPnL: Double {
        realizedPnLSummary.totalRealizedPnL + portfolioTotalProfitLoss
    }
    
    var totalInvestedBasis: Double {
        realizedPnLSummary.totalCostBasis + portfolioTotalInvested
    }
    
    var netPercentage: Double {
        totalInvestedBasis > 0 ? (netPnL / totalInvestedBasis) * 100.0 : 0.0
    }
    
    var isNetProfitable: Bool {
        netPnL >= 0
    }
    
    var isRealizedProfitable: Bool {
        realizedPnLSummary.isProfitable
    }
    
    var isUnrealizedProfitable: Bool {
        portfolioTotalProfitLoss >= 0
    }
    
    // MARK: - User Intent Actions
    
    func refreshData() {
        HapticManager.notification(type: .success)
        withAnimation(.easeInOut(duration: 0.6)) {
            isSpinning.toggle()
        }
        marketViewModel?.reloadData()
    }
}
