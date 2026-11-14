//
//  PortfolioScreen.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI
import SwiftfulUI

struct PortfolioScreen: View {
    @EnvironmentObject private var vm: MarketViewModel
    @State private var showManageSheet = false
    @State private var selectedCoinToEdit: CoinModel? = nil
    @State private var coinToDelete: CoinModel? = nil
    @State private var showDeleteConfirmation = false
    @State private var swipedCoinId: String? = nil
    @State private var selectedCoinForDetail: CoinModel? = nil
    @State private var showSearchBar: Bool = false
    @State private var searchText: String = ""
    @State private var scrollViewOffset: CGFloat = 0
    @State private var fullHeaderSize: CGSize = .zero
    
    private var displayedPortfolioCoins: [CoinModel] {
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
    
    /// Dynamic PnL color to influence ambient aura based on portfolio performance
    private var pnlColor: Color {
        if vm.portfolioCoins.isEmpty {
            return Color.theme.green
        }
        return vm.portfolioTotalProfitLoss >= 0 ? Color.theme.green : Color.theme.red
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Base background (black for deep OLED contrast)
                Color.black
                    .ignoresSafeArea()
                
                // Dynamic ambient crypto gradient glow that responds to scroll and P&L
                backGroundGradientLayer
                
                // Scrollable content that scrolls through and underneath the sticky header
                scrollViewLayer
                
                // Sticky Header View (pinned at top, Netflix-style)
                stickyHeaderView
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showManageSheet) {
                PortfolioView()
                    .environmentObject(vm)
            }
            .sheet(item: $selectedCoinToEdit) { coin in
                PortfolioView(selectedCoin: coin)
                    .environmentObject(vm)
            }
            .alert("Remove Holding", isPresented: $showDeleteConfirmation, presenting: coinToDelete) { coin in
                Button("Remove", role: .destructive) {
                    withAnimation {
                        vm.deleteHolding(coin: coin)
                    }
                    HapticManager.notification(type: .success)
                }
                Button("Cancel", role: .cancel) { }
            } message: { coin in
                Text("Are you sure you want to remove \(coin.name) from your portfolio?")
            }
            .fullScreenCover(item: $selectedCoinForDetail) { coin in
                NavigationStack {
                    CoinDetailView(coin: coin)
                }
            }
        }
    }
}

// MARK: - Sticky Header & Ambient Background (Netflix-Style)
extension PortfolioScreen {
    
