//
//  TradeBookView.swift
//  CrytoTracker
//
//  Created by Antigravity on 16/11/2026.
//

import SwiftUI
import SwiftfulUI

/// Read-only TradeBook view that acts as an immutable, foolproof ledger for all
/// crypto buy and sell trade orders executed in the application.
@MainActor
struct TradeBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var vm: MarketViewModel
    
    // MARK: - View Model
    @StateObject private var viewModel: TradeBookViewModel
    
    // MARK: - Layout & Geometry State
    @State private var scrollViewOffset: CGFloat = 0
    @State private var topSectionHeight: CGFloat = 280
    
    // MARK: - Typealiases for backward compatibility
    typealias TradeFilterType = TradeBookViewModel.TradeFilterType
    typealias TradeSortOption = TradeBookViewModel.TradeSortOption
    
    // MARK: - Initializer
    
    init(viewModel: TradeBookViewModel? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel ?? TradeBookViewModel())
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.theme.screenBackground
                .ignoresSafeArea()
            
            // Ambient trade glow background
            ambientGlowBackground
            
            VStack(spacing: 0) {
                // Header kept intact at the top
                topBar
                    .background(
                        Color.theme.screenBackground
                            .ignoresSafeArea(edges: .top)
                            .opacity(headerBackgroundOpacity)
                    )
                
                if viewModel.cryptoTrades.isEmpty {
                    emptyTradeBookView
                } else {
                    scrollViewLayer
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.setMarketViewModel(vm)
        }
        .sheet(item: $viewModel.selectedTradeForDetail) { trade in
            NavigationStack {
                TradeReceiptDetailSheet(
                    trade: trade,
                    viewModel: viewModel,
                    onViewCoin: { coin in
                        viewModel.viewCoinDetail(coin: coin)
                    }
                )
            }
        }
        .fullScreenCover(item: $viewModel.selectedCoinForDetail) { coin in
            NavigationStack {
                CoinDetailView(coin: coin)
            }
        }
    }
}

// MARK: - Layout & Staged Fade Progress
extension TradeBookView {
    
    /// Progress from 0.0 (fully expanded at top) to 1.0 (fully collapsed and pinned)
    private var collapseProgress: Double {
        guard scrollViewOffset < 0 else { return 0.0 }
        let collapseDistance = max(1.0, topSectionHeight - 10)
        return min(1.0, Double(-scrollViewOffset / collapseDistance))
    }
    
    /// Header background opacity turns solid as user scrolls past 30pt
    private var headerBackgroundOpacity: Double {
        min(1.0, max(0.0, -scrollViewOffset / 30.0))
    }
    
    /// Metric Card fades out smoothly (0% -> 65% of collapse)
    private var metricCardFadeOpacity: Double {
        let progress = min(1.0, max(0.0, collapseProgress / 0.65))
        return 1.0 - progress
    }
    
    /// Search Bar fades out smoothly (25% -> 90% of collapse) before filter bar pins
    private var searchBarFadeOpacity: Double {
        let progress = min(1.0, max(0.0, (collapseProgress - 0.25) / 0.65))
        return 1.0 - progress
    }
    
    /// Overall opacity for ambient background gradient
    private var contentFadeOpacity: Double {
        max(0.0, 1.0 - collapseProgress)
    }
    
    /// Solid background opacity for the sticky filter bar row itself (reaches 1.0 before pinning)
    private var filterBarBackgroundOpacity: Double {
        min(1.0, max(0.0, collapseProgress / 0.85))
    }
}

// MARK: - Ambient, Collapsible Middle Section & Top Bar
extension TradeBookView {
    
