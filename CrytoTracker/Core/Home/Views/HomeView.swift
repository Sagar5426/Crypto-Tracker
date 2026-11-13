//
//  HomeView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 30/07/2025.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var vm: HomeViewModel
    @State private var showSearchBar: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Expandable Search Bar
                        if showSearchBar {
                            SearchBarView(searchText: $vm.searchText)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Global Market Overview Card
                        HomeStatsView(showPortfolio: .constant(false))
                            .padding(.top, 4)
                        
                        // Category Pills (All, Gainers, Losers, Top 10)
                        categoryPillsBar
                        
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
                    }
                    .padding(.bottom, 24)
                }
                .refreshable {
                    vm.reloadData()
                }
            }
            .navigationTitle("Markets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showSearchBar.toggle()
                            if !showSearchBar {
                                vm.searchText = ""
                                UIApplication.shared.endEditing()
                            }
                        }
                    } label: {
                        Image(systemName: showSearchBar ? "xmark" : "magnifyingglass")
                            .font(.headline)
                            .foregroundStyle(Color.theme.accent)
                    }
                }
            }
            .navigationDestination(for: CoinModel.self) { coin in
                DetailLoadingView(coin: .constant(coin))
            }
        }
    }
}

// MARK: - Subviews & Extensions
extension HomeView {
    
    private var categoryPillsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HomeViewModel.MarketCategory.allCases) { category in
                    let isSelected = vm.marketCategory == category
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.marketCategory = category
                        }
                        HapticManager.notification(type: .success)
                    } label: {
                        Text(category.rawValue)
                            .font(.caption)
                            .fontWeight(isSelected ? .bold : .medium)
                            .padding(.horizontal, 14)
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
            .padding(.horizontal)
            .padding(.vertical, 2)
        }
    }
    
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
                        NavigationLink(value: coin) {
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
                NavigationLink(value: coin) {
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
    HomeView()
        .environmentObject(DeveloperPreview.instance.homeVM)
}
