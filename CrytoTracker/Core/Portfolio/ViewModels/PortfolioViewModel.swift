//
//  PortfolioViewModel.swift
//  CoinPilot
//
//  Created by Antigravity on 18/11/2026.
//

import SwiftUI
import Combine

@MainActor
final class PortfolioViewModel: ObservableObject {
    
    // MARK: - Published View State
    
    @Published var showManageSheet: Bool = false
    @Published var selectedCoinToEdit: CoinModel? = nil
    @Published var coinToDelete: CoinModel? = nil
    @Published var showDeleteConfirmation: Bool = false
    @Published var selectedCoinForDetail: CoinModel? = nil
    @Published var showSearchBar: Bool = false
    @Published var searchText: String = ""
    
    // Synced state from MarketViewModel
    @Published var portfolioCoins: [CoinModel] = []
    @Published var portfolioTotalProfitLoss: Double = 0
    @Published var isLoading: Bool = false
    
    // MARK: - Dependencies & Subscriptions
    
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
        
        self.portfolioCoins = vm.portfolioCoins
        self.portfolioTotalProfitLoss = vm.portfolioTotalProfitLoss
        self.isLoading = vm.isLoading
        
        vm.$portfolioCoins
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coins in
                self?.portfolioCoins = coins
            }
            .store(in: &cancellables)
        
        vm.$portfolioTotalProfitLoss
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pnl in
                self?.portfolioTotalProfitLoss = pnl
            }
            .store(in: &cancellables)
        
        vm.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Domain Properties
    
    var displayedPortfolioCoins: [CoinModel] {
        if searchText.isEmpty {
            return portfolioCoins
        } else {
            let lower = searchText.lowercased()
            return portfolioCoins.filter {
                $0.name.lowercased().contains(lower) ||
                $0.symbol.lowercased().contains(lower)
            }
        }
    }
    
    /// Dynamic PnL color to influence ambient aura based on portfolio performance
    var pnlColor: Color {
        if portfolioCoins.isEmpty {
            return Color.theme.green
        }
        return portfolioTotalProfitLoss >= 0 ? Color.theme.green : Color.theme.red
    }
    
    // MARK: - User Intent Actions
    
    func reloadData() {
        marketViewModel?.reloadData()
    }
    
    func openManageSheet() {
        showManageSheet = true
    }
    
    func editHolding(for coin: CoinModel) {
        selectedCoinToEdit = coin
    }
    
    func promptDelete(for coin: CoinModel) {
        coinToDelete = coin
        showDeleteConfirmation = true
    }
    
    func confirmDeleteHolding() {
        guard let coin = coinToDelete else { return }
        withAnimation {
            marketViewModel?.deleteHolding(coin: coin)
        }
        HapticManager.notification(type: .success)
        coinToDelete = nil
        showDeleteConfirmation = false
    }
    
    func selectCoinForDetail(_ coin: CoinModel) {
        selectedCoinForDetail = coin
    }
}
