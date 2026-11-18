//
//  ProfitAndLossView.swift
//  CoinPilot
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI
import SwiftfulUI

@MainActor
struct ProfitAndLossView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var vm: MarketViewModel
    
    // MARK: - View Model
    @StateObject private var viewModel: ProfitAndLossViewModel
    
    // MARK: - Scroll & Geometry UI State
    @State private var scrollViewOffset: CGFloat = 0
    @State private var topSectionHeight: CGFloat = 220
    
    // MARK: - Initializer
    
    init(viewModel: ProfitAndLossViewModel? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel ?? ProfitAndLossViewModel())
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.theme.screenBackground
                .ignoresSafeArea()
            
            // Dynamic ambient crypto gradient glow that scrolls synchronously & fades out together
            backGroundGradientLayer
            
            VStack(spacing: 0) {
                // Header kept intact at the top
                topBar
                    .background(
                        Color.theme.screenBackground
                            .ignoresSafeArea(edges: .top)
                            .opacity(headerBackgroundOpacity)
                    )
                
                if viewModel.allCoinPnLSummaries.isEmpty {
                    emptyStateView
                        .padding(.horizontal)
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
        .fullScreenCover(item: $viewModel.selectedCoinForDetail) { coin in
            NavigationStack {
                CoinDetailView(coin: coin)
            }
        }
    }
}

// MARK: - Layout & Layers
extension ProfitAndLossView {
    
    // MARK: - Unified Collapse & Staged Fade Progress
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
    
    /// Metric Card fades out smoothly (0% -> 75% of collapse) as search bar approaches the pin line
    private var metricCardFadeOpacity: Double {
        let progress = min(1.0, max(0.0, collapseProgress / 0.75))
        return 1.0 - progress
    }
    
    /// Overall opacity for ambient background gradient
    private var contentFadeOpacity: Double {
        max(0.0, 1.0 - collapseProgress)
    }
    
    /// Solid background opacity for the search bar row itself (reaches 1.0 before pinning)
    private var searchBarBackgroundOpacity: Double {
        min(1.0, max(0.0, collapseProgress / 0.85))
    }
    
    // MARK: - Ambient Gradient Layer (Moves synchronously with scroll & fades out together)
    private var backGroundGradientLayer: some View {
        let isProfitable = viewModel.isOverallProfitable
        let pnlColor = isProfitable ? Color.theme.green : Color.theme.red
        
        return ZStack {
            // Multi-stop linear gradient for rich ambient background fade
            LinearGradient(
                stops: [
                    .init(color: pnlColor.opacity(colorScheme == .dark ? 0.14 : 0.08), location: 0.0),
                    .init(color: (colorScheme == .dark ? Color.theme.accent.opacity(0.07) : pnlColor.opacity(0.03)), location: 0.35),
                    .init(color: pnlColor.opacity(0.02), location: 0.65),
                    .init(color: Color.clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Soft ambient aura on top-trailing
            RadialGradient(
                gradient: Gradient(colors: [
                    pnlColor.opacity(colorScheme == .dark ? 0.12 : 0.06),
                    pnlColor.opacity(0.02),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 20,
                endRadius: 280
            )
            
            // Soft ambient accent aura on top-leading
            RadialGradient(
                gradient: Gradient(colors: [
                    (colorScheme == .dark ? Color.theme.accent.opacity(0.10) : pnlColor.opacity(0.04)),
                    Color.clear
                ]),
                center: .topLeading,
                startRadius: 20,
                endRadius: 260
            )
        }
        .ignoresSafeArea(edges: .top)
        .frame(height: 420 + max(0, scrollViewOffset))
        .offset(y: min(0, scrollViewOffset))
        .opacity(contentFadeOpacity)
        .allowsHitTesting(false)
    }
    
    // MARK: - Collapsible Metric Card Section
    private var collapsibleMetricSection: some View {
        SummaryMetricCardView(viewModel: viewModel)
            .opacity(metricCardFadeOpacity)
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
    
    // MARK: - Header Bar (Kept Intact)
    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.theme.accent)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color.theme.secondaryText.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            
            Text("Profit & Loss")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.theme.accent)
            
            Spacer()
            
            Button {
                viewModel.refreshData()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.theme.accent)
                    .rotationEffect(.degrees(viewModel.isLoading || viewModel.isSpinning ? 360 : 0))
                    .animation(
                        viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                        value: viewModel.isLoading
                    )
                    .frame(width: 38, height: 38)
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
    
    // MARK: - Scroll View Layer
    private var scrollViewLayer: some View {
        ScrollViewWithOnScrollChanged(
            .vertical,
            showsIndicators: false,
            content: {
                LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                    // Collapsible Metric Card
                    collapsibleMetricSection
                        .zIndex(1)
                    
                    // Sticky Section: Search Bar sits below metricCard and sticks intact when scrolled
                    Section {
                        if viewModel.filteredCoinPnLList.isEmpty {
                            filterEmptyStateView
                                .zIndex(0)
                        } else {
                            coinsLazyList
                                .zIndex(0)
                        }
                    } header: {
                        stickySearchBarRow
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
    
    // MARK: - Sticky Search Bar Row
    private var stickySearchBarRow: some View {
        VStack(spacing: 0) {
            SearchBarView(searchText: $viewModel.searchText)
                .padding(.top, 4)
                .padding(.bottom, 10)
            
            // Divider line below search bar when sticky
            Rectangle()
                .fill(Color.theme.secondaryText.opacity(0.18))
                .frame(height: 1)
                .opacity(searchBarBackgroundOpacity)
        }
        .background(
            Color.theme.screenBackground
                .opacity(searchBarBackgroundOpacity)
        )
    }
    
    // MARK: - Coins Lazy List
    private var coinsLazyList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredCoinPnLList) { coinPnL in
                if let coin = coinPnL.coinModel {
                    Button {
                        viewModel.selectedCoinForDetail = coin
                    } label: {
                        CoinTradeRowView(coinPnL: coinPnL)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                } else {
                    CoinTradeRowView(coinPnL: coinPnL)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Subviews & Helpers
extension ProfitAndLossView {
    
    // MARK: - Empty States
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.theme.accent.opacity(0.06))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.theme.accent.opacity(0.7))
            }
            
            Text("No Orders Logged")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Text("Execute buy or sell transactions on coins to view realized profits, losses, and open portfolio performance.")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private var filterEmptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(Color.theme.secondaryText.opacity(0.7))
                .padding(.top, 40)
            
            Text("No Matching Coins")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Text("No coins matched '\(viewModel.searchText)'.")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#if DEBUG
private func makePreviewVM() -> MarketViewModel {
    let vm = MarketViewModel(isForPreview: true)
    vm.allCoins = [
        DeveloperPreview.instance.coin,
        DeveloperPreview.instance.ethCoin,
        DeveloperPreview.instance.solCoin,
        DeveloperPreview.instance.adaCoin
    ]
    vm.portfolioCoins = vm.allCoins
    vm.loadMockTransactionsForPreview()
    return vm
}

#Preview("Profit & Loss - Full History") {
    NavigationStack {
        ProfitAndLossView()
            .environmentObject(makePreviewVM())
    }
}

#Preview("Profit & Loss - Dark Mode") {
    NavigationStack {
        ProfitAndLossView()
            .environmentObject(makePreviewVM())
            .preferredColorScheme(.dark)
    }
}

#Preview("Profit & Loss - Empty State") {
    NavigationStack {
        ProfitAndLossView()
            .environmentObject(DeveloperPreview.instance.homeVM)
    }
}
#endif
