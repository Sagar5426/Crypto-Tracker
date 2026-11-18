//
//  MarketView.swift
//  CoinPilot
//
//  Created by Sagar Jangra on 30/07/2025.
//

import SwiftUI
import SwiftfulUI

@MainActor
struct MarketView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var vm: MarketViewModel
    
    // MARK: - View Model
    @StateObject private var viewModel: MarketScreenViewModel
    
    // MARK: - Layout State
    @State private var scrollViewOffset: CGFloat = 0
    @State private var topSafeAreaInset: CGFloat = 59
    @State private var topSectionHeight: CGFloat = 160
    
    // MARK: - Initializer
    
    init(viewModel: MarketScreenViewModel? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel ?? MarketScreenViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Base adaptive background
                Color.theme.screenBackground
                    .ignoresSafeArea()
                
                // Dynamic ambient crypto gradient glow that scrolls synchronously & fades out together
                backGroundGradientLayer
                
                // Scrollable content with collapsible top header & stats, plus sticky filter chips
                scrollViewLayer
            }
            .background(
                // Capture exact top safe area inset for the device
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            if geo.safeAreaInsets.top > 0 {
                                topSafeAreaInset = geo.safeAreaInsets.top
                            }
                        }
                        .onChange(of: geo.safeAreaInsets.top) { _, newValue in
                            if newValue > 0 {
                                topSafeAreaInset = newValue
                            }
                        }
                }
            )
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.setMarketViewModel(vm)
            }
            .fullScreenCover(item: $viewModel.selectedCoinForDetail) { coin in
                NavigationStack {
                    CoinDetailView(coin: coin)
                }
            }
        }
    }
}

// MARK: - Layout & Layers
extension MarketView {
    
    // MARK: - Unified Collapse & Staged Fade Progress
    /// Progress from 0.0 (fully expanded at top) to 1.0 (fully collapsed and pinned)
    private var collapseProgress: Double {
        guard scrollViewOffset < 0 else { return 0.0 }
        let collapseDistance = max(1.0, topSectionHeight - 10)
        return min(1.0, Double(-scrollViewOffset / collapseDistance))
    }
    
    /// Top Header fades out earlier (0% -> 55%) so it never clashes with the status bar
    private var headerFadeOpacity: Double {
        let progress = min(1.0, max(0.0, collapseProgress / 0.55))
        return 1.0 - (progress * progress)
    }
    
    /// MarketStatsView fades out smoothly (15% -> 92%) as filter chips approach the top
    private var statsFadeOpacity: Double {
        let progress = min(1.0, max(0.0, (collapseProgress - 0.15) / 0.77))
        return 1.0 - progress
    }
    
    /// Overall opacity for ambient background gradient
    private var contentFadeOpacity: Double {
        max(0.0, 1.0 - collapseProgress)
    }
    
    /// Solid background opacity for the filter chips row itself (reaches 1.0 before pinning)
    private var chipRowBackgroundOpacity: Double {
        min(1.0, max(0.0, collapseProgress / 0.80))
    }
    
    /// Safe-area extension opacity (activates only as MarketStatsView finishes fading so it never overlaps it)
    private var safeAreaCoverOpacity: Double {
        min(1.0, max(0.0, (collapseProgress - 0.75) / 0.20))
    }
    
