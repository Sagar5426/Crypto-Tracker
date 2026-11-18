//
//  ManagePortfolioView.swift
//  CoinPilot
//
//  Created by Antigravity on 17/11/2026.
//

import SwiftUI

struct ManagePortfolioView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var marketVM: MarketViewModel
    
    // MARK: - View Model
    @StateObject private var viewModel: ManagePortfolioViewModel
    
    // MARK: - UI Animation Namespaces
    @Namespace private var portfolioTabNamespace
    @Namespace private var tradeToggleNamespace
    
    // MARK: - Initializers
    
    init(selectedCoin: CoinModel? = nil, initialTradeType: TransactionType = .buy) {
        self._viewModel = StateObject(wrappedValue: ManagePortfolioViewModel(
            initialCoin: selectedCoin,
            initialTradeType: initialTradeType
        ))
    }
    
    init(viewModel: ManagePortfolioViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.theme.screenBackground
                    .ignoresSafeArea()
                
                // Ambient glow layer that dynamically adjusts based on mode & buy/sell
                ambientGlowLayer
                
                if let coin = viewModel.activeCoin {
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
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.activeCoin?.id)
            .animation(.easeInOut(duration: 0.25), value: viewModel.tradeType)
            .onAppear {
                viewModel.setMarketViewModel(marketVM)
            }
            .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss {
                    dismiss()
                }
            }
            .alert("Remove Holding", isPresented: $viewModel.showDeleteConfirmation, presenting: viewModel.coinToDelete) { coin in
                Button("Remove", role: .destructive) {
                    withAnimation {
                        viewModel.deleteHoldingConfirmed()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: { coin in
                Text("Are you sure you want to completely remove \(coin.name) from your portfolio?")
            }
        }
    }
}

// MARK: - Ambient Glow Layer
extension ManagePortfolioView {
    
