//
//  WatchlistView.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

struct WatchlistView: View {
    @EnvironmentObject private var vm: MarketViewModel
    @State private var searchText: String = ""
    @State private var showSearchBar: Bool = false
    @State private var selectedCoinForDetail: CoinModel? = nil
    
    private var displayedWatchlist: [CoinModel] {
        if searchText.isEmpty {
            return vm.watchlistCoins
        } else {
            let lower = searchText.lowercased()
            return vm.watchlistCoins.filter {
                $0.name.lowercased().contains(lower) ||
                $0.symbol.lowercased().contains(lower)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        HeaderView(
                            title: "Watchlist",
                            showSearchBar: $showSearchBar,
                            searchText: $searchText,
                            isLoading: vm.isLoading,
                            onRefresh: {
                                vm.reloadData()
                            }
                        )
                        
                        if !vm.watchlistCoins.isEmpty {
                            watchlistHeader
                                .padding(.top, 4)
                            
                            if displayedWatchlist.isEmpty && !searchText.isEmpty {
                                noResultsView
                            } else {
                                coinsList
                            }
                        } else {
                            emptyWatchlistView
                                .padding(.top, 40)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .refreshable {
                    vm.reloadData()
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

// MARK: - Subviews
extension WatchlistView {
    
    private var watchlistHeader: some View {
        HStack {
            Text("Tracked Coins (\(displayedWatchlist.count))")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.secondaryText)
            
            Spacer()
            
            Text("7D Trend / 24h")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.secondaryText)
        }
        .padding(.horizontal)
    }
    
    private var coinsList: some View {
        LazyVStack(spacing: 8) {
            ForEach(displayedWatchlist) { coin in
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
    
    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Color.theme.secondaryText)
                .padding(.top, 24)
            
            Text("No results for \"\(searchText)\"")
                .font(.headline)
                .foregroundStyle(Color.theme.accent)
            
            Text("Check the spelling or try searching for another cryptocurrency.")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var emptyWatchlistView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "star.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.yellow)
            }
            
            Text("Your Watchlist is Empty")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Text("Keep an eye on cryptocurrencies you care about. Tap below to quickly add popular coins.")
                .font(.subheadline)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            
            VStack(spacing: 10) {
                Text("Suggested Coins:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
                
                HStack(spacing: 8) {
                    ForEach(vm.allCoins.prefix(4)) { coin in
                        Button {
                            withAnimation {
                                vm.toggleWatchlist(coin: coin)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text(coin.symbol.uppercased())
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.theme.accent.opacity(0.1))
                            .clipShape(Capsule())
                            .foregroundStyle(Color.theme.accent)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    WatchlistView()
        .environmentObject(DeveloperPreview.instance.homeVM)
}
