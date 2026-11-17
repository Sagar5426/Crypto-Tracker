//
//  WatchlistView.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI
import SwiftfulUI

struct WatchlistView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var vm: MarketViewModel
    @State private var searchText: String = ""
    @State private var showSearchBar: Bool = false
    @State private var selectedCoinForDetail: CoinModel? = nil
    @State private var showAddCoinSheet: Bool = false
    @State private var viewMode: WatchlistViewMode = .list
    @State private var filterCategory: WatchlistFilterCategory = .all
    @State private var sortOption: WatchlistSortOption = .rank
    @State private var scrollViewOffset: CGFloat = 0
    @State private var topSectionHeight: CGFloat = 160
    
    enum WatchlistViewMode: String {
        case list, grid
    }
    
    enum WatchlistFilterCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case gainers = "Gainers"
        case losers = "Losers"
        var id: String { rawValue }
    }
    
    enum WatchlistSortOption: String, CaseIterable, Identifiable {
        case rank = "Rank"
        case changeHighLow = "Top 24h Gainers"
        case changeLowHigh = "Top 24h Dips"
        case priceHighLow = "Price (High to Low)"
        case priceLowHigh = "Price (Low to High)"
        case alphabetical = "Name (A-Z)"
        
        var id: String { rawValue }
    }
    
    // MARK: - Computed Properties
    
    private var filteredAndSortedWatchlist: [CoinModel] {
        var coins = vm.watchlistCoins
        
        // Search filter
        if !searchText.isEmpty {
            let lower = searchText.lowercased()
            coins = coins.filter {
                $0.name.lowercased().contains(lower) ||
                $0.symbol.lowercased().contains(lower)
            }
        }
        
        // Category filter
        switch filterCategory {
        case .all:
            break
        case .gainers:
            coins = coins.filter { ($0.priceChangePercentage24H ?? 0) >= 0 }
        case .losers:
            coins = coins.filter { ($0.priceChangePercentage24H ?? 0) < 0 }
        }
        
        // Sorting
        switch sortOption {
        case .rank:
            coins.sort { $0.rank < $1.rank }
        case .changeHighLow:
            coins.sort { ($0.priceChangePercentage24H ?? 0) > ($1.priceChangePercentage24H ?? 0) }
        case .changeLowHigh:
            coins.sort { ($0.priceChangePercentage24H ?? 0) < ($1.priceChangePercentage24H ?? 0) }
        case .priceHighLow:
            coins.sort { $0.currentPrice > $1.currentPrice }
        case .priceLowHigh:
            coins.sort { $0.currentPrice < $1.currentPrice }
        case .alphabetical:
            coins.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        
        return coins
    }
    
    private var averageChange24H: Double {
        let valid = vm.watchlistCoins.compactMap { $0.priceChangePercentage24H }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0, +) / Double(valid.count)
    }
    
    private var gainersCount: Int {
        vm.watchlistCoins.filter { ($0.priceChangePercentage24H ?? 0) >= 0 }.count
    }
    
    private var losersCount: Int {
        vm.watchlistCoins.filter { ($0.priceChangePercentage24H ?? 0) < 0 }.count
    }
    
    private var topPerformer: CoinModel? {
        vm.watchlistCoins
            .filter { ($0.priceChangePercentage24H ?? 0) > 0 }
            .max(by: { ($0.priceChangePercentage24H ?? 0) < ($1.priceChangePercentage24H ?? 0) })
    }
    
    private var topDip: CoinModel? {
        vm.watchlistCoins
            .filter { ($0.priceChangePercentage24H ?? 0) < 0 }
            .min(by: { ($0.priceChangePercentage24H ?? 0) < ($1.priceChangePercentage24H ?? 0) })
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Adaptive canvas background & ambient glow
                Color.theme.screenBackground
                    .ignoresSafeArea()
                
                ambientGlowLayer
                
                VStack(spacing: 0) {
                    // Header kept intact at the top
                    topBar
                        .background(
                            Color.theme.screenBackground
                                .ignoresSafeArea(edges: .top)
                                .opacity(headerBackgroundOpacity)
                        )
                    
                    if vm.watchlistCoins.isEmpty {
                        ScrollView {
                            emptyWatchlistView
                                .padding(.top, 20)
                        }
                        .refreshable {
                            vm.reloadData()
                        }
                    } else {
                        scrollViewLayer
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddCoinSheet) {
                AddWatchlistCoinsSheet()
                    .environmentObject(vm)
            }
            .fullScreenCover(item: $selectedCoinForDetail) { coin in
                NavigationStack {
                    CoinDetailView(coin: coin)
                }
            }
        }
    }
}

