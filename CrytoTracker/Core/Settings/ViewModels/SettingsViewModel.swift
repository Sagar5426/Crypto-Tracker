//
//  SettingsViewModel.swift
//  CoinPilot
//
//  Created by Antigravity on 18/11/2026.
//

import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Preferences & User Defaults State
    
    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "haptics_enabled") }
    }
    
    @Published var compactNumbers: Bool {
        didSet { UserDefaults.standard.set(compactNumbers, forKey: "compact_numbers") }
    }
    
    @Published var autoRefreshEnabled: Bool {
        didSet { UserDefaults.standard.set(autoRefreshEnabled, forKey: "auto_refresh_enabled") }
    }
    
    @Published var selectedCurrency: String {
        didSet { UserDefaults.standard.set(selectedCurrency, forKey: "selected_currency") }
    }
    
    // MARK: - Published UI & Alert States
    
    @Published var cachedImageCount: Int = 0
    @Published var showClearCacheAlert: Bool = false
    @Published var showResetWalletAlert: Bool = false
    @Published var toastMessage: String? = nil
    @Published var showCashWalletView: Bool = false
    @Published var showProfitAndLossView: Bool = false
    @Published var showTradeBookView: Bool = false
    
    // MARK: - Synced Market Data Properties
    
    @Published var cashBalance: Double = 0.0
    @Published var portfolioCoinsCount: Int = 0
    @Published var watchlistCoinsCount: Int = 0
    @Published var cryptoTradesCount: Int = 0
    @Published var netTotalPnL: Double = 0.0
    @Published var isLoading: Bool = false
    
    // MARK: - Constants
    
    let supportedCurrencies: [String] = [
        "USD ($)", "EUR (€)", "GBP (£)", "JPY (¥)", "CAD ($)", "AUD ($)", "INR (₹)"
    ]
    
    let coingeckoURL: URL = URL(string: "https://www.coingecko.com")!
    let coingeckoApiURL: URL = URL(string: "https://www.coingecko.com/en/api")!
    
    // MARK: - Dependencies & Cancellables
    
    private(set) weak var marketViewModel: MarketViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(marketViewModel: MarketViewModel? = nil) {
        let haptics = UserDefaults.standard.object(forKey: "haptics_enabled") == nil ? true : UserDefaults.standard.bool(forKey: "haptics_enabled")
        self.hapticsEnabled = haptics
        
        self.compactNumbers = UserDefaults.standard.bool(forKey: "compact_numbers")
        
        let autoRefresh = UserDefaults.standard.object(forKey: "auto_refresh_enabled") == nil ? true : UserDefaults.standard.bool(forKey: "auto_refresh_enabled")
        self.autoRefreshEnabled = autoRefresh
        
        self.selectedCurrency = UserDefaults.standard.string(forKey: "selected_currency") ?? "USD ($)"
        
        self.cachedImageCount = LocalFileManager.instance.getFolderItemCount(folderName: "coin_images")
        
        if let vm = marketViewModel {
            setMarketViewModel(vm)
        }
    }
    
    // MARK: - MarketViewModel Binding
    
    func setMarketViewModel(_ vm: MarketViewModel) {
        guard self.marketViewModel !== vm else { return }
        self.marketViewModel = vm
        cancellables.removeAll()
        
        updateMetrics(from: vm)
        
        // Subscribe to changes
        Publishers.CombineLatest4(vm.$cashBalance, vm.$portfolioCoins, vm.$watchlistCoinIDs, vm.$transactions)
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak vm] _, _, _, _ in
                guard let self = self, let vm = vm else { return }
                self.updateMetrics(from: vm)
            }
            .store(in: &cancellables)
        
        vm.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &cancellables)
    }
    
    private func updateMetrics(from vm: MarketViewModel) {
        self.cashBalance = vm.cashBalance
        self.portfolioCoinsCount = vm.portfolioCoins.count
        self.watchlistCoinsCount = vm.watchlistCoins.count
        self.cryptoTradesCount = vm.transactions.filter {
            let type = ($0.transactionType ?? "").uppercased()
            return ($0.coinID ?? "") != "usd-cash" && (type == "BUY" || type == "SELL")
        }.count
        self.netTotalPnL = vm.realizedPnLSummary.totalRealizedPnL + vm.portfolioTotalProfitLoss
    }
    
    // MARK: - User Intent Actions
    
    func updateCacheCount() {
        cachedImageCount = LocalFileManager.instance.getFolderItemCount(folderName: "coin_images")
    }
    
    func clearImageCache() {
        LocalFileManager.instance.clearFolder(folderName: "coin_images")
        updateCacheCount()
        HapticManager.notification(type: .success)
        showToast("Image cache cleared successfully!")
    }
    
    func resetCashWallet() {
        marketViewModel?.resetCashWallet(to: 10_000.0)
        HapticManager.notification(type: .success)
        showToast("Cash balance reset to $10,000.00!")
    }
    
    func refreshMarketData() {
        marketViewModel?.reloadData()
        showToast("Market data synced!")
    }
    
    func openCashWallet() {
        showCashWalletView = true
        HapticManager.impact(style: .light)
    }
    
    func showToast(_ text: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            toastMessage = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            withAnimation(.easeInOut(duration: 0.25)) {
                if self?.toastMessage == text {
                    self?.toastMessage = nil
                }
            }
        }
    }
}
