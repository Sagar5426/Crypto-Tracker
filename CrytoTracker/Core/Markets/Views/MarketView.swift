//
//  MarketView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 30/07/2025.
//

import SwiftUI
import SwiftfulUI

struct MarketView: View {
    
    @EnvironmentObject private var vm: MarketViewModel
    @State private var showSearchBar: Bool = false
    @State private var selectedCoinForDetail: CoinModel? = nil
    @State private var scrollViewOffset: CGFloat = 0
    @State private var topSafeAreaInset: CGFloat = 59
    @State private var topSectionHeight: CGFloat = 160
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Base background
                Color.black
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
            .fullScreenCover(item: $selectedCoinForDetail) { coin in
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
                    .init(color: Color.theme.accent.opacity(0.18), location: 0.0),
                    .init(color: Color.theme.accent.opacity(0.08), location: 0.35),
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
                    Color.theme.accent.opacity(0.12),
                    Color.theme.accent.opacity(0.03),
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
                showSearchBar: $showSearchBar,
                searchText: $vm.searchText,
                isLoading: vm.isLoading,
                onRefresh: {
                    vm.reloadData()
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
        .allowsHitTesting(collapseProgress < 0.85)
    }
    
    // MARK: - Scroll View Layer
    private var scrollViewLayer: some View {
        ScrollViewWithOnScrollChanged(
            .vertical,
            showsIndicators: false,
            content: {
                LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                    // Collapsible Top Section (measured dynamically)
                    topCollapsibleSection
                        .zIndex(1)
                    
                    // Sticky Section: Filter chips stick at the top, below views scroll strictly underneath
                    Section {
                        // Top Movers strip (when in 'All' and not searching)
                        if vm.searchText.isEmpty && vm.marketCategory == .all && !vm.topMovers.isEmpty {
                            topMoversSection
                                .zIndex(0)
                        }
                        
                        // Sticky / Flowing Column Titles
                        columnTitles
                            .zIndex(0)
                        
                        // Coins List
                        if vm.displayedCoins.isEmpty && !vm.searchText.isEmpty {
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
            vm.reloadData()
        }
    }
    
    // MARK: - Sticky Filter Chips Row with Non-Transparent Background
    private var filterChipsRow: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MarketViewModel.MarketCategory.allCases) { category in
                        let isSelected = vm.marketCategory == category
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                vm.marketCategory = category
                            }
                            HapticManager.notification(type: .success)
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
                                    // Opaque base so individual chips are never see-through
                                    Capsule()
                                        .fill(Color.black)
                                    
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
                // 1. Solid black background strictly inside filterChipsRow bounds (never overlaps MarketStatsView)
                Color.black
                    .opacity(chipRowBackgroundOpacity)
                
                // 2. Top safe area shield that locks in as the header finishes collapsing
                Color.black
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
                    ForEach(vm.topMovers) { coin in
                        Button {
                            selectedCoinForDetail = coin
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
    
    private var columnTitles: some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("Coin")
                Image(systemName: "chevron.down")
                    .opacity((vm.sortOption == .rank || vm.sortOption == .rankReversed) ? 1.0 : 0.0)
                    .rotationEffect(Angle(degrees: vm.sortOption == .rank ? 0 : 180))
            }
            .onTapGesture {
                withAnimation(.default) {
                    vm.sortOption = vm.sortOption == .rank ? .rankReversed : .rank
                }
            }
            
            Spacer()
            
            Text("7D Trend")
                .font(.caption2)
                .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
                .frame(width: 55, alignment: .center)
            
            HStack(spacing: 4) {
                Text("Price / 24h")
                Image(systemName: "chevron.down")
                    .opacity((vm.sortOption == .price || vm.sortOption == .priceReversed) ? 1.0 : 0.0)
                    .rotationEffect(Angle(degrees: vm.sortOption == .price ? 0 : 180))
            }
            .frame(minWidth: 85, alignment: .trailing)
            .onTapGesture {
                withAnimation(.default) {
                    vm.sortOption = vm.sortOption == .price ? .priceReversed : .price
                }
            }
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(Color.theme.secondaryText)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var coinsLazyList: some View {
        LazyVStack(spacing: 8) {
            ForEach(vm.displayedCoins) { coin in
                Button {
                    selectedCoinForDetail = coin
                } label: {
                    CoinRowView(
                        coin: coin,
                        showHoldingColumn: false,
                        isFavorite: vm.isWatchlisted(coin: coin),
                        onFavoriteTapped: {
                            withAnimation {
                                vm.toggleWatchlist(coin: coin)
                            }
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
                        vm.toggleWatchlist(coin: coin)
                    } label: {
                        Label(
                            vm.isWatchlisted(coin: coin) ? "Remove from Watchlist" : "Add to Watchlist",
                            systemImage: vm.isWatchlisted(coin: coin) ? "star.slash" : "star"
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
            
            Text("No results for \"\(vm.searchText)\"")
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
