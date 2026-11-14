//
//  CoinHoldingCard.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

/// A dedicated card displaying the user's personal holding position for a specific coin in DetailView.
struct CoinHoldingCard: View {
    @EnvironmentObject private var homeVM: MarketViewModel
    let coin: CoinModel
    var onBuyTapped: (() -> Void)? = nil
    var onSellTapped: (() -> Void)? = nil
    
    private var isProfitable: Bool {
        coin.profitLoss >= 0
    }
    
    private var is24HProfitable: Bool {
        (coin.priceChangePercentage24H ?? 0) >= 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection
            financialMetricsGrid
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.06), radius: 10, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.theme.accent.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

// MARK: - Subviews
extension CoinHoldingCard {
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "briefcase.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.accent)
                    
                    Text("\(coin.name.uppercased()) POSITION")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                tradeActionPills
            }
            
            Text(coin.currentHoldingsValue.asCurrencyWith2Decimals())
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            HStack(spacing: 8) {
                totalProfitBadge
                
                Text("•")
                    .foregroundStyle(Color.theme.secondaryText.opacity(0.5))
                
                Text("\((coin.currentHoldings ?? 0).asNumberString()) \(coin.symbol.uppercased())")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
                
                if homeVM.portfolioTotalValue > 0 {
                    Text("•")
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.5))
                    
                    Text("\(String(format: "%.1f%%", homeVM.portfolioShare(for: coin))) of Portfolio")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.top, 2)
        }
    }
    
    // MARK: - Trade Action Pills
    private var tradeActionPills: some View {
        HStack(spacing: 6) {
            if let onBuy = onBuyTapped {
                Button {
                    onBuy()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text("Buy")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.theme.green.opacity(0.15))
                    .foregroundStyle(Color.theme.green)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            if let onSell = onSellTapped {
                Button {
                    onSell()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "minus")
                            .font(.system(size: 9, weight: .bold))
                        Text("Sell")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.theme.red.opacity(0.15))
                    .foregroundStyle(Color.theme.red)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Profit Badge
    private var totalProfitBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: isProfitable ? "arrow.up.right" : "arrow.down.right")
            Text(isProfitable ? "+" : "")
            + Text(coin.profitLoss.asCurrencyWith2Decimals())
            + Text(" (\(coin.profitLossPercentage.asPercentString()))")
        }
        .font(.caption)
        .fontWeight(.bold)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .foregroundStyle(isProfitable ? Color.theme.green : Color.theme.red)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (isProfitable ? Color.theme.green : Color.theme.red).opacity(0.12)
        )
        .clipShape(Capsule())
    }
    
    // MARK: - Financial Metrics Grid
    private var financialMetricsGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                // Invested Amount Box
                metricBox(
                    title: "Invested",
                    value: coin.costBasis.asCurrencyWith2Decimals(),
                    subtitle: nil,
                    systemImage: "arrow.down.circle.fill",
                    tintColor: Color.blue
                )
                
                // Current Value Box
                metricBox(
                    title: "Current Value",
                    value: coin.currentHoldingsValue.asCurrencyWith2Decimals(),
                    subtitle: "\((coin.currentHoldings ?? 0).asNumberString()) \(coin.symbol.uppercased())",
                    systemImage: "banknote.fill",
                    tintColor: Color.purple
                )
                
                // Total Profit & Loss Box
                metricBox(
                    title: "Total P&L",
                    value: (isProfitable ? "+" : "") + coin.profitLoss.asCurrencyWith2Decimals(),
                    subtitle: (isProfitable ? "+" : "") + coin.profitLossPercentage.asPercentString(),
                    systemImage: isProfitable ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                    tintColor: isProfitable ? Color.theme.green : Color.theme.red
                )
            }
            
            // Secondary Performance / Context Banner
            secondaryPerformanceBanner
        }
    }
    
    private var secondaryPerformanceBanner: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 10))
                Text("Avg Buy Price:")
                    .font(.caption2)
                    .fontWeight(.medium)
                Text((coin.averageBuyPrice ?? coin.currentPrice).asFormattedPrice())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
            .foregroundStyle(Color.theme.secondaryText)
            
            Spacer()
            
            HStack(spacing: 3) {
                Image(systemName: is24HProfitable ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 9, weight: .bold))
                Text("24h: \(coin.priceChangePercentage24H?.asPercentString() ?? "0.00%")")
            }
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(is24HProfitable ? Color.theme.green : Color.theme.red)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.theme.secondaryText.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func metricBox(
        title: String,
        value: String,
        subtitle: String?,
        systemImage: String,
        tintColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 11))
                    .foregroundStyle(tintColor)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
            }
            
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(title == "Total P&L" ? tintColor : Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(title == "Total P&L" ? tintColor : Color.theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.secondaryText.opacity(0.06))
        )
    }
}

// MARK: - Previews with Mock Data
#Preview("Coin Holding Card - Profitable (Dark)") {
    let fakeHolding = DeveloperPreview.instance.coin.updateHoldings(
        amount: 1.5,
        investedAmount: 78000,
        averageBuyPrice: 52000
    )
    
    return ZStack {
        Color.theme.background.ignoresSafeArea()
        CoinHoldingCard(
            coin: fakeHolding,
            onBuyTapped: {},
            onSellTapped: {}
        )
        .padding()
        .environmentObject(DeveloperPreview.instance.homeVM)
    }
    .preferredColorScheme(.dark)
}

#Preview("Coin Holding Card - Light Mode") {
    let fakeHolding = DeveloperPreview.instance.ethCoin.updateHoldings(
        amount: 8.0,
        investedAmount: 24000,
        averageBuyPrice: 3000
    )
    
    return ZStack {
        Color.theme.background.ignoresSafeArea()
        CoinHoldingCard(
            coin: fakeHolding,
            onBuyTapped: {},
            onSellTapped: {}
        )
        .padding()
        .environmentObject(DeveloperPreview.instance.homeVM)
    }
    .preferredColorScheme(.light)
}
