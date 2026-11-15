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
    
    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText: String = ""
    @State private var showClearConfirmation: Bool = false
    
    enum TransactionFilter: String, CaseIterable, Identifiable {
        case all = "All Trades"
        case sells = "Sells (Realized)"
        case buys = "Buys"
        var id: String { rawValue }
    }
    
    private var cryptoTransactions: [TransactionEntity] {
        vm.transactions.filter {
            let type = ($0.transactionType ?? "").uppercased()
            return ($0.coinID ?? "") != "usd-cash" && (type == "BUY" || type == "SELL")
        }
    }
    
    private var filteredTransactions: [TransactionEntity] {
        var list = cryptoTransactions
        
        switch selectedFilter {
        case .all:
            break
        case .sells:
            list = list.filter { ($0.transactionType ?? "").uppercased() == "SELL" }
        case .buys:
            list = list.filter { ($0.transactionType ?? "").uppercased() == "BUY" }
        }
        
        if !searchText.isEmpty {
            let lower = searchText.lowercased()
            list = list.filter {
                ($0.coinName ?? "").lowercased().contains(lower) ||
                ($0.coinSymbol ?? "").lowercased().contains(lower) ||
                ($0.transactionType ?? "").lowercased().contains(lower)
            }
        }
        
        return list
    }
    
    private var totalCryptoVolume: Double {
        cryptoTransactions
            .map { $0.totalValue }
            .reduce(0, +)
    }
    
    private var totalBuyCount: Int {
        cryptoTransactions.filter { ($0.transactionType ?? "").uppercased() == "BUY" }.count
    }
    
    private var totalSellCount: Int {
        cryptoTransactions.filter { ($0.transactionType ?? "").uppercased() == "SELL" }.count
    }
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                if !cryptoTransactions.isEmpty {
                    summaryMetricsCard
                    
                    filterBar
                    
                    if cryptoTransactions.count > 4 {
                        searchBar
                    }
                }
                
                if filteredTransactions.isEmpty {
                    emptyStateView
                } else {
                    transactionList
                }
            }
            .padding(.top, 8)
        }
        .navigationTitle("Profit and Loss")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !cryptoTransactions.isEmpty {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.red)
                    }
                }
            }
        }
        .alert("Clear Trade History", isPresented: $showClearConfirmation) {
            Button("Clear All", role: .destructive) {
                withAnimation {
                    vm.clearAllTransactions()
                }
                HapticManager.notification(type: .success)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all logged Buy and Sell trade records. Your current portfolio and cash balances will remain untouched.")
        }
    }
}

// MARK: - Subviews
extension ProfitAndLossView {
    
