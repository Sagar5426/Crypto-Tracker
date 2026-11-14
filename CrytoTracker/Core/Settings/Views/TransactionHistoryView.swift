//
//  TransactionHistoryView.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

struct TransactionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: HomeViewModel
    
    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText: String = ""
    @State private var showClearConfirmation: Bool = false
    @State private var showWalletSheet: Bool = false
    
    enum TransactionFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case buys = "Buys"
        case sells = "Sells"
        case deposits = "Deposits"
        case withdrawals = "Withdraws"
        var id: String { rawValue }
    }
    
    private var filteredTransactions: [TransactionEntity] {
        var list = vm.transactions
        
        switch selectedFilter {
        case .all:
            break
        case .buys:
            list = list.filter { ($0.transactionType ?? "").uppercased() == "BUY" }
        case .sells:
            list = list.filter { ($0.transactionType ?? "").uppercased() == "SELL" }
        case .deposits:
            list = list.filter { ($0.transactionType ?? "").uppercased() == "DEPOSIT" }
        case .withdrawals:
            list = list.filter { ($0.transactionType ?? "").uppercased() == "WITHDRAW" }
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
        vm.transactions
            .filter {
                let type = ($0.transactionType ?? "").uppercased()
                return type == "BUY" || type == "SELL"
            }
            .map { $0.totalValue }
            .reduce(0, +)
    }
    
    private var totalCashDeposited: Double {
        vm.transactions
            .filter { ($0.transactionType ?? "").uppercased() == "DEPOSIT" }
            .map { $0.totalValue }
            .reduce(0, +)
    }
    
    private var totalBuyCount: Int {
        vm.transactions.filter { ($0.transactionType ?? "").uppercased() == "BUY" }.count
    }
    
    private var totalSellCount: Int {
        vm.transactions.filter { ($0.transactionType ?? "").uppercased() == "SELL" }.count
    }
    
    private var totalDepositCount: Int {
        vm.transactions.filter { ($0.transactionType ?? "").uppercased() == "DEPOSIT" }.count
    }
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                if !vm.transactions.isEmpty {
                    summaryMetricsCard
                    
                    filterBar
                    
                    if vm.transactions.count > 4 {
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
        .navigationTitle("Transaction History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    Button {
                        showWalletSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "banknote.fill")
                                .font(.caption2)
                            Text("Wallet")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.theme.green.opacity(0.12))
                        .foregroundStyle(Color.theme.green)
                        .clipShape(Capsule())
                    }
                    
                    if !vm.transactions.isEmpty {
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
        }
        .sheet(isPresented: $showWalletSheet) {
            NavigationStack {
                CashWalletView()
            }
        }
        .alert("Clear All History", isPresented: $showClearConfirmation) {
            Button("Clear All", role: .destructive) {
                withAnimation {
                    vm.clearAllTransactions()
                }
                HapticManager.notification(type: .success)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all logged Buy, Sell, Deposit, and Withdrawal records. Your current portfolio and cash balances will remain untouched.")
        }
    }
}

// MARK: - Subviews
extension TransactionHistoryView {
    
    private var summaryMetricsCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Cash Deposited")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                    Text(totalCashDeposited.asCurrencyWith2Decimals())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Crypto Volume Traded")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                    Text(totalCryptoVolume.asCurrencyWith2Decimals())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                }
            }
            
            Divider()
            
            HStack {
                // Deposit count chip
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.theme.green)
                        .frame(width: 7, height: 7)
                    Text("Deposits: \(totalDepositCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.green)
                }
                
                Spacer()
                
                // Buys count chip
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.theme.accent)
                        .frame(width: 7, height: 7)
                    Text("Buys: \(totalBuyCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.accent)
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
            
            TextField("Search by symbol, coin, or transaction type...", text: $searchText)
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
                let type = (transaction.transactionType ?? "").uppercased()
                
                if type == "DEPOSIT" {
                    cashDepositRow(transaction: transaction)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            deleteSwipeAction(for: transaction)
                        }
                } else if type == "WITHDRAW" {
                    cashWithdrawalRow(transaction: transaction)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            deleteSwipeAction(for: transaction)
                        }
                } else {
                    cryptoTradeRow(transaction: transaction)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            deleteSwipeAction(for: transaction)
                        }
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
    
    // MARK: - Cash Deposit Row UI (Clear & Distinct)
    private func cashDepositRow(transaction: TransactionEntity) -> some View {
        let date = transaction.timestamp ?? Date()
        let total = transaction.totalValue
        
        return HStack(spacing: 12) {
            // Distinct Cash Deposit Green Icon
            ZStack {
                Circle()
                    .fill(Color.theme.green.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "arrow.down.to.line.compact")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.theme.green)
            }
            
            // Deposit Details
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Cash Deposit")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                    
                    
                }
                
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.theme.green)
                    Text("Credited to USD Cash Wallet")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.85))
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 3) {
                Text("+" + total.asCurrencyWith2Decimals())
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.theme.green)
                    Text("Funds Added")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                Text("DEPOSIT")
                    .font(.system(size: 9, weight: .heavy))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.theme.green.opacity(0.16))
                    .foregroundStyle(Color.theme.green)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.green.opacity(0.04), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.green.opacity(0.25), lineWidth: 1)
        )
    }
    
    // MARK: - Cash Withdrawal Row UI
    private func cashWithdrawalRow(transaction: TransactionEntity) -> some View {
        let date = transaction.timestamp ?? Date()
        let total = transaction.totalValue
        
        return HStack(spacing: 12) {
            // Withdrawal Orange/Red Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "arrow.up.to.line.compact")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.orange)
            }
            
            // Withdrawal Details
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Cash Withdrawal")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                    
                    Text("WITHDRAW")
                        .font(.system(size: 9, weight: .heavy))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.16))
                        .foregroundStyle(Color.orange)
                        .clipShape(Capsule())
                }
                
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.orange)
                    Text("Debited from USD Cash Wallet")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.85))
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 3) {
                Text("-" + total.asCurrencyWith2Decimals())
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("Withdrawn")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.secondaryText)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.background)
                .shadow(color: Color.orange.opacity(0.04), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
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
            
            // Trade Execution Details
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
                
                Image(systemName: selectedFilter == .deposits ? "arrow.down.to.line.compact" : "clock.arrow.circlepath")
                    .font(.system(size: 36))
                    .foregroundStyle(selectedFilter == .deposits ? Color.theme.green : Color.theme.accent.opacity(0.7))
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
            
            if selectedFilter == .deposits {
                Button {
                    showWalletSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Deposit Cash Now")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.theme.green)
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all:
            return "No Transactions Found"
        case .buys:
            return "No Buy Orders Found"
        case .sells:
            return "No Sell Orders Found"
        case .deposits:
            return "No Cash Deposits Found"
        case .withdrawals:
            return "No Cash Withdrawals Found"
        }
    }
    
    private var emptyStateDescription: String {
        switch selectedFilter {
        case .all:
            return "Buy crypto or deposit simulated USD funds into your cash wallet to see transactions recorded here."
        case .buys:
            return "No buy orders recorded yet."
        case .sells:
            return "No sell orders recorded yet."
        case .deposits:
            return "Add simulated money to your cash wallet to fund your crypto trades."
        case .withdrawals:
            return "No cash withdrawals recorded."
        }
    }
}

#Preview {
    NavigationStack {
        TransactionHistoryView()
            .environmentObject(DeveloperPreview.instance.homeVM)
    }
}
