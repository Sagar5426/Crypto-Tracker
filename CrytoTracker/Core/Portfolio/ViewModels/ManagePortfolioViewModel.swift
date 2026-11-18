//
//  ManagePortfolioViewModel.swift
//  CoinPilot
//
//  Created by Antigravity on 18/11/2026.
//

import SwiftUI
import Combine

@MainActor
final class ManagePortfolioViewModel: ObservableObject {
    
    // MARK: - Enums
    
    enum PortfolioTab: String, CaseIterable, Identifiable {
        case myHoldings = "My Holdings"
        case addAsset = "Explore All"
        var id: String { rawValue }
    }
    
    enum InputMode: String, CaseIterable, Identifiable {
        case fiat = "USD ($)"
        case token = "Coins"
        var id: String { rawValue }
    }
    
    enum AssetCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case top10 = "Top 10"
        case gainers = "Gainers"
        case losers = "Losers"
        var id: String { rawValue }
    }
    
    // MARK: - Published State
    
    @Published var activeCoin: CoinModel?
    @Published var selectedTab: PortfolioTab = .myHoldings
    @Published var searchText: String = ""
    @Published var filterCategory: AssetCategory = .all
    
    @Published var tradeType: TransactionType = .buy
    @Published var inputMode: InputMode = .fiat
    @Published var quantityText: String = ""
    @Published var fiatText: String = ""
    @Published var orderExecuted: Bool = false
    @Published var coinToDelete: CoinModel? = nil
    @Published var showDeleteConfirmation: Bool = false
    @Published var shouldDismiss: Bool = false
    
    // MARK: - Synced Data from Market/Data Layer
    
    @Published var portfolioCoins: [CoinModel] = []
    @Published var allCoins: [CoinModel] = []
    @Published var cashBalance: Double = 0.0
    
    // MARK: - Dependencies & Context
    
    let isDirectLaunch: Bool
    private(set) weak var marketViewModel: MarketViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(
        marketViewModel: MarketViewModel? = nil,
        initialCoin: CoinModel? = nil,
        initialTradeType: TransactionType = .buy
    ) {
        self.isDirectLaunch = (initialCoin != nil)
        self.activeCoin = initialCoin
        self.tradeType = initialTradeType
        
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
        self.allCoins = vm.allCoins
        self.cashBalance = vm.cashBalance
        
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
        
        vm.$cashBalance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cash in
                self?.cashBalance = cash
            }
            .store(in: &cancellables)
        
        vm.$transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties (Listings & Filtered Data)
    
    var filteredHoldings: [CoinModel] {
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
    
    var filteredAllCoins: [CoinModel] {
        var coins = allCoins
        
        switch filterCategory {
        case .all:
            break
        case .top10:
            coins = Array(coins.prefix(10))
        case .gainers:
            coins = coins.filter { ($0.priceChangePercentage24H ?? 0) > 0 }
                         .sorted(by: { ($0.priceChangePercentage24H ?? 0) > ($1.priceChangePercentage24H ?? 0) })
        case .losers:
            coins = coins.filter { ($0.priceChangePercentage24H ?? 0) < 0 }
                         .sorted(by: { ($0.priceChangePercentage24H ?? 0) < ($1.priceChangePercentage24H ?? 0) })
        }
        
        if !searchText.isEmpty {
            let lower = searchText.lowercased()
            coins = coins.filter {
                $0.name.lowercased().contains(lower) ||
                $0.symbol.lowercased().contains(lower)
            }
        }
        
        return coins
    }
    
    var portfolioTotalValue: Double {
        portfolioCoins.map({ $0.currentHoldingsValue }).reduce(0, +)
    }
    
    var themeColor: Color {
        tradeType == .buy ? Color.theme.green.opacity(0.8) : Color.theme.red
    }
    
    func portfolioShare(for coin: CoinModel) -> Double {
        guard portfolioTotalValue > 0 else { return 0 }
        return (coin.currentHoldingsValue / portfolioTotalValue) * 100
    }
    
    func isHeld(coin: CoinModel) -> Bool {
        portfolioCoins.contains(where: { $0.id == coin.id })
    }
    
    func transactions(for coinID: String) -> [TransactionEntity] {
        marketViewModel?.transactions(for: coinID) ?? []
    }
    
    // MARK: - Computed Properties (Active Trade Studio)
    
    var activePortfolioHolding: CoinModel? {
        guard let activeCoin = activeCoin else { return nil }
        return portfolioCoins.first(where: { $0.id == activeCoin.id })
    }
    
    var currentHolding: Double {
        activePortfolioHolding?.currentHoldings ?? 0
    }
    
    var currentInvested: Double {
        guard let activeCoin = activeCoin else { return 0 }
        return activePortfolioHolding?.investedAmount ?? (currentHolding * activeCoin.currentPrice)
    }
    
    var currentHoldingValue: Double {
        guard let activeCoin = activeCoin else { return 0 }
        return currentHolding * activeCoin.currentPrice
    }
    
    var tradeAmount: Double {
        Double(quantityText) ?? 0
    }
    
    var totalOrderValue: Double {
        guard let activeCoin = activeCoin else { return 0 }
        return tradeAmount * activeCoin.currentPrice
    }
    
    var resultingHolding: Double {
        tradeType == .buy ? (currentHolding + tradeAmount) : max(0, currentHolding - tradeAmount)
    }
    
    var isInsufficientBalance: Bool {
        tradeType == .sell && tradeAmount > currentHolding
    }
    
    var isInsufficientCash: Bool {
        tradeType == .buy && totalOrderValue > cashBalance
    }
    
    var canExecuteOrder: Bool {
        tradeAmount > 0 && !isInsufficientBalance && !isInsufficientCash
    }
    
    var projectedAverageBuyPrice: Double? {
        guard tradeType == .buy, tradeAmount > 0, let activeCoin = activeCoin else { return nil }
        let newInvested = currentInvested + totalOrderValue
        let newHolding = currentHolding + tradeAmount
        return newHolding > 0 ? (newInvested / newHolding) : activeCoin.currentPrice
    }
    
    var orderActionButtonTitle: String {
        guard let activeCoin = activeCoin else { return "" }
        let isBuy = tradeType == .buy
        if orderExecuted {
            return "Order Executed Successfully!"
        } else if tradeAmount <= 0 {
            return "Enter Amount to \(isBuy ? "Buy" : "Sell")"
        } else if isInsufficientCash {
            return "Insufficient Cash Funds"
        } else if isInsufficientBalance {
            return "Insufficient \(activeCoin.symbol.uppercased()) Balance"
        } else {
            return "\(isBuy ? "Buy" : "Sell") \(activeCoin.symbol.uppercased()) • \(totalOrderValue.asCurrencyWith2Decimals())"
        }
    }
    
    var activeCoinHistory: [TransactionEntity] {
        guard let activeCoin = activeCoin else { return [] }
        return transactions(for: activeCoin.id)
    }
    
    // MARK: - User Intent Actions
    
    func openTradeStudio(for coin: CoinModel, type: TransactionType) {
        activeCoin = coin
        tradeType = type
        quantityText = ""
        fiatText = ""
    }
    
    func closeTradeStudio() {
        if isDirectLaunch {
            shouldDismiss = true
        } else {
            activeCoin = nil
        }
    }
    
    func syncFromQuantity(newQty: String) {
        guard inputMode == .token, let activeCoin = activeCoin else { return }
        if let qty = Double(newQty) {
            fiatText = String(format: "%.2f", qty * activeCoin.currentPrice)
        } else {
            fiatText = ""
        }
    }
    
    func syncFromFiat(newFiat: String) {
        guard inputMode == .fiat, let activeCoin = activeCoin else { return }
        if let fiat = Double(newFiat), activeCoin.currentPrice > 0 {
            let qty = fiat / activeCoin.currentPrice
            quantityText = qty.asRawQuantityString()
        } else {
            quantityText = ""
        }
    }
    
    func addFiatAmount(delta: Double) {
        guard let activeCoin = activeCoin else { return }
        inputMode = .fiat
        let currentFiat = Double(fiatText) ?? 0
        let newFiat = currentFiat + delta
        fiatText = newFiat.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", newFiat) : String(format: "%.2f", newFiat)
        if activeCoin.currentPrice > 0 {
            let qty = newFiat / activeCoin.currentPrice
            quantityText = qty.asRawQuantityString()
        }
        HapticManager.notification(type: .success)
    }
    
    func setFiatAmount(amount: Double) {
        guard let activeCoin = activeCoin else { return }
        inputMode = .fiat
        fiatText = amount.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", amount) : String(format: "%.2f", amount)
        if activeCoin.currentPrice > 0 {
            let qty = amount / activeCoin.currentPrice
            quantityText = qty.asRawQuantityString()
        }
        HapticManager.notification(type: .success)
    }
    
    func setSellFraction(fraction: Double) {
        guard let activeCoin = activeCoin else { return }
        inputMode = .token
        let qtyToSell = currentHolding * fraction
        quantityText = qtyToSell.asRawQuantityString()
        fiatText = String(format: "%.2f", qtyToSell * activeCoin.currentPrice)
        HapticManager.notification(type: .success)
    }
    
    func clearInput() {
        fiatText = ""
        quantityText = ""
    }
    
    func executeTrade() {
        guard let coin = activeCoin, canExecuteOrder else { return }
        guard let marketVM = marketViewModel else { return }
        
        let success = marketVM.executeOrder(
            coin: coin,
            type: tradeType,
            amount: tradeAmount,
            pricePerCoin: coin.currentPrice
        )
        guard success else {
            HapticManager.notification(type: .error)
            return
        }
        
        withAnimation(.easeIn(duration: 0.2)) {
            orderExecuted = true
        }
        HapticManager.notification(type: .success)
        UIApplication.shared.endEditing()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self.orderExecuted = false
                self.quantityText = ""
                self.fiatText = ""
                if self.isDirectLaunch {
                    self.shouldDismiss = true
                } else {
                    self.activeCoin = nil
                }
            }
        }
    }
    
    func requestDeleteHolding(_ coin: CoinModel) {
        coinToDelete = coin
        showDeleteConfirmation = true
    }
    
    func deleteHoldingConfirmed() {
        guard let coin = coinToDelete else { return }
        marketViewModel?.deleteHolding(coin: coin)
        if activeCoin?.id == coin.id {
            activeCoin = nil
        }
        coinToDelete = nil
        showDeleteConfirmation = false
        HapticManager.notification(type: .success)
    }
}