    private var ambientGlowBackground: some View {
        LinearGradient(
            stops: [
                .init(color: Color.orange.opacity(colorScheme == .dark ? 0.08 : 0.05), location: 0.0),
                .init(color: colorScheme == .dark ? Color.theme.accent.opacity(0.03) : Color.orange.opacity(0.02), location: 0.22),
                .init(color: Color.clear, location: 0.55)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .top)
        .frame(height: 420 + max(0, scrollViewOffset))
        .offset(y: min(0, scrollViewOffset))
        .opacity(contentFadeOpacity)
        .allowsHitTesting(false)
    }
    
    /// Collapsible Middle Section (Metrics Overview Card + Search Bar)
    private var collapsibleMiddleSection: some View {
        VStack(spacing: 12) {
            // 1. Hero Summary Metrics Card
            metricsOverviewCard
                .opacity(metricCardFadeOpacity)
                .scaleEffect(1.0 - (collapseProgress * 0.03), anchor: .top)
            
            // 2. Search Bar
            SearchBarView(searchText: $viewModel.searchText)
                .padding(.top, -2)
                .opacity(searchBarFadeOpacity)
                .scaleEffect(1.0 - (collapseProgress * 0.02), anchor: .top)
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        if geo.size.height > 0 {
                            topSectionHeight = geo.size.height + 12
                        }
                    }
                    .onChange(of: geo.size.height) { _, newHeight in
                        if newHeight > 0 {
                            topSectionHeight = newHeight + 12
                        }
                    }
            }
        )
        .allowsHitTesting(collapseProgress < 0.85)
    }
    
    /// Header bar kept intact at the top of TradeBook
    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            // Dismiss Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.theme.accent)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.theme.secondaryText.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            
            // Title & Count Badge
            HStack(spacing: 8) {
                Text("TradeBook")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                
                Text("\(viewModel.cryptoTrades.count)")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(Color.orange)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            // Refresh Button
            Button {
                viewModel.refreshData()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.theme.accent)
                    .rotationEffect(.degrees(viewModel.isLoading || viewModel.isSpinning ? 360 : 0))
                    .animation(
                        viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                        value: viewModel.isLoading
                    )
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.theme.secondaryText.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}

// MARK: - Main Scroll Content
extension TradeBookView {
    
