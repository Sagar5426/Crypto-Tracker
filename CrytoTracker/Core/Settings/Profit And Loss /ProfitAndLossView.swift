//
//  ProfitAndLossView.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

struct ProfitAndLossView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: MarketViewModel
    
    @State private var searchText: String = ""
    
    private var cryptoTransactions: [TransactionEntity] {
        vm.transactions.filter {
            let type = ($0.transactionType ?? "").uppercased()
            return ($0.coinID ?? "") != "usd-cash" && (type == "BUY" || type == "SELL")
        }
    }
    
    private var allCoinPnLSummaries: [CoinPnLSummary] {
        let summary = vm.realizedPnLSummary
        
        // Find all unique coin IDs from both transactions and current portfolio
        var orderedCoinIDs: [String] = []
        for tx in cryptoTransactions {
            if let id = tx.coinID, !id.isEmpty, !orderedCoinIDs.contains(id) {
                orderedCoinIDs.append(id)
            }
        }
        for pCoin in vm.portfolioCoins where (pCoin.currentHoldings ?? 0) > 0 {
            if !orderedCoinIDs.contains(pCoin.id) {
                orderedCoinIDs.append(pCoin.id)
            }
        }
        
        return orderedCoinIDs.compactMap { coinID in
            let coinTxs = cryptoTransactions.filter { $0.coinID == coinID }
            let liveCoin = vm.allCoins.first { $0.id.lowercased() == coinID.lowercased() }
            let portfolioCoin = vm.portfolioCoins.first { $0.id.lowercased() == coinID.lowercased() }
            
            let name = liveCoin?.name ?? coinTxs.first?.coinName ?? coinID.capitalized
            let symbol = (liveCoin?.symbol ?? coinTxs.first?.coinSymbol ?? "").uppercased()
            
            // Realized metrics from vm.realizedPnLSummary
            let coinRealizedTrades = summary.tradeDetails.values.filter { $0.coinID == coinID }
            let realizedPnL = coinRealizedTrades.map { $0.realizedPnL }.reduce(0, +)
            let realizedCostBasis = coinRealizedTrades.map { $0.costBasis }.reduce(0, +)
            let realizedProceeds = coinRealizedTrades.map { $0.saleProceeds }.reduce(0, +)
            let realizedQty = coinRealizedTrades.map { $0.sellAmount }.reduce(0, +)
            let sellAvg = realizedQty > 0 ? (realizedProceeds / realizedQty) : 0.0
            let realizedBuyAvg = realizedQty > 0 ? (realizedCostBasis / realizedQty) : 0.0
            let realizedPct = realizedCostBasis > 0 ? (realizedPnL / realizedCostBasis) * 100.0 : 0.0
            let closedCount = coinRealizedTrades.count
            
            // Unrealized metrics from portfolio / holdings
            let holdings = portfolioCoin?.currentHoldings ?? 0.0
            let hasOpenPos = holdings > 0.00000001
            let curPrice = liveCoin?.currentPrice ?? portfolioCoin?.currentPrice ?? 0.0
            let holdingsVal = hasOpenPos ? (portfolioCoin?.currentHoldingsValue ?? (holdings * curPrice)) : 0.0
            let unCostBasis = hasOpenPos ? (portfolioCoin?.costBasis ?? (holdings * (portfolioCoin?.averageBuyPrice ?? curPrice))) : 0.0
            let unPnL = hasOpenPos ? (portfolioCoin?.profitLoss ?? (holdingsVal - unCostBasis)) : 0.0
            let unPct = hasOpenPos ? (portfolioCoin?.profitLossPercentage ?? (unCostBasis > 0 ? (unPnL / unCostBasis) * 100.0 : 0.0)) : 0.0
            let buyAvg = hasOpenPos ? (portfolioCoin?.averageBuyPrice ?? (holdings > 0 ? unCostBasis / holdings : curPrice)) : 0.0
            
            return CoinPnLSummary(
                coinID: coinID,
                coinName: name,
                coinSymbol: symbol,
                coinModel: liveCoin ?? portfolioCoin,
                totalRealizedPnL: realizedPnL,
                totalRealizedPercentage: realizedPct,
                totalRealizedCostBasis: realizedCostBasis,
                totalRealizedProceeds: realizedProceeds,
                totalRealizedQty: realizedQty,
                realizedBuyAvgPrice: realizedBuyAvg,
                sellAvgPrice: sellAvg,
                closedTradesCount: closedCount,
                currentHoldings: holdings,
                currentPrice: curPrice,
                unrealizedCostBasis: unCostBasis,
                currentHoldingsValue: holdingsVal,
                unrealizedPnL: unPnL,
                unrealizedPercentage: unPct,
                buyAvgPrice: buyAvg,
                hasOpenPosition: hasOpenPos
            )
        }
    }
    
    private var filteredCoinPnLList: [CoinPnLSummary] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return allCoinPnLSummaries }
        let lower = trimmed.lowercased()
        return allCoinPnLSummaries.filter {
            $0.coinName.lowercased().contains(lower) ||
            $0.coinSymbol.lowercased().contains(lower)
        }
    }
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            if allCoinPnLSummaries.isEmpty {
                emptyStateView
                    .padding(.horizontal)
            } else {
                List {
                    // Header Overview Card
                    Section {
                        SummaryMetricCardView()
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 6, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    
                    // Single P&L Row Per Coin or Filtered Empty State
                    if filteredCoinPnLList.isEmpty {
                        Section {
                            filterEmptyStateView
                                .listRowInsets(EdgeInsets(top: 40, leading: 16, bottom: 40, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    } else {
                        Section {
                            ForEach(filteredCoinPnLList) { coinPnL in
                                CoinTradeRowView(coinPnL: coinPnL)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search coins by name or symbol..."
                )
            }
        }
        .navigationTitle("Profit and Loss")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Coin P&L Summary Model
struct CoinPnLSummary: Identifiable {
    var id: String { coinID }
    let coinID: String
    let coinName: String
    let coinSymbol: String
    let coinModel: CoinModel?
    
    // Realized metrics
    let totalRealizedPnL: Double
    let totalRealizedPercentage: Double
    let totalRealizedCostBasis: Double
    let totalRealizedProceeds: Double
    let totalRealizedQty: Double
    let realizedBuyAvgPrice: Double
    let sellAvgPrice: Double
    let closedTradesCount: Int
    
    // Unrealized metrics
    let currentHoldings: Double
    let currentPrice: Double
    let unrealizedCostBasis: Double
    let currentHoldingsValue: Double
    let unrealizedPnL: Double
    let unrealizedPercentage: Double
    let buyAvgPrice: Double
    let hasOpenPosition: Bool
    
    var netPnL: Double {
        totalRealizedPnL + (hasOpenPosition ? unrealizedPnL : 0.0)
    }
    
    var netPercentage: Double {
        let totalCost = totalRealizedCostBasis + (hasOpenPosition ? unrealizedCostBasis : 0.0)
        return totalCost > 0 ? (netPnL / totalCost) * 100.0 : 0.0
    }
    
    var hasRealizedActivity: Bool {
        closedTradesCount > 0
    }
    
    var isNetProfitable: Bool {
        netPnL >= 0
    }
    
    var isRealizedProfitable: Bool {
        totalRealizedPnL >= 0
    }
    
    var isUnrealizedProfitable: Bool {
        unrealizedPnL >= 0
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
            
            Text("No Matching Coins")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Text("No coins matched '\(searchText)'.")
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
