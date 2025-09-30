//
//  HomeView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 30/07/2025.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var vm: HomeViewModel
    @State private var showPortfolio = false // for animate right
    @State private var showPortolioViewSheet = false // for newSheet
    
    
    var body: some View {
        // The NavigationStack now handles the navigation flow.
        NavigationStack {
            ZStack {
                // background layer
                Color.theme.background
                    .ignoresSafeArea()
                    .sheet(isPresented: $showPortolioViewSheet) {
                        // sheets are a new environment so if we want to use current view environment we need to manually pass it in sheet
                        PortfolioView()
                            .environmentObject(vm)
                    }
                
                // content layer
                VStack {
                    homeHeader
                    HomeStatsView(showPortfolio: $showPortfolio)
                    SearchBarView(searchText: $vm.searchText)
                    columnTitles
                    
                    if !showPortfolio {
                        allCoinsList
                            .transition(.move(edge: .leading))
                    }
                    if showPortfolio {
                        portfolioCoinsList
                            .transition(.move(edge: .trailing))
                    }
                    Spacer(minLength: 0)
                }
            }
            // This modifier handles which view to show when a CoinModel is passed to a NavigationLink.
            // This is the modern, lazy-loading approach.
            .navigationDestination(for: CoinModel.self) { coin in
                // We use .constant here because DetailLoadingView expects a Binding,
                // and the coin from the navigation destination is immutable.
                DetailLoadingView(coin: .constant(coin))
            }
        }
        // The old, deprecated NavigationLink in the background has been removed.
    }
}

#Preview {
    // The NavigationStack is now inside HomeView, so we don't need it here.
    HomeView()
        .toolbar(.hidden, for: .navigationBar)
        .environmentObject(HomeViewModel())
}

extension HomeView {
    private var homeHeader: some View {
        HStack {
            CircleButtonView(iconName: showPortfolio ? "plus" : "info")
                .animation(.none, value: showPortfolio)
                .onTapGesture {
                    if showPortfolio {
                        showPortolioViewSheet.toggle()
                    }
                }
                .background(
                    CircleButtonAnimationView(animate: $showPortfolio)
                )
            Spacer()
            
            Text(showPortfolio ? "Portfolio" : "Live Prices")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundStyle(Color.theme.accent)
                .animation(.none, value: showPortfolio)
            
            Spacer()
            CircleButtonView(iconName: "chevron.right")
                .rotationEffect(Angle(degrees: showPortfolio ? 180 : 0))
                .onTapGesture {
                    withAnimation(.spring()) {
                        showPortfolio.toggle()
                    }
                }
        }
        .padding(.horizontal)
    }
    
    private var allCoinsList: some View {
        List {
            ForEach(vm.allCoins) { coin in
                // Use a ZStack to overlay an invisible NavigationLink
                ZStack {
                    // Your custom row view is the background
                    CoinRowView(coin: coin, showHoldingColumn: false)
                    
                    // The NavigationLink is an invisible layer on top
                    NavigationLink(value: coin) {
                        EmptyView()
                        }
                    .opacity(0)
                }
                .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 10))
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var portfolioCoinsList: some View {
        List {
            ForEach(vm.portfolioCoins) { coin  in
                
                // Use a ZStack to overlay an invisible NavigationLink
                ZStack {
                    // Your custom row view is the background
                    CoinRowView(coin: coin, showHoldingColumn: true)
                    
                    // The NavigationLink is an invisible layer on top
                    NavigationLink(value: coin) {
                        EmptyView()
                        }
                    .opacity(0)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // The segue function is no longer needed as NavigationStack handles the navigation state.
    // private func segue(coin: CoinModel) {
    //     selectedCoin = coin
    //     showDetailView.toggle()
    // }
    
    private var columnTitles: some View {
        HStack {
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
            if showPortfolio {
                HStack(spacing: 4) {
                    Text("Portfolio")
                    Image(systemName: "chevron.down")
                        .opacity((vm.sortOption == .holdings || vm.sortOption == .holdingsReversed) ? 1.0 : 0.0)
                        .rotationEffect(Angle(degrees: vm.sortOption == .holdings ? 0 : 180))
                }
                .onTapGesture {
                    withAnimation(.default) {
                        vm.sortOption = vm.sortOption == .holdings ? .holdingsReversed : .holdings
                    }
                }
            }
            
            HStack(spacing: 4) {
                Text("Price")
                Image(systemName: "chevron.down")
                    .opacity((vm.sortOption == .price || vm.sortOption == .priceReversed) ? 1.0 : 0.0)
                    .rotationEffect(Angle(degrees: vm.sortOption == .price ? 0 : 180))
            }
            .frame(width: UIScreen.main.bounds.width/3.5, alignment: .trailing)
            .onTapGesture {
                withAnimation(.default) {
                    vm.sortOption = vm.sortOption == .price ? .priceReversed : .price
                }
            }
            
            Button {
                withAnimation(.linear(duration: 2.0)) {
                    vm.reloadData()
                }
            } label: {
                Image(systemName: "goforward")
            }
            .rotationEffect(Angle(degrees: vm.isLoading ? 360 : 0), anchor: .center)
        }
        .font(.caption)
        .foregroundStyle(Color.theme.secondaryText)
        .padding(.horizontal)
    }
}