    private var scrollViewLayer: some View {
        ScrollViewWithOnScrollChanged(
            .vertical,
            showsIndicators: false,
            content: {
                LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                    // Collapsible Middle Section (Metrics Card + Search Bar)
                    collapsibleMiddleSection
                        .zIndex(1)
                    
                    // Sticky Section: Filter & Sort Bar sticks intact when scrolled
                    Section {
                        if viewModel.filteredTrades.isEmpty {
                            filteredEmptyStateView
                                .zIndex(0)
                        } else {
                            tradesListSection
                                .zIndex(0)
                        }
                    } header: {
                        stickyFilterBar
                            .zIndex(10)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 50)
            },
            onScrollChanged: { offset in
                scrollViewOffset = offset.y
            }
        )
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            viewModel.refreshData()
        }
    }
    
    // MARK: - Sticky Filter & Sort Bar
    private var stickyFilterBar: some View {
        VStack(spacing: 0) {
            filterAndSortBar
                .padding(.top, 4)
                .padding(.bottom, 8)
            
            // Divider line below filter bar when sticky
            Rectangle()
                .fill(Color.theme.secondaryText.opacity(0.18))
                .frame(height: 1)
                .opacity(filterBarBackgroundOpacity)
        }
        .background(
            Color.theme.screenBackground
                .opacity(filterBarBackgroundOpacity)
        )
    }
    
    // MARK: - Metrics Overview Card
    private var metricsOverviewCard: some View {
        VStack(spacing: 12) {
            // Top Row: Total Volume & Trade Count
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.orange)
                        
                        Text("TOTAL TRADING VOLUME")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.4)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    Text(viewModel.totalVolume.asCurrencyWith2Decimals())
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer(minLength: 8)
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text("TOTAL TRADES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text("\(viewModel.cryptoTrades.count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                        .lineLimit(1)
                }
            }
            
            // Buy vs Sell Split Bar
            volumeRatioBar
            
            // Metric Cards: Buys vs Sells
            HStack(spacing: 10) {
                metricSubCard(
                    title: "Buys",
                    countText: "\(viewModel.buyTrades.count) Orders",
                    amountText: viewModel.totalBuyVolume.asCurrencyWith2Decimals(),
                    color: Color.theme.green,
                    systemImage: "arrow.down.left.circle.fill"
                )
                
                metricSubCard(
                    title: "Sells",
                    countText: "\(viewModel.sellTrades.count) Orders",
                    amountText: viewModel.totalSellVolume.asCurrencyWith2Decimals(),
                    color: Color.theme.red,
                    systemImage: "arrow.up.right.circle.fill"
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    private func metricSubCard(
        title: String,
        countText: String,
        amountText: String,
        color: Color,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 11))
                
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                
                Spacer(minLength: 4)
                
                Text(countText)
                    .font(.system(size: 9.5, weight: .semibold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }
            .foregroundStyle(color)
            
            Text(amountText)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
    
    private var volumeRatioBar: some View {
        let buyRatio = viewModel.buyRatio
        let sellRatio = viewModel.sellRatio
        
        return VStack(spacing: 4) {
            GeometryReader { geo in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.theme.green)
                        .frame(width: max(4, geo.size.width * CGFloat(buyRatio) - 1.5))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.theme.red)
                        .frame(width: max(4, geo.size.width * CGFloat(sellRatio) - 1.5))
                }
            }
            .frame(height: 5)
            .clipShape(Capsule())
            
            HStack {
                Text("Buy: \(String(format: "%.1f%%", buyRatio * 100))")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(Color.theme.green)
                    .lineLimit(1)
                
                Spacer()
                
                Text("Sell: \(String(format: "%.1f%%", sellRatio * 100))")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(Color.theme.red)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Single Clean Filter & Sort Bar
    private var filterAndSortBar: some View {
        HStack(spacing: 8) {
            // Filter Capsules: All, Buys, Sells
            HStack(spacing: 6) {
                ForEach(TradeFilterType.allCases) { filter in
                    let isSelected = viewModel.selectedFilter == filter
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedFilter = filter
                        }
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 4) {
                            Text(filter.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                            
                            Text("(\(viewModel.countFor(filter: filter)))")
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                                .opacity(0.8)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.orange : Color.theme.secondaryText.opacity(0.08))
                        )
                        .foregroundStyle(isSelected ? Color.white : Color.theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer(minLength: 4)
            
            // Sort Menu Button
            Menu {
                Picker("Sort Order", selection: $viewModel.sortOption) {
                    ForEach(TradeSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 10, weight: .bold))
                    Text(viewModel.sortOption.shortTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(Color.theme.accent)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.theme.secondaryText.opacity(0.08))
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Trades List Section
    private var tradesListSection: some View {
        LazyVStack(spacing: 10) {
            ForEach(viewModel.filteredTrades, id: \.id) { trade in
                TradeRowCard(
                    trade: trade,
                    liveCoin: viewModel.liveCoin(for: trade),
                    onTap: {
                        viewModel.selectTradeForDetail(trade)
                    }
                )
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Empty States
    private var emptyTradeBookView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)
            
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.orange)
            }
            
            VStack(spacing: 6) {
                Text("TradeBook is Empty")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
                
                Text("Every coin buy and sell order executed in the app is automatically and permanently logged here.")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(Color.orange)
                Text("Read-Only Audit Ledger")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.theme.secondaryText.opacity(0.08))
            .clipShape(Capsule())
            
            Spacer()
        }
        .padding()
    }
    
    private var filteredEmptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30))
                .foregroundStyle(Color.theme.secondaryText.opacity(0.6))
                .padding(.top, 28)
            
            Text("No Matching Trades")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Text("No transactions matched '\(viewModel.searchText)' with the current filters.")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.resetFilters()
            } label: {
                Text("Reset Filters")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

// MARK: - Trade Row Card View (Zero Wrapping, Zero Clipping Layout)
struct TradeRowCard: View {
    let trade: TransactionEntity
    let liveCoin: CoinModel?
    let onTap: () -> Void
    
    private var isBuy: Bool {
        (trade.transactionType ?? "").uppercased() == "BUY"
    }
    
    private var badgeColor: Color {
        isBuy ? Color.theme.green : Color.theme.red
    }
    
    private var executionDate: Date {
        trade.timestamp ?? Date()
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // 1. Top Header Row: Coin Icon + Name + Symbol & Date on Left, BUY/SELL Badge on Right
                HStack(alignment: .center, spacing: 10) {
                    coinIconView
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(trade.coinName ?? "Unknown")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.theme.accent)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Text((trade.coinSymbol ?? "").uppercased())
                                .font(.system(size: 9.5, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.theme.secondaryText.opacity(0.1))
                                .foregroundStyle(Color.theme.secondaryText)
                                .clipShape(Capsule())
                                .lineLimit(1)
                        }
                        
                        Text(executionDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.theme.secondaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Order Type Badge (BUY ORDER / SELL ORDER)
                    Text(isBuy ? "BUY ORDER" : "SELL ORDER")
                        .font(.system(size: 9.5, weight: .heavy))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(badgeColor.opacity(0.14))
                        .foregroundStyle(badgeColor)
                        .clipShape(Capsule())
                        .lineLimit(1)
                }
                
                // 2. Structured Data Section
                VStack(spacing: 8) {
                    HStack(alignment: .top) {
                        // Qty Sold / Bought
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isBuy ? "Qty Bought" : "Qty Sold")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(Color.theme.secondaryText)
                            
                            Text(formatUnits(trade.amount) + " " + (trade.coinSymbol ?? "").uppercased())
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(badgeColor)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Selling / Buying Price
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(isBuy ? "Buying Price" : "Selling Price")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(Color.theme.secondaryText)
                            
                            Text(trade.pricePerCoin.asFormattedPrice())
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.theme.accent)
                                .monospacedDigit()
                                .lineLimit(1)
                        }
                    }
                    
                    Divider()
                        .background(Color.theme.secondaryText.opacity(0.08))
                    
                    // Selling / Buying Total Value
                    HStack(alignment: .center) {
                        Text(isBuy ? "Buying Total Value" : "Selling Total Value")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(Color.theme.secondaryText)
                        
                        Spacer()
                        
                        Text(trade.totalValue.asCurrencyWith2Decimals())
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.theme.accent)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                }
                .padding(10)
                .background(Color.theme.secondaryText.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .padding(13)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color.theme.background)
                    .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var coinIconView: some View {
        ZStack {
            Circle()
                .fill(Color.theme.secondaryText.opacity(0.08))
                .frame(width: 36, height: 36)
            
            if let coin = liveCoin {
                CoinImageView(coin: coin)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Text((trade.coinSymbol ?? "?").prefix(3).uppercased())
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Color.theme.accent)
            }
        }
    }
    
    private func formatUnits(_ amount: Double) -> String {
        let absVal = abs(amount)
        if absVal >= 1.0 {
            return amount.asNumberString()
        } else {
            return String(format: "%.4f", amount).replacingOccurrences(
                of: #"(\.\d*?[1-9])0+$|\.0+$"#,
                with: "$1",
                options: .regularExpression
            )
        }
    }
}

