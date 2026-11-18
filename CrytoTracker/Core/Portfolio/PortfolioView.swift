//
//  PortfolioView.swift
//  CoinPilot
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI
import SwiftfulUI

@MainActor
struct PortfolioView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var vm: MarketViewModel
    
    // MARK: - View Model
    @StateObject private var viewModel: PortfolioViewModel
    
    // MARK: - Layout State
    @State private var scrollViewOffset: CGFloat = 0
    @State private var fullHeaderSize: CGSize = .zero
    
    // MARK: - Initializer
    
    init(viewModel: PortfolioViewModel? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel ?? PortfolioViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Adaptive canvas background
                Color.theme.screenBackground
                    .ignoresSafeArea()
                
                // Dynamic ambient crypto gradient glow that responds to scroll and P&L
                backGroundGradientLayer
                
                // Scrollable content that scrolls through and underneath the sticky header
                scrollViewLayer
                
                // Sticky Header View (pinned at top, Netflix-style)
                stickyHeaderView
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.setMarketViewModel(vm)
            }
            .sheet(isPresented: $viewModel.showManageSheet) {
                ManagePortfolioView()
                    .environmentObject(vm)
            }
            .sheet(item: $viewModel.selectedCoinToEdit) { coin in
                ManagePortfolioView(selectedCoin: coin)
                    .environmentObject(vm)
            }
            .alert("Remove Holding", isPresented: $viewModel.showDeleteConfirmation, presenting: viewModel.coinToDelete) { _ in
                Button("Remove", role: .destructive) {
                    viewModel.confirmDeleteHolding()
                }
                Button("Cancel", role: .cancel) { }
            } message: { coin in
                Text("Are you sure you want to remove \(coin.name) from your portfolio?")
            }
            .fullScreenCover(item: $viewModel.selectedCoinForDetail) { coin in
                NavigationStack {
                    CoinDetailView(coin: coin)
                }
            }
        }
    }
}

// MARK: - Sticky Header & Ambient Background (Netflix-Style)
extension PortfolioView {
    
    // MARK: - Sticky Top Header View
    private var stickyHeaderView: some View {
        HeaderView(
            title: "Portfolio",
            showSearchBar: $viewModel.showSearchBar,
            searchText: $viewModel.searchText,
            isLoading: viewModel.isLoading,
            onRefresh: {
                viewModel.reloadData()
            },
            onAdd: {
                viewModel.openManageSheet()
            }
        )
        .padding(.bottom, 8)
        .background(
            ZStack {
                if scrollViewOffset < -15 {
                    Rectangle()
                        .fill(Color.clear)
                        .background(.ultraThinMaterial)
                        .overlay(colorScheme == .dark ? Color.black.opacity(0.35) : Color.clear)
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
                    .init(color: (colorScheme == .dark ? Color.theme.accent.opacity(0.18) : viewModel.pnlColor.opacity(0.08)), location: 0.0),
                    .init(color: (colorScheme == .dark ? Color.theme.accent.opacity(0.08) : viewModel.pnlColor.opacity(0.03)), location: 0.35),
                    .init(color: viewModel.pnlColor.opacity(0.05), location: 0.65),
                    .init(color: Color.clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Soft ambient P&L aura on top-trailing
            RadialGradient(
                gradient: Gradient(colors: [
                    viewModel.pnlColor.opacity(colorScheme == .dark ? 0.14 : 0.08),
                    viewModel.pnlColor.opacity(colorScheme == .dark ? 0.04 : 0.02),
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
                        viewModel.openManageSheet()
                    })
                    
                    if viewModel.portfolioCoins.isEmpty {
                        portfolioEmptyState
                            .padding(.top, 20)
                    } else {
                        holdingsHeader
                        if viewModel.displayedPortfolioCoins.isEmpty && !viewModel.searchText.isEmpty {
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
            viewModel.reloadData()
        }
    }
}

// MARK: - Subviews
extension PortfolioView {
    
    private var holdingsHeader: some View {
        HStack {
            Text("Your Assets (\(viewModel.displayedPortfolioCoins.count))")
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
            ForEach(viewModel.displayedPortfolioCoins) { coin in
                Button {
                    viewModel.selectCoinForDetail(coin)
                } label: {
                    PortfolioCoinRowView(coin: coin)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.background)
                                .shadow(color: Color.theme.accent.opacity(0.04), radius: 4, x: 0, y: 2)
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
                        viewModel.editHolding(for: coin)
                    } label: {
                        Label("Edit Holdings", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        viewModel.promptDelete(for: coin)
                    } label: {
                        Label("Remove Holding", systemImage: "trash")
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
                .padding(.top, 24)
            
            Text("No holdings for \"\(viewModel.searchText)\"")
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
                viewModel.openManageSheet()
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

/// Backward compatibility alias
typealias PortfolioScreen = PortfolioView

#Preview("Portfolio View") {
    PortfolioView()
        .environmentObject(DeveloperPreview.instance.homeVM)
}