// MARK: - Layout & Staged Fade Progress
extension WatchlistView {
    
    /// Progress from 0.0 (fully expanded at top) to 1.0 (fully collapsed and pinned)
    private var collapseProgress: Double {
        if !searchText.isEmpty { return 1.0 }
        guard scrollViewOffset < 0 else { return 0.0 }
        let collapseDistance = max(1.0, topSectionHeight - 10)
        return min(1.0, Double(-scrollViewOffset / collapseDistance))
    }
    
    /// Header background opacity turns solid as user scrolls past 30pt
    private var headerBackgroundOpacity: Double {
        min(1.0, max(0.0, -scrollViewOffset / 30.0))
    }
    
    /// Watchlist Pulse Card fades out smoothly (0% -> 65% of collapse)
    private var pulseCardFadeOpacity: Double {
        let progress = min(1.0, max(0.0, collapseProgress / 0.65))
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

// MARK: - Ambient, Top Bar & Collapsible Pulse Section
extension WatchlistView {
    
    private var ambientGlowLayer: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color.yellow.opacity(0.12), location: 0.0),
                    .init(color: (colorScheme == .dark ? Color.theme.accent.opacity(0.06) : Color.yellow.opacity(0.04)), location: 0.35),
                    .init(color: Color.clear, location: 0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.yellow.opacity(0.10),
                    Color.clear
                ]),
                center: .topLeading,
                startRadius: 20,
                endRadius: 260
            )
        }
        .ignoresSafeArea(edges: .top)
        .frame(height: 340 + max(0, scrollViewOffset))
        .offset(y: min(0, scrollViewOffset))
        .opacity(contentFadeOpacity)
        .allowsHitTesting(false)
    }
    
    /// Header bar kept intact at the top of Watchlist
    private var topBar: some View {
        HeaderView(
            title: "Watchlist",
            showSearchBar: $showSearchBar,
            searchText: $searchText,
            isLoading: vm.isLoading,
            onRefresh: {
                vm.reloadData()
            },
            onAdd: {
                showAddCoinSheet = true
            }
        )
        .padding(.bottom, 6)
    }
    
    /// Collapsible Watchlist Pulse Section that fades and disappears while scrolling
    private var collapsiblePulseSection: some View {
        watchlistPulseCard
            .padding(.horizontal)
            .opacity(pulseCardFadeOpacity)
            .scaleEffect(1.0 - (collapseProgress * 0.03), anchor: .top)
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
}

// MARK: - Watchlist Pulse Summary Card
extension WatchlistView {
    
