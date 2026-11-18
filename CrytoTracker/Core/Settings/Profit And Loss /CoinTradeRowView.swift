//
//  CoinTradeRowView.swift
//  CoinPilot
//

import SwiftUI

struct CoinTradeRowView: View {
    let coinPnL: CoinPnLSummary
    
    private var isNetProfit: Bool {
        coinPnL.isNetProfitable
    }
    
    private var netColor: Color {
        isNetProfit ? Color.theme.green : Color.theme.red
    }
    
    private var isRealizedProfit: Bool {
        coinPnL.isRealizedProfitable
    }
    
    private var realizedColor: Color {
        isRealizedProfit ? Color.theme.green : Color.theme.red
    }
    
    private var isUnrealizedProfit: Bool {
        coinPnL.isUnrealizedProfitable
    }
    
    private var unrealizedColor: Color {
        coinPnL.hasOpenPosition ? (isUnrealizedProfit ? Color.theme.green : Color.theme.red) : Color.theme.secondaryText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1. Top Coin Header
            headerSection
            
            // 2. Realised P&L Section (Only shown when realised data is available)
            if coinPnL.hasRealizedActivity {
                themedDivider
                realizedSection
            }
            
            // 3. Unrealised P&L Section (Only shown when an open position exists)
            if coinPnL.hasOpenPosition {
                themedDivider
                unrealizedSection
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Main Sections
    
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 10) {
            coinIconView
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(coinPnL.coinName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                        .lineLimit(1)
                    
                    Text(coinPnL.coinSymbol)
                        .font(.system(size: 9.5, weight: .heavy))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.theme.secondaryText.opacity(0.1))
                        .foregroundStyle(Color.theme.accent)
                        .clipShape(Capsule())
                }
                
                Text(coinPnL.hasOpenPosition ? "\(formattedQuantity(coinPnL.currentHoldings)) \(coinPnL.coinSymbol) Open" : "Position Closed")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(coinPnL.hasOpenPosition ? Color.theme.accent.opacity(0.8) : Color.theme.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(isNetProfit ? "+" : "")\(coinPnL.netPnL.asCurrencyWith2Decimals())")
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(netColor)
                
                Text("\(isNetProfit ? "+" : "")\(coinPnL.netPercentage.asPercentString()) Net")
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(netColor.opacity(0.85))
                    .monospacedDigit()
            }
        }
    }
    
    private var realizedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            pnlSectionHeader(
                title: "Realised:",
                dotColor: realizedColor,
                isActive: true,
                quantity: coinPnL.totalRealizedQty,
                isProfit: isRealizedProfit,
                pnlAmount: coinPnL.totalRealizedPnL,
                pnlPercentage: coinPnL.totalRealizedPercentage,
                inactiveText: "$0.00 (No sales)"
            )
            
            VStack(spacing: 8) {
                metricPairRow(
                    leftTitle: "Buy avg",
                    leftValue: coinPnL.realizedBuyAvgPrice.asFormattedPrice(),
                    rightTitle: "Buy value",
                    rightValue: coinPnL.totalRealizedCostBasis.asCurrencyWith2Decimals()
                )
                
                themedDivider
                
                metricPairRow(
                    leftTitle: "Sell avg",
                    leftValue: coinPnL.sellAvgPrice.asFormattedPrice(),
                    rightTitle: "Sell value",
                    rightValue: coinPnL.totalRealizedProceeds.asCurrencyWith2Decimals()
                )
            }
            .padding(10)
            .background(Color.theme.secondaryText.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
    
    private var unrealizedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            pnlSectionHeader(
                title: "Unrealised:",
                dotColor: unrealizedColor,
                isActive: coinPnL.hasOpenPosition,
                quantity: coinPnL.currentHoldings,
                isProfit: isUnrealizedProfit,
                pnlAmount: coinPnL.unrealizedPnL,
                pnlPercentage: coinPnL.unrealizedPercentage,
                inactiveText: "$0.00 (Position Closed)"
            )
            
            if coinPnL.hasOpenPosition {
                metricPairRow(
                    leftTitle: "Buy avg",
                    leftValue: coinPnL.buyAvgPrice.asFormattedPrice(),
                    rightTitle: "Buy value",
                    rightValue: coinPnL.unrealizedCostBasis.asCurrencyWith2Decimals()
                )
                .padding(10)
                .background(Color.theme.secondaryText.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
    
    // MARK: - Reusable View Builders
    
    private var coinIconView: some View {
        ZStack {
            Circle()
                .fill(Color.theme.secondaryText.opacity(0.08))
                .frame(width: 38, height: 38)
            
            if let coin = coinPnL.coinModel {
                CoinImageView(coin: coin)
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
            } else {
                Text(coinPnL.coinSymbol.prefix(3))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.theme.accent)
            }
        }
    }
    
    private var themedDivider: some View {
        Divider()
            .background(Color.theme.secondaryText.opacity(0.08))
    }
    
    @ViewBuilder
    private func pnlSectionHeader(
        title: String,
        dotColor: Color,
        isActive: Bool,
        quantity: Double,
        isProfit: Bool,
        pnlAmount: Double,
        pnlPercentage: Double,
        inactiveText: String
    ) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 6, height: 6)
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                if isActive {
                    Text("(Qty: \(formattedQuantity(quantity)))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.7))
                        .padding(.leading, 11)
                }
            }
            
            Spacer()
            
            if isActive {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(isProfit ? "+" : "")\(pnlAmount.asCurrencyWith2Decimals())")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    Text("\(isProfit ? "+" : "")\(pnlPercentage.asPercentString())")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(dotColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
            } else {
                Text(inactiveText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.theme.secondaryText.opacity(0.7))
            }
        }
    }
    
    @ViewBuilder
    private func metricPairRow(
        leftTitle: String,
        leftValue: String,
        rightTitle: String,
        rightValue: String
    ) -> some View {
        HStack {
            metricItem(title: leftTitle, value: leftValue, alignment: .leading)
            Spacer()
            metricItem(title: rightTitle, value: rightValue, alignment: .trailing)
        }
    }
    
    @ViewBuilder
    private func metricItem(
        title: String,
        value: String,
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.theme.secondaryText)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.theme.accent)
        }
    }
    
    // MARK: - Helpers
    
    private func formattedQuantity(_ amount: Double) -> String {
        let absAmount = abs(amount)
        if absAmount >= 1.0 {
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

typealias CoinTradeRow = CoinTradeRowView

// MARK: - Previews & Sample Data
#if DEBUG
extension CoinPnLSummary {
    static let previewProfit = CoinPnLSummary(
        coinID: "bitcoin",
        coinName: "Bitcoin",
        coinSymbol: "BTC",
        coinModel: DeveloperPreview.instance.coin,
        totalRealizedPnL: 1250.0,
        totalRealizedPercentage: 15.62,
        totalRealizedCostBasis: 8000.0,
        totalRealizedProceeds: 9250.0,
        totalRealizedQty: 0.15,
        realizedBuyAvgPrice: 53333.33,
        sellAvgPrice: 61666.67,
        closedTradesCount: 3,
        currentHoldings: 1.5,
        currentPrice: 61408.0,
        unrealizedCostBasis: 78000.0,
        currentHoldingsValue: 92112.0,
        unrealizedPnL: 14112.0,
        unrealizedPercentage: 18.09,
        buyAvgPrice: 52000.0,
        hasOpenPosition: true
    )
    
    static let previewLoss = CoinPnLSummary(
        coinID: "ethereum",
        coinName: "Ethereum",
        coinSymbol: "ETH",
        coinModel: DeveloperPreview.instance.ethCoin,
        totalRealizedPnL: -450.0,
        totalRealizedPercentage: -7.5,
        totalRealizedCostBasis: 6000.0,
        totalRealizedProceeds: 5550.0,
        totalRealizedQty: 1.8,
        realizedBuyAvgPrice: 3333.33,
        sellAvgPrice: 3083.33,
        closedTradesCount: 2,
        currentHoldings: 2.5,
        currentPrice: 3450.0,
        unrealizedCostBasis: 9000.0,
        currentHoldingsValue: 8625.0,
        unrealizedPnL: -375.0,
        unrealizedPercentage: -4.17,
        buyAvgPrice: 3600.0,
        hasOpenPosition: true
    )
    
    static let previewClosed = CoinPnLSummary(
        coinID: "solana",
        coinName: "Solana",
        coinSymbol: "SOL",
        coinModel: DeveloperPreview.instance.solCoin,
        totalRealizedPnL: 820.0,
        totalRealizedPercentage: 22.16,
        totalRealizedCostBasis: 3700.0,
        totalRealizedProceeds: 4520.0,
        totalRealizedQty: 25.0,
        realizedBuyAvgPrice: 148.0,
        sellAvgPrice: 180.8,
        closedTradesCount: 4,
        currentHoldings: 0.0,
        currentPrice: 175.0,
        unrealizedCostBasis: 0.0,
        currentHoldingsValue: 0.0,
        unrealizedPnL: 0.0,
        unrealizedPercentage: 0.0,
        buyAvgPrice: 0.0,
        hasOpenPosition: false
    )
    
    static let previewOpenOnly = CoinPnLSummary(
        coinID: "cardano",
        coinName: "Cardano",
        coinSymbol: "ADA",
        coinModel: DeveloperPreview.instance.adaCoin,
        totalRealizedPnL: 0.0,
        totalRealizedPercentage: 0.0,
        totalRealizedCostBasis: 0.0,
        totalRealizedProceeds: 0.0,
        totalRealizedQty: 0.0,
        realizedBuyAvgPrice: 0.0,
        sellAvgPrice: 0.0,
        closedTradesCount: 0,
        currentHoldings: 5000.0,
        currentPrice: 0.72,
        unrealizedCostBasis: 4500.0,
        currentHoldingsValue: 3600.0,
        unrealizedPnL: -900.0,
        unrealizedPercentage: -20.0,
        buyAvgPrice: 0.90,
        hasOpenPosition: true
    )
}

struct CoinTradeRowPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CoinTradeRowView(coinPnL: .previewProfit)
                CoinTradeRowView(coinPnL: .previewLoss)
                CoinTradeRowView(coinPnL: .previewClosed)
                CoinTradeRowView(coinPnL: .previewOpenOnly)
            }
            .padding()
        }
        .background(Color.theme.background)
    }
}

#Preview("Coin Trade Row - Dark") {
    CoinTradeRowPreview()
        .preferredColorScheme(.dark)
}

#Preview("Coin Trade Row - Light") {
    CoinTradeRowPreview()
        .preferredColorScheme(.light)
}
#endif
