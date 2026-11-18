//
//  TradeBookViewModel.swift
//  CoinPilot
//
//  Created by Antigravity on 18/11/2026.
//

import SwiftUI
import Combine

@MainActor
final class TradeBookViewModel: ObservableObject {
    
    // MARK: - Filter & Sort Enums
    
    enum TradeFilterType: String, CaseIterable, Identifiable {
        case all = "All"
        case buys = "Buys"
        case sells = "Sells"
        
        var id: String { rawValue }
    }
    
    enum TradeSortOption: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case highestValue = "Highest Value"
        case lowestValue = "Lowest Value"
        case largestAmount = "Largest Quantity"
        
        var id: String { rawValue }
        
        var shortTitle: String {
            switch self {
            case .newest: return "Newest"
            case .oldest: return "Oldest"
            case .highestValue: return "High $"
            case .lowestValue: return "Low $"
            case .largestAmount: return "Qty"
            }
        }
    }
    
    // MARK: - Published State Properties
    
    @Published var searchText: String = ""
    @Published var selectedFilter: TradeFilterType = .all
    @Published var sortOption: TradeSortOption = .newest
    @Published var isSpinning: Bool = false
    
    // Navigation and Sheet presentation
    @Published var selectedTradeForDetail: TransactionEntity? = nil
    @Published var selectedCoinForDetail: CoinModel? = nil
    
    // Synced data from MarketViewModel
    @Published var transactions: [TransactionEntity] = []
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
        self.allCoins = vm.allCoins
        self.isLoading = vm.isLoading
        
        vm.$transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] txs in
                self?.transactions = txs
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
    
    // MARK: - Computed Trades Data
    
    /// All crypto buy and sell trades (excluding cash deposits and withdrawals)
    var cryptoTrades: [TransactionEntity] {
        transactions.filter {
            let type = ($0.transactionType ?? "").uppercased()
            return ($0.coinID ?? "") != "usd-cash" && (type == "BUY" || type == "SELL")
        }
    }
    
    /// Filtered and sorted trade orders list
    var filteredTrades: [TransactionEntity] {
        var list = cryptoTrades
        
        // 1. Filter by Trade Type
        switch selectedFilter {
        case .all:
            break
        case .buys:
            list = list.filter { ($0.transactionType ?? "").uppercased() == "BUY" }
        case .sells:
            list = list.filter { ($0.transactionType ?? "").uppercased() == "SELL" }
        }
        
        // 2. Search Query
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter {
                ($0.coinName ?? "").lowercased().contains(query) ||
                ($0.coinSymbol ?? "").lowercased().contains(query)
            }
        }
        
        // 3. Sort
        switch sortOption {
        case .newest:
            list.sort { ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) }
        case .oldest:
            list.sort { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
        case .highestValue:
            list.sort { $0.totalValue > $1.totalValue }
        case .lowestValue:
            list.sort { $0.totalValue < $1.totalValue }
        case .largestAmount:
            list.sort { $0.amount > $1.amount }
        }
        
        return list
    }
    
    // MARK: - Metrics Calculations
    
    var buyTrades: [TransactionEntity] {
        cryptoTrades.filter { ($0.transactionType ?? "").uppercased() == "BUY" }
    }
    
    var sellTrades: [TransactionEntity] {
        cryptoTrades.filter { ($0.transactionType ?? "").uppercased() == "SELL" }
    }
    
    var totalVolume: Double {
        cryptoTrades.map { $0.totalValue }.reduce(0, +)
    }
    
    var totalBuyVolume: Double {
        buyTrades.map { $0.totalValue }.reduce(0, +)
    }
    
    var totalSellVolume: Double {
        sellTrades.map { $0.totalValue }.reduce(0, +)
    }
    
    var buyRatio: Double {
        totalVolume > 0 ? (totalBuyVolume / totalVolume) : 0.5
    }
    
    var sellRatio: Double {
        totalVolume > 0 ? (totalSellVolume / totalVolume) : 0.5
    }
    
    func countFor(filter: TradeFilterType) -> Int {
        switch filter {
        case .all: return cryptoTrades.count
        case .buys: return buyTrades.count
        case .sells: return sellTrades.count
        }
    }
    
    func liveCoin(for trade: TransactionEntity) -> CoinModel? {
        guard let coinID = trade.coinID else { return nil }
        return allCoins.first { $0.id.lowercased() == coinID.lowercased() }
    }
    
    // MARK: - User Intent Actions
    
    func refreshData() {
        HapticManager.notification(type: .success)
        withAnimation(.easeInOut(duration: 0.6)) {
            isSpinning.toggle()
        }
        marketViewModel?.reloadData()
    }
    
    func resetFilters() {
        withAnimation {
            searchText = ""
            selectedFilter = .all
        }
    }
    
    func selectTradeForDetail(_ trade: TransactionEntity) {
        selectedTradeForDetail = trade
    }
    
    func viewCoinDetail(coin: CoinModel) {
        selectedTradeForDetail = nil
        selectedCoinForDetail = coin
    }
}
