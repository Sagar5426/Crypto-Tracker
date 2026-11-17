//
//  CoinInvestmentBreakdownView.swift
//  CrytoTracker
//
//  Created by Antigravity on 15/11/2026.
//

import SwiftUI

@MainActor
struct CoinInvestmentBreakdownView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeVM: MarketViewModel
    @StateObject private var viewModel: CoinInvestmentBreakdownViewModel
    
    typealias PurchaseLot = CoinInvestmentBreakdownViewModel.PurchaseLot
    
    init(coin: CoinModel, viewModel: CoinInvestmentBreakdownViewModel? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel ?? CoinInvestmentBreakdownViewModel(coin: coin))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Section 1: Overview Holding Position Card
                Section {
                    holdingSummaryCard
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                
                // Section 2: Purchase Transactions with Apple Native Swipe Actions
                Section {
                    if viewModel.purchaseLots.isEmpty {
                        emptyTransactionsPlaceholder
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 24, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.purchaseLots) { lot in
                            PurchaseLotCardRow(
                                lot: lot,
                                coin: viewModel.currentCoin
                            )
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    viewModel.editLot(lot)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                } header: {
                    transactionsSectionHeader
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.theme.screenBackground.ignoresSafeArea())
            .navigationTitle("\(viewModel.currentCoin.name) Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CoinImageView(coin: viewModel.currentCoin)
                        .frame(width: 28, height: 28)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline).bold()
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                viewModel.setMarketViewModel(homeVM)
            }
            .sheet(item: $viewModel.editingLot) { lot in
                EditTransactionSheet(coin: viewModel.currentCoin, lot: lot) { updatedDate, updatedAmount, updatedPrice in
                    viewModel.updateTransaction(
                        id: lot.id,
                        updatedDate: updatedDate,
                        updatedAmount: updatedAmount,
                        updatedPrice: updatedPrice
                    )
                }
            }
        }
    }
}

// MARK: - Subviews & Sections
extension CoinInvestmentBreakdownView {
    
    // MARK: - Holding Summary Card
    private var holdingSummaryCard: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT POSITION")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    HStack(spacing: 6) {
                        Text(viewModel.currentCoin.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                        
                        Text(viewModel.currentCoin.symbol.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.theme.secondaryText.opacity(0.12))
                            .clipShape(Capsule())
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Current Price")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text(viewModel.currentCoin.currentPrice.asFormattedPrice())
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                }
            }
            
            Divider()
                .background(Color.theme.secondaryText.opacity(0.12))
            
            // Row 1: Total Quantity Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "number.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.orange)
                    Text("Total Quantity")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text("\((viewModel.currentCoin.currentHoldings ?? 0).asNumberString()) \(viewModel.currentCoin.symbol.uppercased())")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            // Row 2: Present Value Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "banknote.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.purple)
                    Text("Present Value")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text(viewModel.currentCoin.currentHoldingsValue.asCurrencyWith2Decimals())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            // Row 3: Average Buy Price Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.cyan)
                    Text("Average Buy Price")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text((viewModel.currentCoin.averageBuyPrice ?? viewModel.currentCoin.currentPrice).asFormattedPrice())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            // Row 4: Total Unrealized P&L Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.currentCoin.profitLoss >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(viewModel.currentCoin.profitLoss >= 0 ? Color.theme.green : Color.theme.red)
                    Text("Total P&L")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text("\(viewModel.currentCoin.profitLoss >= 0 ? "+" : "")\(viewModel.currentCoin.profitLoss.asCurrencyWith2Decimals()) (\(viewModel.currentCoin.profitLoss >= 0 ? "+" : "")\(viewModel.currentCoin.profitLossPercentage.asPercentString()))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(viewModel.currentCoin.profitLoss >= 0 ? Color.theme.green : Color.theme.red)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.05), radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Transactions Header
    private var transactionsSectionHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.subheadline)
                .foregroundStyle(Color.theme.accent)
            
            Text("Purchase Transactions")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Spacer()
            
            Text("\(viewModel.purchaseLots.count) \(viewModel.purchaseLots.count == 1 ? "Lot" : "Lots")")
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.theme.secondaryText.opacity(0.12))
                .clipShape(Capsule())
                .foregroundStyle(Color.theme.secondaryText)
        }
    }
    
    // MARK: - Empty State
    private var emptyTransactionsPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.theme.secondaryText.opacity(0.4))
            
            Text("No recorded buy transactions")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.secondaryText.opacity(0.10), lineWidth: 1)
        )
    }
}

// MARK: - Redesigned Transaction Lot Card Row Component (Matching TradeRowCard Layout)
private struct PurchaseLotCardRow: View {
    let lot: CoinInvestmentBreakdownView.PurchaseLot
    let coin: CoinModel
    
    private var badgeColor: Color {
        Color.theme.green
    }
    
    private var executionDate: Date {
        lot.date
    }
    
    private var totalCost: Double {
        lot.amount * lot.pricePerCoin
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1. Top Header Row: Coin Icon + Name + Symbol & Date on Left, BUY ORDER Badge on Right
            HStack(alignment: .center, spacing: 10) {
                coinIconView
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(coin.name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.theme.accent)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Text(coin.symbol.uppercased())
                            .font(.system(size: 9.5, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color.theme.secondaryText.opacity(0.1))
                            .foregroundStyle(Color.theme.secondaryText)
                            .clipShape(Capsule())
                            .lineLimit(1)
                    }
                    
                    Text(executionDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.theme.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                // Order Type Badge (BUY ORDER)
                Text("BUY ORDER")
                    .font(.system(size: 9.5, weight: .heavy))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.14))
                    .foregroundStyle(badgeColor)
                    .clipShape(Capsule())
                    .lineLimit(1)
            }
            
            // 2. Structured Data Section
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    // Qty Bought
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Qty Bought")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(Color.theme.secondaryText)
                        
                        Text(formatUnits(lot.amount) + " " + coin.symbol.uppercased())
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(badgeColor)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Buying Price
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Buying Price")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(Color.theme.secondaryText)
                        
                        Text(lot.pricePerCoin.asFormattedPrice())
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.theme.accent)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                }
                
                Divider()
                    .background(Color.theme.secondaryText.opacity(0.08))
                
                // Buying Total Value
                HStack(alignment: .center) {
                    Text("Buying Total Value")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Spacer()
                    
                    Text(totalCost.asCurrencyWith2Decimals())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
            .padding(10)
            .background(Color.theme.secondaryText.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var coinIconView: some View {
        ZStack {
            Circle()
                .fill(Color.theme.secondaryText.opacity(0.08))
                .frame(width: 36, height: 36)
            
            CoinImageView(coin: coin)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        }
    }
    
    private func formatUnits(_ amount: Double) -> String {
        let absVal = abs(amount)
        if absVal >= 1.0 {
            return amount.asNumberString()
        } else {
            return String(format: "%.4f", amount).replacingOccurrences(
                of: #"(\.\d*?[1-9])0+$|\.0+$"#,
                with: "$1",
                options: .regularExpression
            )
        }
    }
}

// MARK: - Previews
#Preview("Coin Investment Breakdown - Dark") {
    CoinInvestmentBreakdownView(coin: DeveloperPreview.instance.coin)
        .environmentObject(DeveloperPreview.instance.homeVM)
        .preferredColorScheme(.dark)
}

#Preview("Coin Investment Breakdown - Light") {
    CoinInvestmentBreakdownView(coin: DeveloperPreview.instance.coin)
        .environmentObject(DeveloperPreview.instance.homeVM)
        .preferredColorScheme(.light)
}
