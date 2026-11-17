//
//  MarketScreenViewModel.swift
//  CrytoTracker
//
//  Created by Antigravity on 18/11/2026.
//

import SwiftUI
import Combine

@MainActor
final class MarketScreenViewModel: ObservableObject {
    
    // MARK: - Published View State
    
    @Published var showSearchBar: Bool = false
    @Published var selectedCoinForDetail: CoinModel? = nil
    @Published var searchText: String = "" {
        didSet {
            if marketViewModel?.searchText != searchText {
                marketViewModel?.searchText = searchText
            }
        }
    }
    
    @Published var marketCategory: MarketViewModel.MarketCategory = .all
    @Published var sortOption: MarketViewModel.SortOption = .holdings
    @Published var displayedCoins: [CoinModel] = []
    @Published var topMovers: [CoinModel] = []
    @Published var topLosers: [CoinModel] = []
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
        
        syncFromMarketViewModel(vm)
        
        // Subscribe to objectWillChange to catch any updates from services/combine
        vm.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak vm] _ in
                guard let self = self, let vm = vm else { return }
                self.syncFromMarketViewModel(vm)
            }
            .store(in: &cancellables)
        
        // Specifically listen for search text modifications from outside
        vm.$searchText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                if self?.searchText != text {
                    self?.searchText = text
                }
            }
            .store(in: &cancellables)
    }
    
    private func syncFromMarketViewModel(_ vm: MarketViewModel) {
        self.displayedCoins = vm.displayedCoins
        self.topMovers = vm.topMovers
        self.topLosers = vm.topLosers
        self.sortOption = vm.sortOption
        self.marketCategory = vm.marketCategory
        self.isLoading = vm.isLoading
    }
    
    // MARK: - User Intent Actions
    
    func reloadData() {
        marketViewModel?.reloadData()
    }
    
    func selectCategory(_ category: MarketViewModel.MarketCategory) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            self.marketCategory = category
            marketViewModel?.marketCategory = category
            if let vm = marketViewModel {
                self.displayedCoins = vm.displayedCoins
            }
        }
        HapticManager.notification(type: .success)
    }
    
    func toggleRankSort() {
        let newSort: MarketViewModel.SortOption = (sortOption == .rank ? .rankReversed : .rank)
        withAnimation(.default) {
            self.sortOption = newSort
            marketViewModel?.sortOption = newSort
        }
    }
    
    func togglePriceSort() {
        let newSort: MarketViewModel.SortOption = (sortOption == .price ? .priceReversed : .price)
        withAnimation(.default) {
            self.sortOption = newSort
            marketViewModel?.sortOption = newSort
        }
    }
    
    func isWatchlisted(coin: CoinModel) -> Bool {
        marketViewModel?.isWatchlisted(coin: coin) ?? false
    }
    
    func toggleWatchlist(coin: CoinModel) {
        marketViewModel?.toggleWatchlist(coin: coin)
    }
    
    func selectCoinForDetail(_ coin: CoinModel) {
        selectedCoinForDetail = coin
    }
}

/// Convenience alias
typealias MarketsViewModel = MarketScreenViewModel