    // MARK: - Ambient Gradient Layer (Moves synchronously with scroll & fades out together)
    private var backGroundGradientLayer: some View {
        ZStack {
            // Multi-stop linear gradient for rich ambient background fade
            LinearGradient(
                stops: [
                    .init(color: (colorScheme == .dark ? Color.theme.accent.opacity(0.18) : Color.theme.green.opacity(0.08)), location: 0.0),
                    .init(color: (colorScheme == .dark ? Color.theme.accent.opacity(0.08) : Color.theme.green.opacity(0.03)), location: 0.35),
                    .init(color: Color.theme.green.opacity(0.05), location: 0.65),
                    .init(color: Color.clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Soft ambient green aura on top-trailing
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.theme.green.opacity(0.14),
                    Color.theme.green.opacity(0.04),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 20,
                endRadius: 280
            )
            
            // Soft ambient accent aura on top-leading
            RadialGradient(
                gradient: Gradient(colors: [
                    (colorScheme == .dark ? Color.theme.accent.opacity(0.12) : Color.blue.opacity(0.06)),
                    (colorScheme == .dark ? Color.theme.accent.opacity(0.03) : Color.blue.opacity(0.02)),
                    Color.clear
                ]),
                center: .topLeading,
                startRadius: 20,
                endRadius: 260
            )
        }
        .ignoresSafeArea(edges: .top)
        .frame(height: 380 + max(0, scrollViewOffset))
        .offset(y: min(0, scrollViewOffset))
        .opacity(contentFadeOpacity)
        .allowsHitTesting(false)
    }
    
    // MARK: - Collapsible Top Section (Header + Global Stats)
    private var topCollapsibleSection: some View {
        VStack(spacing: 14) {
            // 1. Collapsible Top Header
            HeaderView(
                title: "Markets",
                showSearchBar: $viewModel.showSearchBar,
                searchText: $viewModel.searchText,
                isLoading: viewModel.isLoading,
                showLiveBadge: true,
                onRefresh: {
                    viewModel.reloadData()
                }
            )
            .opacity(headerFadeOpacity)
            .scaleEffect(1.0 - (collapseProgress * 0.03), anchor: .top)
            .offset(y: min(0, -scrollViewOffset * 0.15))
            
            // 2. Collapsible Global Market Overview Card
            MarketStatsView(showPortfolio: .constant(false))
                .opacity(statsFadeOpacity)
                .scaleEffect(1.0 - (collapseProgress * 0.04), anchor: .top)
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
    }
    
    // MARK: - Main Scroll Content with Sticky Filter Chips & Coins
    private var scrollViewLayer: some View {
        ScrollViewWithOnScrollChanged(
            .vertical,
            showsIndicators: false,
            content: {
                LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                    // Collapsible Top Section (Hero Header + MarketStatsView)
                    topCollapsibleSection
                        .zIndex(1)
                    
                    // Search Bar Dropdown (when toggled from header)
                    if viewModel.showSearchBar {
                        SearchBarView(searchText: $viewModel.searchText)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(1)
                    }
                    
                    // Sticky Filter Chips & Content
                    Section {
                        // Top Movers & Losers (Only shown in "All" category when not searching)
                        if viewModel.marketCategory == .all && viewModel.searchText.isEmpty {
                            VStack(spacing: 10) {
                                if !viewModel.topMovers.isEmpty {
                                    topMoversSection
                                        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                                }
                                
                                if !viewModel.topLosers.isEmpty {
                                    topLosersSection
                                        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                                }
                            }
                            .padding(.top, 4)
                            .padding(.bottom, 2)
                        } else if viewModel.searchText.isEmpty {
                            // Category Banner for Gainers / Losers / Top 10
                            if let desc = viewModel.marketCategory.description {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(Color.theme.secondaryText)
                                    Text(desc)
                                        .font(.caption2)
                                        .foregroundStyle(Color.theme.secondaryText)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 2)
                                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                            }
                        }
                        
                        // Sticky / Flowing Column Titles
                        columnTitles
                            .zIndex(0)
                        
                        // Coins List
                        if viewModel.displayedCoins.isEmpty && !viewModel.searchText.isEmpty {
                            noResultsView
                                .zIndex(0)
                        } else {
                            coinsLazyList
                                .zIndex(0)
                        }
                    } header: {
                        filterChipsRow
                            .zIndex(10)
                    }
                }
                .padding(.bottom, 24)
            },
            onScrollChanged: { offset in
                scrollViewOffset = offset.y
            }
        )
        .refreshable {
            viewModel.reloadData()
        }
    }
    
    // MARK: - Sticky Filter Chips Row with Non-Transparent Background
    private var filterChipsRow: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MarketViewModel.MarketCategory.allCases) { category in
                        let isSelected = viewModel.marketCategory == category
                        Button {
                            viewModel.selectCategory(category)
                        } label: {
                            HStack(spacing: 6) {
                                if category == .gainers {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 10, weight: .bold))
                                } else if category == .losers {
                                    Image(systemName: "arrow.down.right")
                                        .font(.system(size: 10, weight: .bold))
                                } else if category == .topTen {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                
                                Text(category.rawValue)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                ZStack {
                                    // Opaque adaptive base so individual chips are never see-through
                                    Capsule()
                                        .fill(Color.theme.screenBackground)
                                    
                                    Capsule()
                                        .fill(isSelected ? Color.theme.accent : Color.theme.secondaryText.opacity(0.12))
                                }
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : Color.theme.secondaryText.opacity(0.14), lineWidth: 1)
                            )
                            .foregroundStyle(isSelected ? Color.theme.background : Color.theme.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            // Divider line below filter chips
            Rectangle()
                .fill(Color.theme.secondaryText.opacity(0.22))
                .frame(height: 1)
                .opacity(chipRowBackgroundOpacity)
        }
        .background(
            ZStack(alignment: .top) {
                // 1. Adaptive solid background strictly inside filterChipsRow bounds (never overlaps MarketStatsView)
                Color.theme.screenBackground
                    .opacity(chipRowBackgroundOpacity)
                
                // 2. Top safe area shield that locks in as the header finishes collapsing
                Color.theme.screenBackground
                    .frame(height: topSafeAreaInset + 2)
                    .offset(y: -topSafeAreaInset)
                    .ignoresSafeArea(edges: .top)
                    .opacity(safeAreaCoverOpacity)
            }
        )
        .compositingGroup()
    }
}