    private var watchlistPulseCard: some View {
        let isPositive = averageChange24H >= 0
        let avgBadgeColor = isPositive ? Color.theme.green : Color.theme.red
        
        return VStack(spacing: 14) {
            // Top Row: Title + 24h Avg Trend Pill
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.16))
                            .frame(width: 34, height: 34)
                        Image(systemName: "star.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.yellow)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Watchlist Pulse")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.theme.accent)
                        
                        Text("\(vm.watchlistCoins.count) Assets Tracked")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                }
                
                Spacer()
                
                // 24H Average Badge
                HStack(spacing: 4) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(averageChange24H.asPercentString())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Text("24h avg")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(avgBadgeColor.opacity(0.8))
                }
                .foregroundStyle(avgBadgeColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(avgBadgeColor.opacity(0.12))
                .clipShape(Capsule())
            }
            
            Divider()
                .background(Color.theme.secondaryText.opacity(0.15))
            
            // Bottom 3-Metric Summary Row
            HStack(spacing: 12) {
                // Metric 1: Sentiment / Ratio
                VStack(alignment: .leading, spacing: 4) {
                    Text("Market Trend")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    HStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 8, weight: .bold))
                            Text("\(gainersCount)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Color.theme.green)
                        
                        Text("•")
                            .foregroundStyle(Color.theme.secondaryText.opacity(0.4))
                        
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 8, weight: .bold))
                            Text("\(losersCount)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Color.theme.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Metric 2: Top Gainer
                if let topGainer = topPerformer {
                    Button {
                        selectedCoinForDetail = topGainer
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Top Gainer")
                                .font(.caption2)
                                .foregroundStyle(Color.theme.secondaryText)
                            
                            VStack(spacing: 2) {
                                HStack(spacing: 4) {
                                    CoinImageView(coin: topGainer)
                                        .frame(width: 14, height: 14)
                                        .clipShape(Circle())
                                    
                                    Text(topGainer.symbol.uppercased())
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color.theme.accent)
                                }
                                    
                                    Text("+\(topGainer.priceChangePercentage24H?.asPercentString() ?? "0%")")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.theme.green)
                                
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Top Gainer")
                            .font(.caption2)
                            .foregroundStyle(Color.theme.secondaryText)
                        Text("—")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Metric 3: Top Dip
                if let dip = topDip {
                    Button {
                        selectedCoinForDetail = dip
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Top Dip")
                                .font(.caption2)
                                .foregroundStyle(Color.theme.secondaryText)
                            
                            VStack(spacing: 2) {
                                HStack(spacing: 4) {
                                    CoinImageView(coin: dip)
                                        .frame(width: 14, height: 14)
                                        .clipShape(Circle())
                                    
                                    Text(dip.symbol.uppercased())
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color.theme.accent)
                                }
                                
                                Text(dip.priceChangePercentage24H?.asPercentString() ?? "0%")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.theme.red)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Top Dip")
                            .font(.caption2)
                            .foregroundStyle(Color.theme.secondaryText)
                        Text("—")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

// MARK: - Filters, Controls & Column Titles
extension WatchlistView {
    
    // MARK: - Sticky Filter & Controls Bar
    private var stickyFilterBar: some View {
        VStack(spacing: 0) {
            filterAndControlsBar
                .padding(.horizontal)
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
    
    private var filterAndControlsBar: some View {
        HStack(spacing: 8) {
            // Filter Pills (All / Gainers / Losers)
            HStack(spacing: 6) {
                ForEach(WatchlistFilterCategory.allCases) { category in
                    let isSelected = filterCategory == category
                    let count: Int = {
                        switch category {
                        case .all: return vm.watchlistCoins.count
                        case .gainers: return gainersCount
                        case .losers: return losersCount
                        }
                    }()
                    
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            filterCategory = category
                        }
                        HapticManager.impact(style: .light)
                    } label: {
                        HStack(spacing: 4) {
                            Text(category.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            
                            Text("\(count)")
                                .font(.system(size: 10, weight: .semibold))
                                .opacity(0.7)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.theme.accent : Color.theme.secondaryText.opacity(0.1))
                        )
                        .foregroundStyle(isSelected ? Color.theme.background : Color.theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            // Sort Menu Button
            Menu {
                Picker("Sort By", selection: $sortOption) {
                    ForEach(WatchlistSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(sortOption == .rank ? Color.theme.secondaryText : Color.theme.accent)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.theme.secondaryText.opacity(0.1))
                )
            }
            
            // Grid / List Toggle
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewMode = viewMode == .list ? .grid : .list
                }
                HapticManager.impact(style: .light)
            } label: {
                Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.theme.accent)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.theme.secondaryText.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var columnTitles: some View {
        HStack(spacing: 4) {
            Text("Coin")
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text("7D Trend")
                .font(.caption2)
                .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
                .frame(width: 60, alignment: .center)
            
            Text("Price / 24h")
                .frame(width: 88, alignment: .trailing)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(Color.theme.secondaryText)
        .padding(.horizontal, 28)
        .padding(.vertical, 2)
    }
}

// MARK: - Main Scroll Content
extension WatchlistView {
    
    private var scrollViewLayer: some View {
        ScrollViewWithOnScrollChanged(
            .vertical,
            showsIndicators: false,
            content: {
                LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                    // Watchlist Pulse Summary Card (collapsible and disappears while scrolling)
                    if searchText.isEmpty {
                        collapsiblePulseSection
                            .zIndex(1)
                    }
                    
                    // Sticky Section: Filter & Controls Bar sticks intact when scrolled
                    Section {
                        // Watchlist Content
                        if filteredAndSortedWatchlist.isEmpty && !searchText.isEmpty {
                            noResultsView
                                .zIndex(0)
                        } else if filteredAndSortedWatchlist.isEmpty {
                            noCategoryMatchesView
                                .zIndex(0)
                        } else {
                            if viewMode == .list {
                                columnTitles
                                    .zIndex(0)
                                coinsListView
                                    .zIndex(0)
                            } else {
                                coinsGridView
                                    .zIndex(0)
                            }
                        }
                    } header: {
                        stickyFilterBar
                            .zIndex(10)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 32)
            },
            onScrollChanged: { offset in
                scrollViewOffset = offset.y
            }
        )
        .clipped()
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            vm.reloadData()
        }
    }
}

// MARK: - List & Grid Views
extension WatchlistView {
    
    private var coinsListView: some View {
        LazyVStack(spacing: 8) {
            ForEach(filteredAndSortedWatchlist) { coin in
                Button {
                    selectedCoinForDetail = coin
                } label: {
                    CoinRowView(
                        coin: coin,
                        isFavorite: true,
                        onFavoriteTapped: {
                            withAnimation {
                                vm.toggleWatchlist(coin: coin)
                            }
                        }
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.theme.background)
                            .shadow(color: Color.theme.accent.opacity(0.03), radius: 4, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .contextMenu {
                    Button(role: .destructive) {
                        withAnimation {
                            vm.toggleWatchlist(coin: coin)
                        }
                    } label: {
                        Label("Remove from Watchlist", systemImage: "star.slash")
                    }
                }
            }
        }
    }
    
    private var coinsGridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(filteredAndSortedWatchlist) { coin in
                Button {
                    selectedCoinForDetail = coin
                } label: {
                    WatchlistGridCard(coin: coin) {
                        withAnimation {
                            vm.toggleWatchlist(coin: coin)
                        }
                    }
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        withAnimation {
                            vm.toggleWatchlist(coin: coin)
                        }
                    } label: {
                        Label("Remove from Watchlist", systemImage: "star.slash")
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Watchlist Grid Card
struct WatchlistGridCard: View {
    let coin: CoinModel
    var onRemove: () -> Void
    
    var body: some View {
        let isPositive = (coin.priceChangePercentage24H ?? 0) >= 0
        let badgeColor = isPositive ? Color.theme.green : Color.theme.red
        
        VStack(alignment: .leading, spacing: 8) {
            // Header: Coin Icon + Rank + Star Remove Button
            HStack {
                CoinImageView(coin: coin)
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                
                Text("#\(coin.rank)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.yellow)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
            
            // Name & Symbol
            VStack(alignment: .leading, spacing: 2) {
                Text(coin.symbol.uppercased())
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                    .lineLimit(1)
                
                Text(coin.name)
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
            }
            
            // 7D Sparkline Chart
            MiniSparklineView(
                data: coin.sparklineIn7D?.price ?? [],
                isPositive: isPositive
            )
            .frame(height: 34)
            .padding(.vertical, 2)
            
            // Price & 24h Change Badge
            VStack(alignment: .leading, spacing: 4) {
                Text(coin.currentPrice.asFormattedPrice())
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                HStack(spacing: 3) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 8, weight: .bold))
                    Text(coin.priceChangePercentage24H?.asPercentString() ?? "0.0%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundStyle(badgeColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(badgeColor.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.secondaryText.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Empty & No Results Views
extension WatchlistView {
    
    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(Color.theme.secondaryText)
                .padding(.top, 24)
            
            Text("No results for \"\(searchText)\"")
                .font(.headline)
                .foregroundStyle(Color.theme.accent)
            
            Text("No coins in your watchlist match your search.")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var noCategoryMatchesView: some View {
        VStack(spacing: 10) {
            Text("No \(filterCategory.rawValue) in Watchlist")
                .font(.headline)
                .foregroundStyle(Color.theme.accent)
                .padding(.top, 20)
            
            Text("None of your tracked assets currently fall into the \(filterCategory.rawValue.lowercased()) category.")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
            
            Button("Show All Coins") {
                withAnimation {
                    filterCategory = .all
                }
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(Color.theme.accent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var emptyWatchlistView: some View {
        VStack(spacing: 20) {
            // Gold Star Illustration
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.12))
                    .frame(width: 88, height: 88)
                
                Circle()
                    .stroke(Color.yellow.opacity(0.25), lineWidth: 2)
                    .frame(width: 108, height: 108)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.yellow)
                    .shadow(color: Color.yellow.opacity(0.4), radius: 8, x: 0, y: 0)
            }
            
            VStack(spacing: 8) {
                Text("Your Watchlist is Empty")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                
                Text("Monitor live prices, 24-hour trends, and sparklines for cryptocurrencies you care about.")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Primary Action: Add Coins Button
            Button {
                showAddCoinSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Coins to Watchlist")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.theme.background)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.theme.accent)
                .clipShape(Capsule())
                .shadow(color: Color.theme.accent.opacity(0.2), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            
            // Quick Add Suggested Cards
            if !vm.allCoins.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular Cryptocurrencies:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.secondaryText)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(vm.allCoins.prefix(4)) { coin in
                            HStack {
                                CoinImageView(coin: coin)
                                    .frame(width: 28, height: 28)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(coin.symbol.uppercased())
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.theme.accent)
                                    
                                    Text(coin.name)
                                        .font(.caption2)
                                        .foregroundStyle(Color.theme.secondaryText)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(coin.currentPrice.asFormattedPrice())
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color.theme.accent)
                                    
                                    Text(coin.priceChangePercentage24H?.asPercentString() ?? "0.0%")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle((coin.priceChangePercentage24H ?? 0) >= 0 ? Color.theme.green : Color.theme.red)
                                }
                                
                                Button {
                                    withAnimation {
                                        vm.toggleWatchlist(coin: coin)
                                    }
                                } label: {
                                    Image(systemName: "star")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Color.yellow)
                                        .padding(.leading, 8)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.theme.background)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Add Coins to Watchlist Sheet
struct AddWatchlistCoinsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: MarketViewModel
    @State private var searchText: String = ""
    @State private var filterMode: AddFilterMode = .all
    
    enum AddFilterMode: String, CaseIterable, Identifiable {
        case all = "All"
        case notTracked = "Not Tracked"
        case tracked = "Tracked"
        var id: String { rawValue }
    }
    
    private var displayedCoins: [CoinModel] {
        var coins = vm.allCoins
        
        if !searchText.isEmpty {
            let lower = searchText.lowercased()
            coins = coins.filter {
                $0.name.lowercased().contains(lower) ||
                $0.symbol.lowercased().contains(lower)
            }
        }
        
        switch filterMode {
        case .all:
            break
        case .notTracked:
            coins = coins.filter { !vm.isWatchlisted(coin: $0) }
        case .tracked:
            coins = coins.filter { vm.isWatchlisted(coin: $0) }
        }
        
        return coins
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.screenBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Search Bar
                    SearchBarView(searchText: $searchText)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Filter Chips
                    HStack(spacing: 8) {
                        ForEach(AddFilterMode.allCases) { mode in
                            let isSelected = filterMode == mode
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    filterMode = mode
                                }
                            } label: {
                                Text(mode.rawValue)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? Color.theme.accent : Color.theme.secondaryText.opacity(0.12))
                                    )
                                    .foregroundStyle(isSelected ? Color.theme.background : Color.theme.secondaryText)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                        
                        Text("\(vm.watchlistCoinIDs.count) tracked")
                            .font(.caption)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    .padding(.horizontal)
                    
                    // Coins List
                    List {
                        ForEach(displayedCoins) { coin in
                            let isTracked = vm.isWatchlisted(coin: coin)
                            
                            HStack(spacing: 12) {
                                CoinImageView(coin: coin)
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(coin.symbol.uppercased())
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(Color.theme.accent)
                                        
                                        Text("#\(coin.rank)")
                                            .font(.caption2)
                                            .foregroundStyle(Color.theme.secondaryText)
                                    }
                                    
                                    Text(coin.name)
                                        .font(.caption)
                                        .foregroundStyle(Color.theme.secondaryText)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(coin.currentPrice.asFormattedPrice())
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.theme.accent)
                                    
                                    let change = coin.priceChangePercentage24H ?? 0
                                    Text(coin.priceChangePercentage24H?.asPercentString() ?? "0.0%")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(change >= 0 ? Color.theme.green : Color.theme.red)
                                }
                                
                                Button {
                                    withAnimation {
                                        vm.toggleWatchlist(coin: coin)
                                    }
                                } label: {
                                    Image(systemName: isTracked ? "star.fill" : "star")
                                        .font(.system(size: 18))
                                        .foregroundStyle(isTracked ? Color.yellow : Color.theme.secondaryText.opacity(0.4))
                                        .padding(.leading, 8)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.theme.background)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Manage Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(Color.theme.accent)
                }
            }
        }
    }
}
