//
//  CoinInvestmentCard.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

/// A dedicated card displaying the user's personal holding position for a specific coin in DetailView.
struct CoinInvestmentCard: View {
    let coin: CoinModel
    var onViewBreakdownTapped: (() -> Void)? = nil
    
    private var isProfitable: Bool {
        coin.profitLoss >= 0
    }
    
    private var is24HProfitable: Bool {
        (coin.priceChangePercentage24H ?? 0) >= 0
    }
    
    private var daysProfitLoss: Double {
        (coin.currentHoldings ?? 0) * (coin.priceChange24H ?? 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            primaryMetricsRow
            secondaryMetricsRow
            viewBreakdownButton
        }
        .padding(14)
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
extension CoinInvestmentCard {
    
    // MARK: - Row 1: Invested, Current, P&L
    private var primaryMetricsRow: some View {
        HStack(spacing: 10) {
            metricBox(
                title: "Invested",
                value: coin.costBasis.asCurrencyWith2Decimals(),
                systemImage: "arrow.down.circle.fill",
                tintColor: Color.blue
            )
            
            metricBox(
                title: "Current",
                value: coin.currentHoldingsValue.asCurrencyWith2Decimals(),
                systemImage: "banknote.fill",
                tintColor: Color.purple
            )
            
            metricBox(
                title: "Total P&L",
                value: (isProfitable ? "+" : "") + coin.profitLoss.asCurrencyWith2Decimals(),
                systemImage: isProfitable ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                tintColor: isProfitable ? Color.theme.green : Color.theme.red,
                colorizeValue: true
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Row 2: Qty, Avg Price, Day's P&L
    private var secondaryMetricsRow: some View {
        VStack(spacing: 10) {
            
            metricRow(
                title: "Qty",
                value: "\((coin.currentHoldings ?? 0).asNumberString()) \(coin.symbol.uppercased())",
                systemImage: "number.circle.fill",
                tintColor: Color.orange
            )
            
            
            metricRow(
                title: "Avg Price",
                value: (coin.averageBuyPrice ?? coin.currentPrice).asFormattedPrice(),
                systemImage: "tag.fill",
                tintColor: Color.cyan
            )
            
            metricRow(
                title: "Day's P&L",
                value: (is24HProfitable ? "+" : "") + daysProfitLoss.asCurrencyWith2Decimals(),
                systemImage: is24HProfitable ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                tintColor: is24HProfitable ? Color.theme.green : Color.theme.red,
                colorizeValue: true
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - View Breakdown Button
    private var viewBreakdownButton: some View {
        Button {
            onViewBreakdownTapped?()
        } label: {
            HStack(spacing: 6) {
                Text("View Breakdown")
                    .font(.caption)
                    .fontWeight(.bold)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.theme.accent.opacity(0.10))
            .foregroundStyle(Color.theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Reusable Metric Box
    private func metricRow(
    title: String,
    value: String,
    systemImage: String,
    tintColor: Color,
    colorizeValue: Bool = false
    ) -> some View {
        HStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 11))
                    .foregroundStyle(tintColor)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(colorizeValue ? tintColor : Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.secondaryText.opacity(0.06))
        )
    }
    // MARK: - Reusable Metric Box
    private func metricBox(
        title: String,
        value: String,
        systemImage: String,
        tintColor: Color,
        colorizeValue: Bool = false
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
                .foregroundStyle(colorizeValue ? tintColor : Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
    ZStack {
        Color.theme.screenBackground.ignoresSafeArea()
        CoinInvestmentCard(
            coin: DeveloperPreview.instance.coin,
            onViewBreakdownTapped: {}
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Coin Holding Card - Loss (Dark)") {
    ZStack {
        Color.theme.screenBackground.ignoresSafeArea()
        CoinInvestmentCard(
            coin: DeveloperPreview.instance.adaCoin,
            onViewBreakdownTapped: {}
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Coin Holding Card - Light Mode") {
    ZStack {
        Color.theme.screenBackground.ignoresSafeArea()
        CoinInvestmentCard(
            coin: DeveloperPreview.instance.coin,
            onViewBreakdownTapped: {}
        )
        .padding()
    }
    .preferredColorScheme(.light)
}