// MARK: - Read-Only Trade Receipt Detail Sheet
struct TradeReceiptDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: MarketViewModel
    
    let trade: TransactionEntity
    var viewModel: TradeBookViewModel? = nil
    let onViewCoin: (CoinModel) -> Void
    
    @State private var hasCopiedID: Bool = false
    
    private var isBuy: Bool {
        (trade.transactionType ?? "").uppercased() == "BUY"
    }
    
    private var badgeColor: Color {
        isBuy ? Color.theme.green : Color.theme.red
    }
    
    private var liveCoin: CoinModel? {
        if let viewModel = viewModel {
            return viewModel.liveCoin(for: trade)
        }
        return vm.allCoins.first { $0.id.lowercased() == (trade.coinID ?? "").lowercased() }
    }
    
    var body: some View {
        ZStack {
            Color.theme.screenBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Receipt Card
                    receiptCard
                    
                    // Transaction Identifier Card
                    transactionMetadataCard
                    
                    // Foolproof Security Notice Card
                    immutableLedgerNoticeCard
                    
                    // Market Navigation Button
                    if let live = liveCoin {
                        Button {
                            onViewCoin(live)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                Text("View \(live.name) in Markets")
                            }
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.theme.accent)
                            .foregroundStyle(Color.theme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Trade Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            }
        }
    }
    
    private var receiptCard: some View {
        VStack(spacing: 14) {
            // Coin Hero Header
            HStack(spacing: 12) {
                if let live = liveCoin {
                    CoinImageView(coin: live)
                        .frame(width: 44, height: 44)
                } else {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text((trade.coinSymbol ?? "?").prefix(3).uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.orange)
                        )
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(trade.coinName ?? "Unknown Coin")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                        .lineLimit(1)
                    
                    HStack(spacing: 5) {
                        Text((trade.coinSymbol ?? "").uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.secondaryText)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(Color.theme.secondaryText.opacity(0.5))
                        
                        Text("FILLED & LOGGED")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(Color.theme.green)
                    }
                }
                
                Spacer(minLength: 8)
                
                // BUY / SELL Badge
                Text(isBuy ? "BUY ORDER" : "SELL ORDER")
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(badgeColor.opacity(0.14))
                    .foregroundStyle(badgeColor)
                    .clipShape(Capsule())
                    .lineLimit(1)
            }
            
            Divider()
            
            // Detail Rows
            VStack(spacing: 11) {
                receiptRow(title: "Execution Date", value: (trade.timestamp ?? Date()).formatted(date: .long, time: .shortened))
                receiptRow(title: isBuy ? "Quantity Bought" : "Quantity Sold", value: "\(trade.amount.asNumberString()) \((trade.coinSymbol ?? "").uppercased())")
                receiptRow(title: isBuy ? "Buying Price" : "Selling Price", value: trade.pricePerCoin.asFormattedPrice())
                receiptRow(title: isBuy ? "Buying Total Value" : "Selling Total Value", value: trade.totalValue.asCurrencyWith2Decimals(), isBold: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
    }
    
    private var transactionMetadataCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TRANSACTION ID")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(Color.theme.secondaryText)
                .lineLimit(1)
            
            HStack {
                Text(trade.id ?? "Unknown ID")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer(minLength: 6)
                
                Button {
                    if let id = trade.id {
                        UIPasteboard.general.string = id
                        HapticManager.notification(type: .success)
                        withAnimation {
                            hasCopiedID = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                hasCopiedID = false
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: hasCopiedID ? "checkmark" : "doc.on.doc")
                        Text(hasCopiedID ? "Copied" : "Copy")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(hasCopiedID ? Color.theme.green : Color.theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.theme.secondaryText.opacity(0.08))
                    .clipShape(Capsule())
                    .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.theme.secondaryText.opacity(0.05))
        )
    }
    
    private var immutableLedgerNoticeCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.theme.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Immutable Audit Record")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
                    .lineLimit(1)
                
                Text("This order is stored permanently in your local portfolio ledger to ensure foolproof historical integrity.")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.theme.green.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.theme.green.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func receiptRow(title: String, value: String, isBold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                .lineLimit(1)
            
            Spacer(minLength: 8)
            
            Text(value)
                .font(.caption)
                .fontWeight(isBold ? .bold : .semibold)
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
        }
    }
}

// MARK: - Previews
#Preview("TradeBook - Populated") {
    NavigationStack {
        TradeBookView()
            .environmentObject(DeveloperPreview.instance.homeVM)
    }
    .preferredColorScheme(.dark)
}

#Preview("TradeBook - Empty") {
    NavigationStack {
        TradeBookView()
            .environmentObject(MarketViewModel(isForPreview: true))
    }
    .preferredColorScheme(.dark)
}
