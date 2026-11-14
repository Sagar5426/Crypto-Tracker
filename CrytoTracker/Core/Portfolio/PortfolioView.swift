//
//  PortfolioView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 28/09/2025.
//

import SwiftUI

struct PortfolioView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: MarketViewModel
    
    // Initializer context
    private let initialCoin: CoinModel?
    private let initialTradeType: TransactionType
    
    // State
    @State private var activeCoin: CoinModel?
    @State private var selectedTab: PortfolioTab = .myHoldings
    @State private var searchText: String = ""
    @State private var filterCategory: AssetCategory = .all
    
    // Trade State
    @State private var tradeType: TransactionType = .buy
    @State private var inputMode: InputMode = .token
    @State private var quantityText: String = ""
    @State private var fiatText: String = ""
    @State private var orderExecuted: Bool = false
    @State private var coinToDelete: CoinModel? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    enum PortfolioTab: String, CaseIterable, Identifiable {
        case myHoldings = "My Holdings"
        case addAsset = "All Cryptos"
        var id: String { rawValue }
    }
    
    enum InputMode: String, CaseIterable, Identifiable {
        case token = "Coins"
        case fiat = "USD ($)"
        var id: String { rawValue }
    }
    
    enum AssetCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case top10 = "Top 10"
        case gainers = "Gainers"
        case losers = "Losers"
        var id: String { rawValue }
    }
    
    init(selectedCoin: CoinModel? = nil, initialTradeType: TransactionType = .buy) {
        self.initialCoin = selectedCoin
        self.initialTradeType = initialTradeType
        self._activeCoin = State(initialValue: selectedCoin)
        self._tradeType = State(initialValue: initialTradeType)
    }
    
    // Computed Lists
    private var filteredHoldings: [CoinModel] {
        if searchText.isEmpty {
            return vm.portfolioCoins
        } else {
            let lower = searchText.lowercased()
            return vm.portfolioCoins.filter {
                $0.name.lowercased().contains(lower) ||
                $0.symbol.lowercased().contains(lower)
            }
        }
    }
    
    private var filteredAllCoins: [CoinModel] {
        var coins = vm.allCoins
        
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                if let coin = activeCoin {
                    tradeStudioView(coin: coin)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    mainAssetListView
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: activeCoin?.id)
            .alert("Remove Holding", isPresented: $showDeleteConfirmation, presenting: coinToDelete) { coin in
                Button("Remove", role: .destructive) {
                    withAnimation {
                        vm.deleteHolding(coin: coin)
                        if activeCoin?.id == coin.id {
                            activeCoin = nil
                        }
                    }
                    HapticManager.notification(type: .success)
                }
                Button("Cancel", role: .cancel) { }
            } message: { coin in
                Text("Are you sure you want to remove \(coin.name) from your portfolio?")
            }
        }
    }
}

// MARK: - Main Asset List View
extension PortfolioView {
    
