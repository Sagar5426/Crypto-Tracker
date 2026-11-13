//
//  PortfolioScreen.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

struct PortfolioScreen: View {
    @EnvironmentObject private var vm: HomeViewModel
    @State private var showManageSheet = false
    @State private var selectedCoinToEdit: CoinModel? = nil
    @State private var coinToDelete: CoinModel? = nil
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        PortfolioSummaryCard(onAddTapped: {
                            showManageSheet.toggle()
                        })
                        .padding(.top, 8)
                        
                        if vm.portfolioCoins.isEmpty {
                            portfolioEmptyState
                                .padding(.top, 20)
                        } else {
                            holdingsHeader
                            holdingsList
                        }
                    }
                    .padding(.bottom, 24)
                }
                .refreshable {
                    vm.reloadData()
                }
            }
            .navigationTitle("Portfolio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showManageSheet.toggle()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.theme.accent)
                    }
                }
            }
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
            .navigationDestination(for: CoinModel.self) { coin in
                DetailLoadingView(coin: .constant(coin))
            }
        }
    }
}

// MARK: - Subviews
extension PortfolioScreen {
    
    private var holdingsHeader: some View {
        HStack {
            Text("Your Assets (\(vm.portfolioCoins.count))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Spacer()
            
            Text("Holdings / Price")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.secondaryText)
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
    
    private var holdingsList: some View {
        LazyVStack(spacing: 8) {
            ForEach(vm.portfolioCoins) { coin in
                HStack(spacing: 0) {
                    NavigationLink(value: coin) {
                        CoinRowView(coin: coin, showHoldingColumn: true)
                    }
                    .buttonStyle(.plain)
                    
                    // Quick Action Menu
                    Menu {
                        Button {
                            selectedCoinToEdit = coin
                        } label: {
                            Label("Edit Holdings", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            coinToDelete = coin
                            showDeleteConfirmation = true
                        } label: {
                            Label("Remove Holding", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.secondaryText)
                            .frame(width: 28, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
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
                .padding(.horizontal)
                .contextMenu {
                    Button {
                        selectedCoinToEdit = coin
                    } label: {
                        Label("Edit Holdings", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        coinToDelete = coin
                        showDeleteConfirmation = true
                    } label: {
                        Label("Remove from Portfolio", systemImage: "trash")
                    }
                }
            }
        }
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

#Preview {
    PortfolioScreen()
        .environmentObject(DeveloperPreview.instance.homeVM)
}