    // MARK: - Sticky Top Header View
    private var stickyHeaderView: some View {
        HeaderView(
            title: "Portfolio",
            showSearchBar: $showSearchBar,
            searchText: $searchText,
            isLoading: vm.isLoading,
            onRefresh: {
                vm.reloadData()
            },
            onAdd: {
                showManageSheet.toggle()
            }
        )
        .padding(.bottom, 8)
        .background(
            ZStack {
                if scrollViewOffset < -15 {
                    Rectangle()
                        .fill(Color.clear)
                        .background(.ultraThinMaterial)
                        .overlay(Color.black.opacity(0.35))
                        .ignoresSafeArea(edges: .top)
                    
                    // Subtle bottom separator line
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.theme.secondaryText.opacity(0.12))
                            .frame(height: 0.5)
                    }
                }
            }
        )
        .animation(.smooth, value: scrollViewOffset)
        .readingFrame { frame in
            if abs(fullHeaderSize.height - frame.size.height) > 1 && frame.size.height > 0 {
                fullHeaderSize = frame.size
            }
        }
    }
    
    // MARK: - Dynamic Ambient Crypto Gradient Glow
    private var backGroundGradientLayer: some View {
        ZStack {
            // Multi-stop linear gradient for rich ambient background fade
            LinearGradient(
                stops: [
                    .init(color: Color.theme.accent.opacity(0.18), location: 0.0),
                    .init(color: Color.theme.accent.opacity(0.08), location: 0.35),
                    .init(color: pnlColor.opacity(0.05), location: 0.65),
                    .init(color: Color.clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Soft ambient P&L aura on top-trailing
            RadialGradient(
                gradient: Gradient(colors: [
                    pnlColor.opacity(0.14),
                    pnlColor.opacity(0.04),
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
        .frame(maxHeight: max(10, 400 + scrollViewOffset * 0.75))
        .opacity(scrollViewOffset < -220 ? 0 : 1)
        .animation(.smooth, value: scrollViewOffset)
        .allowsHitTesting(false)
    }
    
    // MARK: - Scroll View Layer
    private var scrollViewLayer: some View {
        ScrollViewWithOnScrollChanged(
            .vertical,
            showsIndicators: false,
            content: {
                VStack(spacing: 16) {
                    // Spacer equal to header height so content begins directly below sticky header
                    Rectangle()
                        .opacity(0)
                        .frame(height: max(50, fullHeaderSize.height))
                    
                    PortfolioSummaryCard(onAddTapped: {
                        showManageSheet.toggle()
                    })
                    
                    if vm.portfolioCoins.isEmpty {
                        portfolioEmptyState
                            .padding(.top, 20)
                    } else {
                        holdingsHeader
                        if displayedPortfolioCoins.isEmpty && !searchText.isEmpty {
                            noResultsView
                        } else {
                            holdingsList
                        }
                    }
                }
                .padding(.bottom, 24)
            },
            onScrollChanged: { offset in
                scrollViewOffset = min(0, offset.y)
            }
        )
        .refreshable {
            vm.reloadData()
        }
    }
}

// MARK: - Subviews
extension PortfolioScreen {
    
    private var holdingsHeader: some View {
        HStack {
            Text("Your Assets (\(displayedPortfolioCoins.count))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Spacer()
            
            Text("Holdings / P&L")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.secondaryText)
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
    
    private var holdingsList: some View {
        LazyVStack(spacing: 8) {
            ForEach(displayedPortfolioCoins) { coin in
                PortfolioSwipeableRow(
                    coin: coin,
                    swipedCoinId: $swipedCoinId,
                    onTap: {
                        selectedCoinForDetail = coin
                    },
                    onEdit: {
                        selectedCoinToEdit = coin
                    },
                    onRemove: {
                        coinToDelete = coin
                        showDeleteConfirmation = true
                    }
                )
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Color.theme.secondaryText)
                .padding(.top, 24)
            
            Text("No holdings for \"\(searchText)\"")
                .font(.headline)
                .foregroundStyle(Color.theme.accent)
            
            Text("Check the spelling or try searching for another coin in your portfolio.")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var portfolioEmptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.theme.accent.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.theme.accent)
            }
            
            Text("Build Your Portfolio")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Text("Add coins to track your holdings, live valuations, 24h profit and loss, and asset allocation percentages.")
                .font(.subheadline)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            
            Button {
                showManageSheet.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Asset")
                }
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.background)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.theme.accent)
                .clipShape(Capsule())
                .shadow(color: Color.theme.accent.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Swipeable Row Component
private struct PortfolioSwipeableRow: View {
    let coin: CoinModel
    @Binding var swipedCoinId: String?
    let onTap: () -> Void
    let onEdit: () -> Void
    let onRemove: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    private let actionButtonsWidth: CGFloat = 126
    
    private var isSwipedOpen: Bool {
        swipedCoinId == coin.id
    }
    
    private var currentOffset: CGFloat {
        let base: CGFloat = isSwipedOpen ? -actionButtonsWidth : 0
        return base + dragOffset
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Action Buttons Revealed Behind Card
            actionButtons
            
            // Foreground Interactive Card
            cardContent
                .offset(x: currentOffset)
                .simultaneousGesture(swipeGesture)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 6) {
            // Edit Button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    swipedCoinId = nil
                }
                HapticManager.impact(style: .light)
                onEdit()
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .bold))
                    Text("Edit")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(width: 58)
                .frame(maxHeight: .infinity)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            // Remove Button
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    swipedCoinId = nil
                }
                HapticManager.impact(style: .medium)
                onRemove()
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .bold))
                    Text("Remove")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(width: 58)
                .frame(maxHeight: .infinity)
                .background(Color.theme.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 1)
    }
    
    // MARK: - Card Content
    private var cardContent: some View {
        ZStack {
            Button {
                if !isSwipedOpen {
                    onTap()
                }
            } label: {
                PortfolioCoinRowView(coin: coin)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .disabled(isSwipedOpen)
            
            // Tap outside to close when swiped open
            if isSwipedOpen {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            swipedCoinId = nil
                        }
                    }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit Holdings", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove Holding", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Swipe Gesture
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 15, coordinateSpace: .local)
            .onChanged { value in
                // Only respond if drag is primarily horizontal
                if abs(value.translation.width) > abs(value.translation.height) {
                    let base: CGFloat = isSwipedOpen ? -actionButtonsWidth : 0
                    let proposed = base + value.translation.width
                    
                    if proposed <= 0 {
                        // Dragging left: clamp with rubber-banding past action buttons
                        let overdrag = max(-actionButtonsWidth - proposed, 0)
                        dragOffset = (proposed - base) + (overdrag * 0.2)
                    } else {
                        // Dragging right: slight elastic resistance
                        dragOffset = min(value.translation.width * 0.2, 10)
                    }
                }
            }
            .onEnded { value in
                let horizontalDrag = value.translation.width
                let velocity = value.predictedEndTranslation.width
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if isSwipedOpen {
                        // If already open, swiping right or fast flick closes it
                        if horizontalDrag > 25 || velocity > 60 {
                            swipedCoinId = nil
                        } else {
                            swipedCoinId = coin.id
                        }
                    } else {
                        // If closed, swiping left or fast flick opens it
                        if horizontalDrag < -40 || velocity < -80 {
                            swipedCoinId = coin.id
                            HapticManager.impact(style: .light)
                        } else {
                            swipedCoinId = nil
                        }
                    }
                    dragOffset = 0
                }
            }
    }
}

#Preview("Portfolio Screen") {
    PortfolioScreen()
        .environmentObject(DeveloperPreview.instance.homeVM)
}

#Preview("Portfolio Swipeable Row") {
    VStack(spacing: 16) {
        PortfolioSwipeableRow(
            coin: DeveloperPreview.instance.coin,
            swipedCoinId: .constant(nil),
            onTap: {},
            onEdit: {},
            onRemove: {}
        )
        
        PortfolioSwipeableRow(
            coin: DeveloperPreview.instance.adaCoin,
            swipedCoinId: .constant(DeveloperPreview.instance.adaCoin.id),
            onTap: {},
            onEdit: {},
            onRemove: {}
        )
    }
    .padding(.vertical)
    .background(Color.theme.background)
    .preferredColorScheme(.dark)
}