    private var mainAssetListView: some View {
        VStack(spacing: 12) {
            // Mode Picker
            Picker("Mode", selection: $selectedTab) {
                Text("My Holdings (\(vm.portfolioCoins.count))").tag(PortfolioTab.myHoldings)
                Text("All Cryptos").tag(PortfolioTab.addAsset)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 4)
            
            // Search Bar
            SearchBarView(searchText: $searchText)
                .padding(.vertical, -4)
            
            // Category Filter Pills (All Cryptos tab only)
            if selectedTab == .addAsset {
                categoryPillsBar
            }
            
            // Content List
            if selectedTab == .myHoldings {
                holdingsTabContent
            } else {
                addAssetTabContent
            }
        }
        .navigationTitle("Trade & Portfolio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.accent)
            }
        }
    }
    
    private var categoryPillsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AssetCategory.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            filterCategory = category
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(.caption)
                            .fontWeight(filterCategory == category ? .bold : .medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(filterCategory == category ? Color.theme.accent : Color.theme.secondaryText.opacity(0.1))
                            )
                            .foregroundStyle(filterCategory == category ? Color.theme.background : Color.theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Holdings List
    private var holdingsTabContent: some View {
        Group {
            if vm.portfolioCoins.isEmpty {
                emptyHoldingsState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredHoldings) { coin in
                            holdingListRow(coin: coin)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    private func holdingListRow(coin: CoinModel) -> some View {
        HStack(spacing: 12) {
            CoinImageView(coin: coin)
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(coin.symbol.uppercased())
                        .font(.headline)
                        .foregroundStyle(Color.theme.accent)
                    
                    Text("\(String(format: "%.1f%%", vm.portfolioShare(for: coin)))")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.theme.green.opacity(0.12))
                        .foregroundStyle(Color.theme.green)
                        .clipShape(Capsule())
                }
                
                Text(coin.name)
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(coin.currentHoldingsValue.asCurrencyWith2Decimals())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
                    .lineLimit(1)
                
                Text("\((coin.currentHoldings ?? 0).asNumberString()) \(coin.symbol.uppercased())")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
            }
            
            // Quick Trade Action Buttons
            HStack(spacing: 6) {
                Button {
                    openTradeStudio(for: coin, type: .buy)
                } label: {
                    Text("Buy")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.theme.green.opacity(0.15))
                        .foregroundStyle(Color.theme.green)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button {
                    openTradeStudio(for: coin, type: .sell)
                } label: {
                    Text("Sell")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.theme.red.opacity(0.15))
                        .foregroundStyle(Color.theme.red)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
        .contextMenu {
            Button {
                openTradeStudio(for: coin, type: .buy)
            } label: {
                Label("Buy \(coin.symbol.uppercased())", systemImage: "plus.circle")
            }
            
            Button {
                openTradeStudio(for: coin, type: .sell)
            } label: {
                Label("Sell \(coin.symbol.uppercased())", systemImage: "minus.circle")
            }
            
            Button(role: .destructive) {
                coinToDelete = coin
                showDeleteConfirmation = true
            } label: {
                Label("Remove Holding", systemImage: "trash")
            }
        }
    }
    
    private var emptyHoldingsState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.theme.accent.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.theme.accent)
            }
            
            Text("No Assets In Portfolio")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Text("Buy cryptocurrency to start tracking your holdings, live valuations, profit & loss, and trade history.")
                .font(.subheadline)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                withAnimation {
                    selectedTab = .addAsset
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Explore & Buy Cryptos")
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.background)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.theme.accent)
                .clipShape(Capsule())
            }
            .padding(.top, 4)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - All Cryptos Tab Content
    private var addAssetTabContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredAllCoins) { coin in
                    let isHeld = vm.portfolioCoins.contains(where: { $0.id == coin.id })
                    
                    HStack(spacing: 12) {
                        Text("\(coin.rank)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.theme.secondaryText)
                            .frame(width: 20, alignment: .leading)
                        
                        CoinImageView(coin: coin)
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(coin.symbol.uppercased())
                                .font(.headline)
                                .foregroundStyle(Color.theme.accent)
                            Text(coin.name)
                                .font(.caption2)
                                .foregroundStyle(Color.theme.secondaryText)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(coin.currentPrice.asFormattedPrice())
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.accent)
                            
                            Text(coin.priceChangePercentage24H?.asPercentString() ?? "0.0%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle((coin.priceChangePercentage24H ?? 0) >= 0 ? Color.theme.green : Color.theme.red)
                        }
                        
                        // Trade Button
                        Button {
                            openTradeStudio(for: coin, type: .buy)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isHeld ? "arrow.left.arrow.right" : "cart.fill.badge.plus")
                                Text(isHeld ? "Trade" : "Buy")
                            }
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.theme.accent)
                            .foregroundStyle(Color.theme.background)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.theme.background)
                            .shadow(color: Color.theme.accent.opacity(0.03), radius: 4, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Buy & Sell Trade Studio View
extension PortfolioView {
    
    private func tradeStudioView(coin: CoinModel) -> some View {
        let currentHolding = vm.portfolioCoins.first(where: { $0.id == coin.id })?.currentHoldings ?? 0
        let currentHoldingValue = currentHolding * coin.currentPrice
        let tradeAmount = Double(quantityText) ?? 0
        let totalOrderValue = tradeAmount * coin.currentPrice
        let resultingHolding = tradeType == .buy ? (currentHolding + tradeAmount) : max(0, currentHolding - tradeAmount)
        let isInsufficientBalance = tradeType == .sell && tradeAmount > currentHolding
        let isInsufficientCash = tradeType == .buy && totalOrderValue > vm.cashBalance
        let canExecuteOrder = tradeAmount > 0 && !isInsufficientBalance && !isInsufficientCash
        
        let coinHistory = vm.transactions(for: coin.id)
        
        return ScrollView {
            VStack(spacing: 16) {
                // Buy / Sell Selector
                buySellTabPicker
                
                // Coin Header Card
                coinHeaderCard(coin: coin, currentHolding: currentHolding, currentHoldingValue: currentHoldingValue)
                
                // Trade Order Input Box
                orderInputCard(coin: coin, currentHolding: currentHolding)
                
                // Order Impact & Execution Summary
                orderSummaryCard(
                    coin: coin,
                    tradeAmount: tradeAmount,
                    totalOrderValue: totalOrderValue,
                    currentHolding: currentHolding,
                    resultingHolding: resultingHolding,
                    isInsufficientBalance: isInsufficientBalance,
                    isInsufficientCash: isInsufficientCash
                )
                
                // Execution Action Button
                orderActionButton(
                    coin: coin,
                    tradeAmount: tradeAmount,
                    canExecute: canExecuteOrder,
                    isInsufficientBalance: isInsufficientBalance,
                    isInsufficientCash: isInsufficientCash
                )
                
                // Coin Specific Transaction History
                if !coinHistory.isEmpty {
                    coinTradeHistorySection(transactions: coinHistory, symbol: coin.symbol.uppercased())
                }
            }
            .padding()
        }
        .navigationTitle("\(tradeType.title) \(coin.symbol.uppercased())")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if initialCoin != nil {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.theme.accent)
                } else {
                    Button {
                        withAnimation {
                            activeCoin = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(Color.theme.accent)
                    }
                }
            }
        }
    }
    
    // MARK: - Buy / Sell Tab Picker
    private var buySellTabPicker: some View {
        HStack(spacing: 8) {
            // Buy Button Tab
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    tradeType = .buy
                }
                HapticManager.notification(type: .success)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.down.left")
                        .font(.system(size: 11, weight: .bold))
                    Text("BUY")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(tradeType == .buy ? Color.theme.green : Color.clear)
                )
                .foregroundStyle(tradeType == .buy ? Color.white : Color.theme.secondaryText)
            }
            .buttonStyle(.plain)
            
            // Sell Button Tab
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    tradeType = .sell
                }
                HapticManager.notification(type: .success)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("SELL")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(tradeType == .sell ? Color.theme.red : Color.clear)
                )
                .foregroundStyle(tradeType == .sell ? Color.white : Color.theme.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.theme.secondaryText.opacity(0.08))
        )
    }
    
    // MARK: - Coin Header Card
    private func coinHeaderCard(coin: CoinModel, currentHolding: Double, currentHoldingValue: Double) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                CoinImageView(coin: coin)
                    .frame(width: 42, height: 42)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(coin.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                    
                    HStack(spacing: 6) {
                        Text(coin.symbol.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.secondaryText)
                        
                        Text("Rank #\(coin.rank)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.theme.secondaryText.opacity(0.1))
                            .clipShape(Capsule())
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(coin.currentPrice.asFormattedPrice())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                    
                    Text(coin.priceChangePercentage24H?.asPercentString() ?? "0.0%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle((coin.priceChangePercentage24H ?? 0) >= 0 ? Color.theme.green : Color.theme.red)
                }
            }
            
            Divider()
            
            // Available Balance Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "briefcase.fill")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                    Text("Crypto Holdings:")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text("\(currentHolding.asNumberString()) \(coin.symbol.uppercased()) (\(currentHoldingValue.asCurrencyWith2Decimals()))")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            Divider()
            
            // Available USD Cash Wallet Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "banknote.fill")
                        .font(.caption)
                        .foregroundStyle(Color.theme.green)
                    Text("USD Cash Wallet:")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text(vm.cashBalance.asCurrencyWith2Decimals())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.green)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Order Input Card
    private func orderInputCard(coin: CoinModel, currentHolding: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Picker("Input Mode", selection: $inputMode) {
                    ForEach(InputMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 190)
                
                Spacer()
                
                Button("Clear") {
                    quantityText = ""
                    fiatText = ""
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.red)
                .opacity((quantityText.isEmpty && fiatText.isEmpty) ? 0 : 1)
            }
            
            // Main Amount Field
            HStack {
                if inputMode == .fiat {
                    Text("$")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    TextField("0.00", text: $fiatText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                        .onChange(of: fiatText) { _, newFiat in
                            syncFromFiat(newFiat: newFiat, price: coin.currentPrice)
                        }
                } else {
                    TextField("0.00", text: $quantityText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                        .onChange(of: quantityText) { _, newQty in
                            syncFromQuantity(newQty: newQty, price: coin.currentPrice)
                        }
                    
                    Text(coin.symbol.uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.secondaryText)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.theme.secondaryText.opacity(0.08))
            )
            
            // Equivalent Subtitle
            if inputMode == .fiat {
                let qty = Double(quantityText) ?? 0
                Text("≈ \(qty.asNumberString()) \(coin.symbol.uppercased())")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.secondaryText)
            } else {
                let val = (Double(quantityText) ?? 0) * coin.currentPrice
                Text("≈ \(val.asCurrencyWith2Decimals())")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            // Smart Shortcuts: Buy Presets vs Sell Percentage Chips
            if tradeType == .buy {
                // Buy USD Presets
                HStack(spacing: 6) {
                    ForEach([50.0, 100.0, 500.0, 1000.0], id: \.self) { amount in
                        Button {
                            setFiatAmount(amount: amount, price: coin.currentPrice)
                        } label: {
                            Text("+$\(Int(amount))")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.theme.green.opacity(0.1))
                                .clipShape(Capsule())
                                .foregroundStyle(Color.theme.green)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
            } else {
                // Sell Percentage Chips (25%, 50%, 75%, MAX)
                HStack(spacing: 8) {
                    ForEach([0.25, 0.50, 0.75, 1.0], id: \.self) { fraction in
                        let title = fraction == 1.0 ? "MAX" : "\(Int(fraction * 100))%"
                        Button {
                            setSellFraction(fraction: fraction, currentHolding: currentHolding, price: coin.currentPrice)
                        } label: {
                            Text(title)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color.theme.red.opacity(fraction == 1.0 ? 0.2 : 0.1))
                                .clipShape(Capsule())
                                .foregroundStyle(Color.theme.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Order Summary Card
    private func orderSummaryCard(
        coin: CoinModel,
        tradeAmount: Double,
        totalOrderValue: Double,
        currentHolding: Double,
        resultingHolding: Double,
        isInsufficientBalance: Bool,
        isInsufficientCash: Bool
    ) -> some View {
        VStack(spacing: 10) {
            // Insufficient Balance Warning Banner
            if isInsufficientBalance {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.theme.red)
                    Text("Insufficient balance. You only hold \(currentHolding.asNumberString()) \(coin.symbol.uppercased()).")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.red)
                    Spacer()
                }
                .padding(10)
                .background(Color.theme.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Insufficient USD Cash Wallet Banner
            if isInsufficientCash {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.theme.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Insufficient USD Cash Wallet Funds")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.red)
                        Text("Available: \(vm.cashBalance.asCurrencyWith2Decimals()) | Order: \(totalOrderValue.asCurrencyWith2Decimals())")
                            .font(.caption2)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button {
                        vm.depositCash(amount: 5000)
                        HapticManager.notification(type: .success)
                    } label: {
                        Text("+$5,000")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.theme.green)
                            .foregroundStyle(Color.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(10)
                .background(Color.theme.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            HStack {
                Text("Execution Price")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                Spacer()
                Text(coin.currentPrice.asFormattedPrice())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            Divider()
            
            HStack {
                Text("Order Amount")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                Spacer()
                Text("\(tradeAmount.asNumberString()) \(coin.symbol.uppercased())")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(tradeType == .buy ? Color.theme.green : Color.theme.red)
            }
            
            Divider()
            
            HStack {
                Text(tradeType == .buy ? "Total Purchase Cost" : "Total Sale Proceeds")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.theme.accent)
                Spacer()
                Text(totalOrderValue.asCurrencyWith2Decimals())
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(tradeType == .buy ? Color.theme.green : Color.theme.red)
            }
            
            Divider()
            
            HStack {
                Text("Resulting Position")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(currentHolding.asNumberString())")
                        .foregroundStyle(Color.theme.secondaryText)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    Text("\(resultingHolding.asNumberString()) \(coin.symbol.uppercased())")
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                }
                .font(.caption)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isInsufficientBalance ? Color.theme.red.opacity(0.4) : Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Order Action Button
    private func orderActionButton(
        coin: CoinModel,
        tradeAmount: Double,
        canExecute: Bool,
        isInsufficientBalance: Bool,
        isInsufficientCash: Bool
    ) -> some View {
        let isBuy = tradeType == .buy
        let actionColor = isBuy ? Color.theme.green : Color.theme.red
        
        var buttonTitle: String {
            if orderExecuted {
                return "Order Executed!"
            } else if tradeAmount <= 0 {
                return "Enter Amount"
            } else if isInsufficientCash {
                return "Insufficient Cash Wallet Funds"
            } else if isInsufficientBalance {
                return "Insufficient \(coin.symbol.uppercased()) Balance"
            } else {
                return "\(tradeType.title) \(coin.symbol.uppercased())"
            }
        }
        
        return Button {
            executeTrade(coin: coin, amount: tradeAmount)
        } label: {
            HStack(spacing: 8) {
                if orderExecuted {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Order Executed!")
                } else {
                    if canExecute {
                        Image(systemName: isBuy ? "arrow.down.left" : "arrow.up.right")
                    }
                    Text(buttonTitle)
                }
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(canExecute ? actionColor : Color.theme.secondaryText.opacity(0.2))
            .foregroundStyle(canExecute ? Color.white : Color.theme.secondaryText)
            .clipShape(Capsule())
            .shadow(color: canExecute ? actionColor.opacity(0.25) : Color.clear, radius: 6, x: 0, y: 3)
        }
        .disabled(!canExecute || orderExecuted)
        .buttonStyle(.plain)
    }
    
    // MARK: - Coin Specific Transaction History
    private func coinTradeHistorySection(transactions: [TransactionEntity], symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(symbol) Trade History")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                Text("\(transactions.count) orders")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            VStack(spacing: 8) {
                ForEach(transactions.prefix(4), id: \.id) { tx in
                    let isBuy = (tx.transactionType ?? "").uppercased() == "BUY"
                    HStack {
                        HStack(spacing: 6) {
                            Text(isBuy ? "BUY" : "SELL")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background((isBuy ? Color.theme.green : Color.theme.red).opacity(0.15))
                                .foregroundStyle(isBuy ? Color.theme.green : Color.theme.red)
                                .clipShape(Capsule())
                            
                            Text((tx.timestamp ?? Date()).formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(Color.theme.secondaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 1) {
                            Text((isBuy ? "+" : "-") + "\(tx.amount.asNumberString()) \(symbol)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(isBuy ? Color.theme.green : Color.theme.red)
                            
                            Text(tx.totalValue.asCurrencyWith2Decimals())
                                .font(.caption2)
                                .foregroundStyle(Color.theme.secondaryText)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if tx.id != transactions.prefix(4).last?.id {
                        Divider()
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.theme.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - Logic & Sync Helpers
extension PortfolioView {
    
    private func openTradeStudio(for coin: CoinModel, type: TransactionType) {
        activeCoin = coin
        tradeType = type
        quantityText = ""
        fiatText = ""
    }
    
    private func syncFromQuantity(newQty: String, price: Double) {
        guard inputMode == .token else { return }
        if let qty = Double(newQty) {
            fiatText = String(format: "%.2f", qty * price)
        } else {
            fiatText = ""
        }
    }
    
    private func syncFromFiat(newFiat: String, price: Double) {
        guard inputMode == .fiat else { return }
        if let fiat = Double(newFiat), price > 0 {
            let qty = fiat / price
            quantityText = qty.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", qty) : String(format: "%.4f", qty)
        } else {
            quantityText = ""
        }
    }
    
    private func setFiatAmount(amount: Double, price: Double) {
        inputMode = .fiat
        fiatText = String(format: "%.0f", amount)
        let qty = amount / price
        quantityText = String(format: "%.4f", qty)
        HapticManager.notification(type: .success)
    }
    
    private func setSellFraction(fraction: Double, currentHolding: Double, price: Double) {
        inputMode = .token
        let qtyToSell = currentHolding * fraction
        quantityText = qtyToSell.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", qtyToSell) : String(format: "%.4f", qtyToSell)
        fiatText = String(format: "%.2f", qtyToSell * price)
        HapticManager.notification(type: .success)
    }
    
    private func executeTrade(coin: CoinModel, amount: Double) {
        let success = vm.executeOrder(coin: coin, type: tradeType, amount: amount, pricePerCoin: coin.currentPrice)
        guard success else {
            HapticManager.notification(type: .error)
            return
        }
        
        withAnimation(.easeIn) {
            orderExecuted = true
        }
        HapticManager.notification(type: .success)
        UIApplication.shared.endEditing()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                orderExecuted = false
                quantityText = ""
                fiatText = ""
                if initialCoin != nil {
                    dismiss()
                } else {
                    activeCoin = nil
                }
            }
        }
    }
}

#Preview {
    PortfolioView()
        .environmentObject(DeveloperPreview.instance.homeVM)
}