// MARK: - Subviews & Sections
extension MarketView {
    
    private var topMoversSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.orange)
                    .font(.caption)
                Text("Top Gainers 24h")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(viewModel.topMovers) { coin in
                        Button {
                            viewModel.selectCoinForDetail(coin)
                        } label: {
                            topMoverCard(coin: coin)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 2)
            }
        }
    }
    
    private func topMoverCard(coin: CoinModel) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                CoinImageView(coin: coin)
                    .frame(width: 22, height: 22)
                Spacer()
                Text("#\(coin.rank)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            Text(coin.symbol.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
            
            Text(coin.currentPrice.asFormattedPrice())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            HStack(spacing: 2) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 7, weight: .bold))
                Text(coin.priceChangePercentage24H?.asPercentString() ?? "+0.0%")
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.theme.green)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.theme.green.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(8)
        .frame(width: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.06), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    private var topLosersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .foregroundStyle(Color.theme.red)
                    .font(.caption)
                Text("Top Losers 24h")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(viewModel.topLosers) { coin in
                        Button {
                            viewModel.selectCoinForDetail(coin)
                        } label: {
                            topLoserCard(coin: coin)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 2)
            }
        }
    }
    
    private func topLoserCard(coin: CoinModel) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                CoinImageView(coin: coin)
                    .frame(width: 22, height: 22)
                Spacer()
                Text("#\(coin.rank)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            Text(coin.symbol.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
            
            Text(coin.currentPrice.asFormattedPrice())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            HStack(spacing: 2) {
                Image(systemName: "arrow.down.right")
                    .font(.system(size: 7, weight: .bold))
                Text(coin.priceChangePercentage24H?.asPercentString() ?? "-0.0%")
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.theme.red)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.theme.red.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(8)
        .frame(width: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.06), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    private var columnTitles: some View {
        HStack(spacing: 4) {
            HStack(spacing: 3) {
                Text("Rank")
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .opacity((viewModel.sortOption == .rank || viewModel.sortOption == .rankReversed) ? 1.0 : 0.0)
                    .rotationEffect(Angle(degrees: viewModel.sortOption == .rank ? 0 : 180))
            }
            .fixedSize()
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.toggleRankSort()
            }
            
            Text("Coin")
                .lineLimit(1)
                .frame(width: 86, alignment: .center)
            
            Spacer(minLength: 6)
            
            Text("7D Trend")
                .font(.caption2)
                .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
                .frame(width: 60, alignment: .center)
            
            HStack(spacing: 3) {
                Text("Price")
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .opacity((viewModel.sortOption == .price || viewModel.sortOption == .priceReversed) ? 1.0 : 0.0)
                    .rotationEffect(Angle(degrees: viewModel.sortOption == .price ? 0 : 180))
            }
            .frame(width: 88, alignment: .trailing)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.togglePriceSort()
            }
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(Color.theme.secondaryText)
        .padding(.horizontal, 28)
        .padding(.vertical, 4)
    }
    
    private var coinsLazyList: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.displayedCoins) { coin in
                Button {
                    viewModel.selectCoinForDetail(coin)
                } label: {
                    CoinRowView(
                        coin: coin,
                        isFavorite: viewModel.isWatchlisted(coin: coin),
                        onFavoriteTapped: {
                            viewModel.toggleWatchlist(coin: coin)
                        }
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
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
                .buttonStyle(.plain)
                .padding(.horizontal)
                .contextMenu {
                    Button {
                        viewModel.toggleWatchlist(coin: coin)
                    } label: {
                        Label(
                            viewModel.isWatchlisted(coin: coin) ? "Remove from Watchlist" : "Add to Watchlist",
                            systemImage: viewModel.isWatchlisted(coin: coin) ? "star.slash" : "star"
                        )
                    }
                }
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Color.theme.secondaryText)
                .padding(.top, 40)
            
            Text("No results for \"\(viewModel.searchText)\"")
                .font(.headline)
                .foregroundStyle(Color.theme.accent)
            
            Text("Check the spelling or try searching for another cryptocurrency name or symbol.")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    MarketView()
        .environmentObject(DeveloperPreview.instance.homeVM)
}
