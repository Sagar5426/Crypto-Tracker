//
//  CoinInvestmentBreakdownView.swift
//  CrytoTracker
//
//  Created by Antigravity on 15/11/2026.
//

import SwiftUI

struct CoinInvestmentBreakdownView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeVM: MarketViewModel
    let coin: CoinModel
    
    struct PurchaseLot: Identifiable {
        let id: String
        let date: Date
        let amount: Double
        let pricePerCoin: Double
    }
    
    private var purchaseLots: [PurchaseLot] {
        let buyTxs = homeVM.transactions(for: coin.id)
            .filter { ($0.transactionType ?? "").uppercased() == "BUY" }
        
        if !buyTxs.isEmpty {
            return buyTxs.map { tx in
                PurchaseLot(
                    id: tx.id ?? UUID().uuidString,
                    date: tx.timestamp ?? Date(),
                    amount: tx.amount,
                    pricePerCoin: tx.pricePerCoin
                )
            }
        }
        
        // Fallback for coins held without granular buy records (e.g. manual portfolio entry or preview)
        if let holdings = coin.currentHoldings, holdings > 0 {
            let buyPrice = coin.averageBuyPrice ?? coin.currentPrice
            let fallbackDate = Calendar.current.date(byAdding: .day, value: -78, to: Date()) ?? Date()
            return [
                PurchaseLot(
                    id: "primary-lot",
                    date: fallbackDate,
                    amount: holdings,
                    pricePerCoin: buyPrice
                )
            ]
        }
        
        return []
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        holdingSummaryCard
                        transactionsSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("\(coin.name) Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CoinImageView(coin: coin)
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
                        Text(coin.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                        
                        Text(coin.symbol.uppercased())
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
                    Text("Market Price")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text(coin.currentPrice.asFormattedPrice())
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                }
            }
            
            Divider()
                .overlay(Color.theme.secondaryText.opacity(0.15))
            
            // Total Quantity Row
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
                
                Text("\((coin.currentHoldings ?? 0).asNumberString()) \(coin.symbol.uppercased())")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            // Present Value Row
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
                
                Text(coin.currentHoldingsValue.asCurrencyWith2Decimals())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            // Average Buy Price Row
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
                
                Text((coin.averageBuyPrice ?? coin.currentPrice).asFormattedPrice())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            // Total P&L Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: coin.profitLoss >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(coin.profitLoss >= 0 ? Color.theme.green : Color.theme.red)
                    Text("Total P&L")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text("\((coin.profitLoss >= 0 ? "+" : ""))\(coin.profitLoss.asCurrencyWith2Decimals()) (\((coin.profitLoss >= 0 ? "+" : ""))\(coin.profitLossPercentage.asPercentString()))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(coin.profitLoss >= 0 ? Color.theme.green : Color.theme.red)
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
    
    // MARK: - Transactions Section
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.accent)
                
                Text("Purchase Transactions")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
                
                Spacer()
                
                Text("\(purchaseLots.count) \(purchaseLots.count == 1 ? "Lot" : "Lots")")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            .padding(.top, 4)
            
            if purchaseLots.isEmpty {
                emptyTransactionsPlaceholder
            } else {
                VStack(spacing: 10) {
                    ForEach(purchaseLots) { lot in
                        transactionRow(for: lot)
                    }
                }
            }
        }
    }
    
    // MARK: - Transaction Row
    private func transactionRow(for lot: PurchaseLot) -> some View {
        let lotPnl = lot.amount * (coin.currentPrice - lot.pricePerCoin)
        let lotPnlPct = lot.pricePerCoin > 0 ? ((coin.currentPrice - lot.pricePerCoin) / lot.pricePerCoin) * 100 : 0
        let isProfitable = lotPnl >= 0
        
        return VStack(alignment: .leading, spacing: 0) {
            
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.theme.secondaryText)
                
                Text(lot.date.asDayMonthYearString())
                    .fontWeight(.medium)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            .font(.footnote)
            .padding(.bottom, 4)
            
        HStack(alignment: .bottom) {
            // VStack 1: Date of purchase, Qty bought, Price at which bought
            VStack(alignment: .leading, spacing: 2) {
                
                
                Text("Qty \(lot.amount.asNumberString())")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Text("Price \(lot.pricePerCoin.asFormattedPrice())")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            Spacer()
            
            // VStack 2: How many days old purchase, P&L according to that purchase price
            VStack(alignment: .trailing, spacing: 2) {
                Text(daysOldText(from: lot.date))
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.theme.secondaryText)
                
                HStack(spacing: 3) {
                    Text("\(isProfitable ? "+ " : "")\(lotPnl.asCurrencyWith2Decimals())")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundStyle(isProfitable ? Color.theme.green : Color.theme.red)
            }
        }
    }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
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
    
    // MARK: - Helpers
    private func daysOldText(from date: Date) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfPurchase = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: startOfPurchase, to: startOfToday)
        let days = max(0, components.day ?? 0)
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day old"
        } else {
            return "\(days) days old"
        }
    }
}

// MARK: - Previews
#Preview("Breakdown - Profitable (Dark)") {
    CoinInvestmentBreakdownView(coin: DeveloperPreview.instance.coin)
        .environmentObject(DeveloperPreview.instance.homeVM)
        .preferredColorScheme(.dark)
}

#Preview("Breakdown - Loss (Dark)") {
    CoinInvestmentBreakdownView(coin: DeveloperPreview.instance.adaCoin)
        .environmentObject(DeveloperPreview.instance.homeVM)
        .preferredColorScheme(.dark)
}

#Preview("Breakdown - Light Mode") {
    CoinInvestmentBreakdownView(coin: DeveloperPreview.instance.coin)
        .environmentObject(DeveloperPreview.instance.homeVM)
        .preferredColorScheme(.light)
}
