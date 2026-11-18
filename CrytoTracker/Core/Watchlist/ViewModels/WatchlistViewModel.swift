//
//  WatchlistViewModel.swift
//  CoinPilot
//
//  Created by Antigravity on 18/11/2026.
//

import SwiftUI
import Combine

@MainActor
final class WatchlistViewModel: ObservableObject {
    
    // MARK: - Enums
    
    enum ViewMode: String {
        case list, grid
    }
    
    enum FilterCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case gainers = "Gainers"
        case losers = "Losers"
        var id: String { rawValue }
    }
    
    enum SortOption: String, CaseIterable, Identifiable {
        case rank = "Rank"
        case changeHighLow = "Top 24h Gainers"
        case changeLowHigh = "Top 24h Dips"
        case priceHighLow = "Price (High to Low)"
        case priceLowHigh = "Price (Low to High)"
        case alphabetical = "Name (A-Z)"
        
        var id: String { rawValue }
    }
    
    enum AddFilterMode: String, CaseIterable, Identifiable {
        case all = "All"
        case notTracked = "Not Tracked"
        case tracked = "Tracked"
        var id: String { rawValue }
    }
    
    // MARK: - Published View State
    
    @Published var searchText: String = ""
    @Published var showSearchBar: Bool = false
    @Published var selectedCoinForDetail: CoinModel? = nil
    @Published var showAddCoinSheet: Bool = false
    @Published var viewMode: ViewMode = .list
    @Published var filterCategory: FilterCategory = .all
    @Published var sortOption: SortOption = .rank
    
    // Add Sheet View State
    @Published var addSheetSearchText: String = ""
    @Published var addSheetFilterMode: AddFilterMode = .all
    
    // MARK: - Synced Data from Market Layer
    
    @Published var allCoins: [CoinModel] = []
    @Published var watchlistCoinIDs: Set<String> = []
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
        
        self.allCoins = vm.allCoins
        self.watchlistCoinIDs = vm.watchlistCoinIDs
        self.isLoading = vm.isLoading
        
        vm.$allCoins
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coins in
                self?.allCoins = coins
            }
            .store(in: &cancellables)
        
        vm.$watchlistCoinIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                self?.watchlistCoinIDs = ids
            }
            .store(in: &cancellables)
        
        vm.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Derived Watchlist Coins
    
    var watchlistCoins: [CoinModel] {
        allCoins.filter { watchlistCoinIDs.contains($0.id) }
    }
    
    var filteredAndSortedWatchlist: [CoinModel] {
        var coins = watchlistCoins
        
        // Search filter
        if !searchText.isEmpty {
            let lower = searchText.lowercased()
            coins = coins.filter {
                $0.name.lowercased().contains(lower) ||
                $0.symbol.lowercased().contains(lower)
            }
        }
        
        // Category filter
        switch filterCategory {
        case .all:
            break
        case .gainers:
            coins = coins.filter { ($0.priceChangePercentage24H ?? 0) >= 0 }
        case .losers:
            coins = coins.filter { ($0.priceChangePercentage24H ?? 0) < 0 }
        }
        
        // Sorting
        switch sortOption {
        case .rank:
            coins.sort { $0.rank < $1.rank }
        case .changeHighLow:
            coins.sort { ($0.priceChangePercentage24H ?? 0) > ($1.priceChangePercentage24H ?? 0) }
        case .changeLowHigh:
            coins.sort { ($0.priceChangePercentage24H ?? 0) < ($1.priceChangePercentage24H ?? 0) }
        case .priceHighLow:
            coins.sort { $0.currentPrice > $1.currentPrice }
        case .priceLowHigh:
            coins.sort { $0.currentPrice < $1.currentPrice }
        case .alphabetical:
            coins.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        
        return coins
    }
    
    // MARK: - Watchlist Analytics & Pulse Metrics
    
    var averageChange24H: Double {
        let valid = watchlistCoins.compactMap { $0.priceChangePercentage24H }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0, +) / Double(valid.count)
    }
    
    var gainersCount: Int {
        watchlistCoins.filter { ($0.priceChangePercentage24H ?? 0) >= 0 }.count
    }
    
    var losersCount: Int {
        watchlistCoins.filter { ($0.priceChangePercentage24H ?? 0) < 0 }.count
    }
    
    var topPerformer: CoinModel? {
        watchlistCoins
            .filter { ($0.priceChangePercentage24H ?? 0) > 0 }
            .max(by: { ($0.priceChangePercentage24H ?? 0) < ($1.priceChangePercentage24H ?? 0) })
    }
    
    var topDip: CoinModel? {
        watchlistCoins
            .filter { ($0.priceChangePercentage24H ?? 0) < 0 }
            .min(by: { ($0.priceChangePercentage24H ?? 0) < ($1.priceChangePercentage24H ?? 0) })
    }
    
    var suggestedCoins: [CoinModel] {
        Array(allCoins.prefix(4))
    }
    
    // MARK: - Add Sheet Display Logic
    
    var displayedAddCoins: [CoinModel] {
        var coins = allCoins
        
        if !addSheetSearchText.isEmpty {
            let lower = addSheetSearchText.lowercased()
            coins = coins.filter {
                $0.name.lowercased().contains(lower) ||
                $0.symbol.lowercased().contains(lower)
            }
        }
        
        switch addSheetFilterMode {
        case .all:
            break
        case .notTracked:
            coins = coins.filter { !isWatchlisted(coin: $0) }
        case .tracked:
            coins = coins.filter { isWatchlisted(coin: $0) }
        }
        
        return coins
    }
    
    // MARK: - User Intent Actions
    
    func toggleWatchlist(coin: CoinModel) {
        marketViewModel?.toggleWatchlist(coin: coin)
    }
    
    func reloadData() {
        marketViewModel?.reloadData()
    }
    
    func isWatchlisted(coin: CoinModel) -> Bool {
        watchlistCoinIDs.contains(coin.id)
    }
    
    func toggleViewMode() {
        viewMode = viewMode == .list ? .grid : .list
        HapticManager.impact(style: .light)
    }
    
    func setFilterCategory(_ category: FilterCategory) {
        filterCategory = category
        HapticManager.impact(style: .light)
    }
    
    func resetCategoryFilter() {
        filterCategory = .all
    }
}
