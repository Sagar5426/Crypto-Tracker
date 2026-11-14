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
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    Color.theme.background
                        .ignoresSafeArea()
                    
                    // Dynamic ambient crypto gradient glow that scrolls synchronously with content
                    backGroundGradientLayer
                    
                    // Scrollable content with collapsible top header & stats, plus sticky filter chips
                    scrollViewLayer
                    
                    // Top safe area cover that masks content scrolling into status bar area
                    topSafeAreaCover(topInset: geometry.safeAreaInsets.top)
                }
            }
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
    
    // MARK: - Opacity Calculations (Fade Animation)
    private var headerOpacity: Double {
        if scrollViewOffset >= 0 { return 1.0 }
        return max(0.0, 1.0 + Double(scrollViewOffset / 70.0))
    }
    
    private var marketStatsOpacity: Double {
        if scrollViewOffset >= -15 { return 1.0 }
        return max(0.0, 1.0 + Double((scrollViewOffset + 15) / 95.0))
    }
    
    /// Progress (0.0 to 1.0) of header and market stats fading out and filter chips becoming pinned
    private var stickyProgress: Double {
        if scrollViewOffset >= -30 { return 0.0 }
        if scrollViewOffset <= -110 { return 1.0 }
        return Double((-scrollViewOffset - 30.0) / 80.0)
    }
    
    // MARK: - Top Safe Area Cover (Blocks scrolling data behind status bar)
    private func topSafeAreaCover(topInset: CGFloat) -> some View {
        Color.theme.background
            .opacity(stickyProgress)
            .frame(height: topInset)
            .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Ambient Gradient Layer (Moves synchronously with scroll)
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
    }
    
    // MARK: - Scroll View Layer
    private var scrollViewLayer: some View {
        ScrollViewWithOnScrollChanged(
            .vertical,
            showsIndicators: false,
            content: {
                LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                    // 1. Collapsible Top Header with pure opacity fade
                    HeaderView(
                        title: "Markets",
                        showSearchBar: $showSearchBar,
                        searchText: $vm.searchText,
                        isLoading: vm.isLoading,
                        onRefresh: {
                            vm.reloadData()
                        }
                    )
                    .opacity(headerOpacity)
                    
                    // 2. Collapsible Global Market Overview Card with pure opacity fade
                    MarketStatsView(showPortfolio: .constant(false))
                        .padding(.top, 2)
                        .opacity(marketStatsOpacity)
                    
                    // 3. Sticky Section: Filter chips stick at the top, below views scroll inside
                    Section {
                        // Top Movers strip (when in 'All' and not searching)
                        if vm.searchText.isEmpty && vm.marketCategory == .all && !vm.topMovers.isEmpty {
                            topMoversSection
                        }
                        
                        // Sticky / Flowing Column Titles
                        columnTitles
                        
                        // Coins List
                        if vm.displayedCoins.isEmpty && !vm.searchText.isEmpty {
                            noResultsView
                        } else {
                            coinsLazyList
                        }
                    } header: {
                        filterChipsRow
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
    
    // MARK: - Sticky Filter Chips Row with dynamic transparency & divider
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
                                Capsule()
                                    .fill(isSelected ? Color.theme.accent : Color.theme.secondaryText.opacity(0.1))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                            )
                            .foregroundStyle(isSelected ? Color.theme.background : Color.theme.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            
            // Small divider line below filter chips (fades in as header & stats fade)
            Rectangle()
                .fill(Color.theme.secondaryText.opacity(0.15))
                .frame(height: 1)
                .opacity(stickyProgress)
        }
        .background(
            Color.theme.background
                .opacity(stickyProgress)
        )
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