    private var ambientGlowLayer: some View {
        let activeColor = viewModel.activeCoin != nil ? viewModel.themeColor : (colorScheme == .dark ? Color.theme.accent : Color.theme.green)
        
        return ZStack {
            LinearGradient(
                stops: [
                    .init(color: activeColor.opacity(0.14), location: 0.0),
                    .init(color: activeColor.opacity(0.04), location: 0.35),
                    .init(color: Color.clear, location: 0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            RadialGradient(
                gradient: Gradient(colors: [
                    activeColor.opacity(0.12),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 20,
                endRadius: 280
            )
        }
        .ignoresSafeArea(edges: .top)
        .frame(height: 360)
        .allowsHitTesting(false)
    }
}

// MARK: - Main Asset List View (Holdings vs Explore)
extension ManagePortfolioView {
    
    private var mainAssetListView: some View {
        VStack(spacing: 14) {
            // Top Header Bar
            assetListHeaderBar
            
            // Financial Quick Summary Card (Cash + Portfolio Value)
            financialOverviewCard
            
            // Custom Mode Selector Toggle (My Holdings vs Explore All)
            portfolioModeToggle
            
            // Search Bar
            SearchBarView(searchText: $viewModel.searchText)
                .padding(.vertical, -4)
            
            // Category Filter Pills (Explore tab only)
            if viewModel.selectedTab == .addAsset {
                categoryPillsBar
            }
            
            // Content
            if viewModel.selectedTab == .myHoldings {
                holdingsTabContent
            } else {
                addAssetTabContent
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var assetListHeaderBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Manage Portfolio")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                
                Text("Execute buy & sell orders or rebalance assets")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.theme.accent)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(Color.theme.secondaryText.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var financialOverviewCard: some View {
        HStack(spacing: 12) {
            // Available Cash
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.theme.green)
                    Text("CASH WALLET")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.3)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Text(viewModel.cashBalance.asCurrencyWith2Decimals())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.green)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .frame(height: 32)
                .background(Color.theme.secondaryText.opacity(0.15))
            
            // Portfolio Holdings Value
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.theme.accent)
                    Text("PORTFOLIO VALUE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.3)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Text(viewModel.portfolioTotalValue.asCurrencyWith2Decimals())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Custom Mode Selector Toggle (My Holdings vs Explore All)
    private var portfolioModeToggle: some View {
        HStack(spacing: 6) {
            ForEach(ManagePortfolioViewModel.PortfolioTab.allCases) { tab in
                let isSelected = viewModel.selectedTab == tab
                let count = tab == .myHoldings ? viewModel.portfolioCoins.count : viewModel.allCoins.count
                let icon = tab == .myHoldings ? "briefcase.fill" : "globe"
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.selectedTab = tab
                    }
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .bold))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        
                        // Count badge
                        Text("\(count)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.theme.background.opacity(0.18) : Color.theme.secondaryText.opacity(0.12))
                            )
                            .foregroundStyle(isSelected ? Color.theme.background : Color.theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.accent)
                                .shadow(color: Color.theme.accent.opacity(0.15), radius: 6, x: 0, y: 2)
                                .matchedGeometryEffect(id: "portfolioTabBackground", in: portfolioTabNamespace)
                        }
                    }
                    .foregroundStyle(isSelected ? Color.theme.background : Color.theme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
    
    private var categoryPillsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ManagePortfolioViewModel.AssetCategory.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.filterCategory = category
                        }
                        HapticManager.selection()
                    } label: {
                        Text(category.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(viewModel.filterCategory == category ? Color.theme.accent : Color.theme.secondaryText.opacity(0.08))
                            )
                            .foregroundStyle(viewModel.filterCategory == category ? Color.theme.background : Color.theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Holdings List
    private var holdingsTabContent: some View {
        Group {
            if viewModel.portfolioCoins.isEmpty {
                emptyHoldingsState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.filteredHoldings) { coin in
                            holdingListCard(coin: coin)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    private func holdingListCard(coin: CoinModel) -> some View {
        VStack(spacing: 12) {
            // Row 1: Coin Icon, Identity, and Holding Value & Quantity
            HStack(spacing: 12) {
                // Coin Icon
                CoinImageView(coin: coin)
                    .frame(width: 38, height: 38)
                
                // Symbol & Full Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(coin.symbol.uppercased())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                    
                    Text(coin.name)
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Holdings Amount & Value
                VStack(alignment: .trailing, spacing: 2) {
                    Text(coin.currentHoldingsValue.asCurrencyWith2Decimals())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                        .lineLimit(1)
                    
                    Text("\((coin.currentHoldings ?? 0).asFormattedQuantity()) \(coin.symbol.uppercased())")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.secondaryText)
                        .lineLimit(1)
                }
            }
            
            Divider()
                .background(Color.theme.secondaryText.opacity(0.08))
            
            // Row 2: Portfolio Share Percentage & Buy/Sell Action Chips
            HStack(alignment: .center) {
                // Percentage Chip + 24h Trend
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 10))
                        Text(String(format: "%.1f%% Share", viewModel.portfolioShare(for: coin)))
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4.5)
                    .background(Color.theme.accent.opacity(0.12))
                    .foregroundStyle(Color.theme.accent)
                    .clipShape(Capsule())
                    
                    // 24h Trend
                    Text(coin.priceChangePercentage24H?.asPercentString() ?? "0.0%")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4.5)
                        .background(((coin.priceChangePercentage24H ?? 0) >= 0 ? Color.theme.green : Color.theme.red).opacity(0.12))
                        .foregroundStyle((coin.priceChangePercentage24H ?? 0) >= 0 ? Color.theme.green : Color.theme.red)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                // Trade Action Chips: Buy & Sell Buttons
                HStack(spacing: 8) {
                    Button {
                        viewModel.openTradeStudio(for: coin, type: .buy)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.left")
                                .font(.system(size: 9, weight: .bold))
                            Text("Buy")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.theme.green.opacity(0.16))
                        .foregroundStyle(Color.theme.green)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        viewModel.openTradeStudio(for: coin, type: .sell)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .bold))
                            Text("Sell")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.theme.red.opacity(0.16))
                        .foregroundStyle(Color.theme.red)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.secondaryText.opacity(0.10), lineWidth: 1)
                )
        )
        .contextMenu {
            Button {
                viewModel.openTradeStudio(for: coin, type: .buy)
            } label: {
                Label("Buy \(coin.symbol.uppercased())", systemImage: "plus.circle")
            }
            
            Button {
                viewModel.openTradeStudio(for: coin, type: .sell)
            } label: {
                Label("Sell \(coin.symbol.uppercased())", systemImage: "minus.circle")
            }
            
            Button(role: .destructive) {
                viewModel.requestDeleteHolding(coin)
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
            
            Text("Use your wallet fund to buy cryptocurrency and track portfolio gains, losses, and order execution logs.")
                .font(.subheadline)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                withAnimation {
                    viewModel.selectedTab = .addAsset
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                    Text("Explore Cryptos to Buy")
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
                ForEach(viewModel.filteredAllCoins) { coin in
                    let isHeld = viewModel.isHeld(coin: coin)
                    
                    HStack(spacing: 12) {
                        Text("\(coin.rank)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.theme.secondaryText)
                            .frame(width: 22, alignment: .leading)
                        
                        CoinImageView(coin: coin)
                            .frame(width: 34, height: 34)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(coin.symbol.uppercased())
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.theme.accent)
                            Text(coin.name)
                                .font(.caption2)
                                .foregroundStyle(Color.theme.secondaryText)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(coin.currentPrice.asFormattedPrice())
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.theme.accent)
                            
                            Text(coin.priceChangePercentage24H?.asPercentString() ?? "0.0%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle((coin.priceChangePercentage24H ?? 0) >= 0 ? Color.theme.green : Color.theme.red)
                        }
                        
                        Button {
                            viewModel.openTradeStudio(for: coin, type: .buy)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isHeld ? "arrow.left.arrow.right" : "plus")
                                    .font(.system(size: 10, weight: .bold))
                                Text(isHeld ? "Trade" : "Buy")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isHeld ? Color.theme.secondaryText.opacity(0.12) : Color.theme.green.opacity(0.15))
                            .foregroundStyle(isHeld ? Color.theme.accent : Color.theme.green)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.theme.background)
                            .shadow(color: Color.theme.accent.opacity(0.03), radius: 4, x: 0, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Trade Studio View (The Core Buy & Sell Interface)
extension ManagePortfolioView {
    
    private func tradeStudioView(coin: CoinModel) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top Custom Studio Bar
                tradeStudioHeaderBar(coin: coin)
                
                // Animated Master BUY / SELL Toggle
                buySellMasterToggle
                
                // Live Asset & Holdings Header Card
                coinLiveHeaderCard(coin: coin)
                
                // Amount Input Studio Box
                amountInputCard(coin: coin)
                
                // Order Impact & Position Shift Card
                orderImpactCard(coin: coin)
                
                // Big Glowing Action Button
                orderActionButton
                
                // Embedded Coin Trade History (Mini Ledger)
                if !viewModel.activeCoinHistory.isEmpty {
                    coinTradeHistorySection(
                        transactions: viewModel.activeCoinHistory,
                        symbol: coin.symbol.uppercased()
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Trade Studio Header Bar
    private func tradeStudioHeaderBar(coin: CoinModel) -> some View {
        HStack(alignment: .center) {
            Button {
                if viewModel.isDirectLaunch {
                    dismiss()
                } else {
                    withAnimation {
                        viewModel.closeTradeStudio()
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    if !viewModel.isDirectLaunch {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(viewModel.isDirectLaunch ? "Close" : "Portfolio")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.theme.accent)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Coin Symbol & Rank Tag
            HStack(spacing: 6) {
                Text("#\(coin.rank)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.theme.secondaryText.opacity(0.12))
                    .foregroundStyle(Color.theme.secondaryText)
                    .clipShape(Capsule())
                
                Text(coin.symbol.uppercased())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
            }
            
            Spacer()
            
            // Price Tag
            Text(coin.currentPrice.asFormattedPrice())
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.themeColor)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Master BUY / SELL Toggle
    private var buySellMasterToggle: some View {
        HStack(spacing: 8) {
            // BUY Tab
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    viewModel.tradeType = .buy
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.left")
                        .font(.system(size: 13, weight: .black))
                    Text("BUY")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if viewModel.tradeType == .buy {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.theme.green.opacity(0.8))
                            .shadow(color: Color.theme.green.opacity(0.3), radius: 8, x: 0, y: 3)
                            .matchedGeometryEffect(id: "tradeToggleBackground", in: tradeToggleNamespace)
                    }
                }
                .foregroundStyle(viewModel.tradeType == .buy ? Color.white : Color.theme.secondaryText)
            }
            .buttonStyle(.plain)
            
            // SELL Tab
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    viewModel.tradeType = .sell
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .black))
                    Text("SELL")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if viewModel.tradeType == .sell {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.theme.red)
                            .shadow(color: Color.theme.red.opacity(0.35), radius: 8, x: 0, y: 3)
                            .matchedGeometryEffect(id: "tradeToggleBackground", in: tradeToggleNamespace)
                    }
                }
                .foregroundStyle(viewModel.tradeType == .sell ? Color.white : Color.theme.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Live Coin Header Card
    private func coinLiveHeaderCard(coin: CoinModel) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                CoinImageView(coin: coin)
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(coin.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                    
                    HStack(spacing: 6) {
                        Text(coin.currentPrice.asFormattedPrice())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.theme.accent)
                        
                        Text(coin.priceChangePercentage24H?.asPercentString() ?? "0.0%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle((coin.priceChangePercentage24H ?? 0) >= 0 ? Color.theme.green : Color.theme.red)
                    }
                }
                
                Spacer()
                
                // Badge indicating current holding
                VStack(alignment: .trailing, spacing: 2) {
                    Text(viewModel.currentHolding > 0 ? "You Own" : "Not Held")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text("\(viewModel.currentHolding.asFormattedQuantity()) \(coin.symbol.uppercased())")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.currentHolding > 0 ? Color.theme.accent : Color.theme.secondaryText)
                }
            }
            
            Divider()
                .background(Color.theme.secondaryText.opacity(0.12))
            
            // Dual Balance Snapshot Row
            HStack(spacing: 12) {
                // Available Cash Wallet
                HStack(spacing: 6) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.theme.green)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Available Cash")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(Color.theme.secondaryText)
                        Text(viewModel.cashBalance.asCurrencyWith2Decimals())
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.theme.green)
                    }
                }
                
                Spacer()
                
                // Holdings Valuation
                HStack(spacing: 6) {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.theme.accent)
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Holdings Value")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(Color.theme.secondaryText)
                        Text(viewModel.currentHoldingValue.asCurrencyWith2Decimals())
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.theme.accent)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.theme.secondaryText.opacity(0.10), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Amount Input Studio Box
    private func amountInputCard(coin: CoinModel) -> some View {
        VStack(spacing: 14) {
            // Mode Selector: Dollar Amount vs Token Quantity
            HStack {
                Text("ORDER AMOUNT")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                Picker("", selection: $viewModel.inputMode) {
                    ForEach(ManagePortfolioViewModel.InputMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            
            // Primary Interactive Input Field
            HStack(alignment: .center, spacing: 8) {
                if viewModel.inputMode == .fiat {
                    Text("$")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                    
                    TextField("0.00", text: $viewModel.fiatText)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .keyboardType(.decimalPad)
                        .foregroundStyle(Color.theme.accent)
                        .onChange(of: viewModel.fiatText) { _, newValue in
                            viewModel.syncFromFiat(newFiat: newValue)
                        }
                } else {
                    TextField("0.00", text: $viewModel.quantityText)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .keyboardType(.decimalPad)
                        .foregroundStyle(Color.theme.accent)
                        .onChange(of: viewModel.quantityText) { _, newValue in
                            viewModel.syncFromQuantity(newQty: newValue)
                        }
                    
                    Text(coin.symbol.uppercased())
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.secondaryText)
                }
            }
            .padding(.vertical, 6)
            
            // Converted Equivalent Subtext
            HStack {
                if viewModel.inputMode == .fiat {
                    Text("≈ \(viewModel.tradeAmount.asFormattedQuantity()) \(coin.symbol.uppercased())")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.secondaryText)
                } else {
                    Text("≈ \(viewModel.totalOrderValue.asCurrencyWith2Decimals())")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                if !viewModel.fiatText.isEmpty || !viewModel.quantityText.isEmpty {
                    Button("Clear") {
                        viewModel.clearInput()
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
                }
            }
            
            Divider()
                .background(Color.theme.secondaryText.opacity(0.10))
            
            // Quick Percentage & Quick Value Buttons
            if viewModel.tradeType == .buy {
                // Buy Quick Cash Chips: +$100, +$500, +$1,000, MAX Cash
                HStack(spacing: 8) {
                    ForEach([100.0, 500.0, 1000.0], id: \.self) { delta in
                        Button {
                            viewModel.addFiatAmount(delta: delta)
                        } label: {
                            Text("+$\(Int(delta))")
                                .font(.system(size: 12, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.theme.secondaryText.opacity(0.1))
                                .clipShape(Capsule())
                                .foregroundStyle(Color.theme.accent)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        viewModel.setFiatAmount(amount: viewModel.cashBalance)
                    } label: {
                        Text("MAX")
                            .font(.system(size: 12, weight: .black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.theme.green)
                            .clipShape(Capsule())
                            .foregroundStyle(Color.black)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.cashBalance <= 0)
                }
            } else {
                // Sell Fraction Chips: 25%, 50%, 75%, MAX
                HStack(spacing: 8) {
                    ForEach([0.25, 0.50, 0.75, 1.0], id: \.self) { fraction in
                        let isMax = fraction == 1.0
                        let title = isMax ? "MAX" : "\(Int(fraction * 100))%"
                        
                        Button {
                            viewModel.setSellFraction(fraction: fraction)
                        } label: {
                            Text(title)
                                .font(.system(size: 12, weight: isMax ? .black : .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(isMax ? Color.theme.red : Color.theme.red.opacity(0.12))
                                .clipShape(Capsule())
                                .foregroundStyle(isMax ? Color.white : Color.theme.red)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.currentHolding <= 0)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.theme.secondaryText.opacity(0.10), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Order Impact Breakdown Card
    private func orderImpactCard(coin: CoinModel) -> some View {
        VStack(spacing: 12) {
            // Insufficient Warnings
            if viewModel.isInsufficientBalance {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.theme.red)
                    Text("Insufficient coins. You hold \(viewModel.currentHolding.asFormattedQuantity()) \(coin.symbol.uppercased()).")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.red)
                    Spacer()
                }
                .padding(10)
                .background(Color.theme.red.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            if viewModel.isInsufficientCash {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.theme.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Insufficient Cash Wallet Balance")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.red)
                        Text("Cash short by \((viewModel.totalOrderValue - viewModel.cashBalance).asCurrencyWith2Decimals())")
                            .font(.caption2)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding(10)
                .background(Color.theme.red.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Order Metrics Breakdown
            VStack(spacing: 10) {
                // Execution Price Row
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
                    .background(Color.theme.secondaryText.opacity(0.10))
                
                // Total Order Cost / Proceeds Row
                HStack {
                    Text(viewModel.tradeType == .buy ? "Total Purchase Cost" : "Total Sale Proceeds")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                    Spacer()
                    Text(viewModel.totalOrderValue.asCurrencyWith2Decimals())
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(viewModel.themeColor)
                }
                
                Divider()
                    .background(Color.theme.secondaryText.opacity(0.10))
                
                // Position Shift Row
                HStack {
                    Text("Resulting Position")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                    Spacer()
                    HStack(spacing: 5) {
                        Text("\(viewModel.currentHolding.asFormattedQuantity())")
                            .foregroundStyle(Color.theme.secondaryText)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(Color.theme.secondaryText)
                        Text("\(viewModel.resultingHolding.asFormattedQuantity()) \(coin.symbol.uppercased())")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                    }
                    .font(.caption)
                }
                
                // Projected Average Buy Price (DCA calculation when buying)
                if let projectedAvgPrice = viewModel.projectedAverageBuyPrice {
                    Divider()
                        .background(Color.theme.secondaryText.opacity(0.10))
                    
                    HStack {
                        Text("Projected Avg Buy Price")
                            .font(.caption)
                            .foregroundStyle(Color.theme.secondaryText)
                        Spacer()
                        Text(projectedAvgPrice.asFormattedPrice())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.secondaryText.opacity(0.10), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Big Glowing Order Action Button
    private var orderActionButton: some View {
        let isBuy = viewModel.tradeType == .buy
        let actionColor = isBuy ? Color.theme.green.opacity(0.8) : Color.theme.red
        
        return Button {
            viewModel.executeTrade()
        } label: {
            HStack(spacing: 8) {
                if viewModel.orderExecuted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                } else if viewModel.canExecuteOrder {
                    Image(systemName: isBuy ? "arrow.down.left" : "arrow.up.right")
                        .font(.system(size: 14, weight: .black))
                }
                
                Text(viewModel.orderActionButtonTitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                viewModel.canExecuteOrder ? actionColor : Color.theme.secondaryText.opacity(0.18)
            )
            .foregroundStyle(viewModel.canExecuteOrder ? Color.white : Color.theme.secondaryText)
            .clipShape(Capsule())
            .shadow(color: viewModel.canExecuteOrder ? actionColor.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!viewModel.canExecuteOrder || viewModel.orderExecuted)
        .buttonStyle(.plain)
    }
    
    // MARK: - Mini Ledger (Coin Specific Trade History)
    private func coinTradeHistorySection(transactions: [TransactionEntity], symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(symbol) ORDER HISTORY")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                Text("\(transactions.count) orders logged")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 0) {
                ForEach(transactions.prefix(4), id: \.id) { tx in
                    let isBuy = (tx.transactionType ?? "").uppercased() == "BUY"
                    
                    HStack {
                        HStack(spacing: 8) {
                            Text(isBuy ? "BUY" : "SELL")
                                .font(.system(size: 10, weight: .black))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background((isBuy ? Color.theme.green : Color.theme.red).opacity(0.15))
                                .foregroundStyle(isBuy ? Color.theme.green : Color.theme.red)
                                .clipShape(Capsule())
                            
                            Text((tx.timestamp ?? Date()).formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(Color.theme.secondaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text((isBuy ? "+" : "-") + "\(tx.amount.asFormattedQuantity()) \(symbol)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(isBuy ? Color.theme.green : Color.theme.red)
                            
                            Text(tx.totalValue.asCurrencyWith2Decimals())
                                .font(.caption2)
                                .foregroundStyle(Color.theme.secondaryText)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    
                    if tx.id != transactions.prefix(4).last?.id {
                        Divider()
                            .background(Color.theme.secondaryText.opacity(0.08))
                            .padding(.leading, 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
                )
            )
        }
        .padding(.top, 4)
    }
}

typealias ManagePortfolioSheet = ManagePortfolioView

#Preview {
    ManagePortfolioView()
        .environmentObject(DeveloperPreview.instance.homeVM)
}