    private var summaryMetricsCard: some View {
        let summary = vm.realizedPnLSummary
        let hasClosedTrades = summary.totalClosedTrades > 0
        let isProfitable = summary.isProfitable
        
        return VStack(spacing: 12) {
            // Realized Profit / Loss Hero Section
            VStack(spacing: 8) {
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: hasClosedTrades ? (isProfitable ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis") : "chart.line.flattrend.xyaxis")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(hasClosedTrades ? (isProfitable ? Color.theme.green : Color.theme.red) : Color.theme.secondaryText)
                        
                        Text("REALIZED PROFIT / LOSS")
                            .font(.caption2)
                            .fontWeight(.heavy)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Text(hasClosedTrades ? "\(summary.totalClosedTrades) Closed \(summary.totalClosedTrades == 1 ? "Trade" : "Trades")" : "No Closed Trades")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Color.theme.secondaryText.opacity(0.12))
                        .clipShape(Capsule())
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text("\(hasClosedTrades && isProfitable ? "+" : "")\(summary.totalRealizedPnL.asCurrencyWith2Decimals())")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(hasClosedTrades ? (isProfitable ? Color.theme.green : Color.theme.red) : Color.theme.accent)
                    
                    if hasClosedTrades {
                        Text("\(isProfitable ? "+" : "")\(summary.totalRealizedPercentage.asPercentString())")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((isProfitable ? Color.theme.green : Color.theme.red).opacity(0.14))
                            .foregroundStyle(isProfitable ? Color.theme.green : Color.theme.red)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    if hasClosedTrades {
                        Text("\(Int(summary.winRate))% Win Rate")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(summary.winRate >= 50 ? Color.theme.green : Color.theme.red)
                    }
                }
                
                if hasClosedTrades {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("Gain:")
                                .font(.caption2)
                                .foregroundStyle(Color.theme.secondaryText)
                            Text("+\(summary.totalRealizedGains.asCurrencyWith2Decimals())")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.green)
                        }
                        
                        HStack(spacing: 4) {
                            Text("Loss:")
                                .font(.caption2)
                                .foregroundStyle(Color.theme.secondaryText)
                            Text("-\(summary.totalRealizedLosses.asCurrencyWith2Decimals())")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.red)
                        }
                        
                        Spacer()
                        
                        Text("\(summary.profitableTradesCount)W / \(summary.lossTradesCount)L")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                } else {
                    Text("Only closed (sold) crypto positions generate realized profit or loss.")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill((hasClosedTrades ? (isProfitable ? Color.theme.green : Color.theme.red) : Color.theme.accent).opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke((hasClosedTrades ? (isProfitable ? Color.theme.green : Color.theme.red) : Color.theme.secondaryText).opacity(0.15), lineWidth: 1)
            )
            
            // Trading Volume & Basis stats
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Closed Trades Cost Basis")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    Text(summary.totalCostBasis.asCurrencyWith2Decimals())
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Crypto Volume Traded")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    Text(totalCryptoVolume.asCurrencyWith2Decimals())
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                }
            }
            
            Divider()
            
            HStack {
                // Buys count chip
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.theme.green)
                        .frame(width: 7, height: 7)
                    Text("Buys: \(totalBuyCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.green)
                }
                
                Spacer()
                
                // Sells count chip
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.theme.red)
                        .frame(width: 7, height: 7)
                    Text("Sells: \(totalSellCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.red)
                }
                
                Spacer()
                
                // Closed realized trades count chip
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.theme.accent)
                        .frame(width: 7, height: 7)
                    Text("Realized: \(summary.totalClosedTrades)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.accent)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TransactionFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption)
                            .fontWeight(selectedFilter == filter ? .bold : .medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? Color.theme.accent : Color.theme.secondaryText.opacity(0.1))
                            )
                            .foregroundStyle(selectedFilter == filter ? Color.theme.background : Color.theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
            
            TextField("Search by symbol, coin, or order type...", text: $searchText)
                .font(.caption)
                .foregroundStyle(Color.theme.accent)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                }
            }
        }
        .padding(8)
        .background(Color.theme.secondaryText.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
    
    private var transactionList: some View {
        List {
            ForEach(filteredTransactions, id: \.id) { transaction in
                cryptoTradeRow(transaction: transaction)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        deleteSwipeAction(for: transaction)
                    }
            }
        }
        .listStyle(.plain)
    }
    
    private func deleteSwipeAction(for transaction: TransactionEntity) -> some View {
        Button(role: .destructive) {
            withAnimation {
                vm.deleteTransaction(transaction)
            }
            HapticManager.notification(type: .success)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Crypto Buy & Sell Row UI
    private func cryptoTradeRow(transaction: TransactionEntity) -> some View {
        let isBuy = (transaction.transactionType ?? "").uppercased() == "BUY"
        let symbol = (transaction.coinSymbol ?? "").uppercased()
        let name = transaction.coinName ?? ""
        let date = transaction.timestamp ?? Date()
        let amount = transaction.amount
        let price = transaction.pricePerCoin
        let total = transaction.totalValue
        let realizedInfo = !isBuy ? vm.realizedInfo(for: transaction.id ?? "") : nil
        
        return HStack(spacing: 12) {
            // Direction Badge Icon
            ZStack {
                Circle()
                    .fill((isBuy ? Color.theme.green : Color.theme.red).opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: isBuy ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isBuy ? Color.theme.green : Color.theme.red)
            }
            
            // Coin Info & Timestamp
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(symbol)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                    
                    Text(isBuy ? "BUY" : "SELL")
                        .font(.system(size: 9, weight: .heavy))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((isBuy ? Color.theme.green : Color.theme.red).opacity(0.12))
                        .foregroundStyle(isBuy ? Color.theme.green : Color.theme.red)
                        .clipShape(Capsule())
                }
                
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
                
                if !name.isEmpty {
                    Text(name)
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Trade Execution Details & Realized P&L
            VStack(alignment: .trailing, spacing: 3) {
                Text((isBuy ? "+" : "-") + "\(amount.asNumberString()) \(symbol)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(isBuy ? Color.theme.green : Color.theme.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(total.asCurrencyWith2Decimals())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.accent)
                
                Text("@ \(price.asFormattedPrice())")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
                
                if let info = realizedInfo {
                    HStack(spacing: 3) {
                        Image(systemName: info.isProfitable ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 8, weight: .bold))
                        Text("\(info.isProfitable ? "+" : "")\(info.realizedPnL.asCurrencyWith2Decimals()) (\(info.isProfitable ? "+" : "")\(info.realizedPercentage.asPercentString()))")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(info.isProfitable ? Color.theme.green : Color.theme.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((info.isProfitable ? Color.theme.green : Color.theme.red).opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.top, 1)
                    
                    Text("Cost: \(info.costBasis.asCurrencyWith2Decimals())")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.theme.secondaryText)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.03), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Empty State View
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
            
            Text(emptyStateTitle)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Text(emptyStateDescription)
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all:
            return "No Trades Found"
        case .sells:
            return "No Sell Orders Found"
        case .buys:
            return "No Buy Orders Found"
        }
    }
    
    private var emptyStateDescription: String {
        switch selectedFilter {
        case .all:
            return "Execute buy and sell orders on coins to track your realized profit and loss."
        case .sells:
            return "No sell orders recorded yet. Sell coins to realize profits or losses."
        case .buys:
            return "No buy orders recorded yet."
        }
    }
}

#Preview {
    NavigationStack {
        ProfitAndLossView()
            .environmentObject(DeveloperPreview.instance.homeVM)
    }
}
