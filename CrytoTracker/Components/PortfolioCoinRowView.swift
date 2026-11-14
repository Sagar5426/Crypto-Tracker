//
//  PortfolioCoinRowView.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

/// A dedicated row view for displaying a coin holding inside the user's Portfolio.
struct PortfolioCoinRowView: View {
    let coin: CoinModel
    
    // MARK: - Computed Properties
    
    private var quantityBoughtText: String {
        "\((coin.currentHoldings ?? 0).asNumberString()) \(coin.symbol.uppercased())"
    }
    
    private var avgBuyPriceFormatted: String {
        let avg = coin.averageBuyPrice ?? (
            (coin.currentHoldings ?? 0) > 0 ? (coin.costBasis / (coin.currentHoldings ?? 1)) : coin.currentPrice
        )
        return avg.asFormattedPrice()
    }
    
    private var investedAmountFormatted: String {
        coin.costBasis.asCurrencyWith2Decimals()
    }
    
    private var presentValueFormatted: String {
        coin.currentHoldingsValue.asCurrencyWith2Decimals()
    }
    
    private var isProfitable: Bool {
        coin.profitLoss >= 0
    }
    
    private var profitLossPercentageFormatted: String {
        let pct = coin.profitLossPercentage
        let prefix = isProfitable ? "+" : ""
        return "\(prefix)\(pct.asPercentString())"
    }
    
    private var is24HProfitable: Bool {
        (coin.priceChangePercentage24H ?? 0) >= 0
    }
    
    private var price24HChangeFormatted: String {
        let pct = coin.priceChangePercentage24H ?? 0
        let prefix = is24HProfitable ? "+" : ""
        return "\(prefix)\(pct.asPercentString())"
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left Column
            VStack(alignment: .leading, spacing: 6) {
                // 1. HStack { Quantity bought, Avg buy price }
                HStack(alignment: .center, spacing: 5) {
                    Text("Qty. \(quantityBoughtText)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text("•")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.4))
                    
                    Text("Avg. \(avgBuyPriceFormatted)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.theme.secondaryText)
                }
                .lineLimit(1)
                
                // 2. HStack { image of coin and name }
                HStack(spacing: 8) {
                    CoinImageView(coin: coin)
                        .frame(width: 26, height: 26)
                        .clipShape(Circle())
                    
                    Text(coin.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                        .lineLimit(1)
                }
                
                // 3. Invested (Amount)
                HStack(spacing: 4) {
                    Text("Invested")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text(investedAmountFormatted)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                }
                .lineLimit(1)
            }
            
            Spacer(minLength: 8)
            
            // Right Column
            VStack(alignment: .trailing, spacing: 6) {
                // 1. Overall change in percentage of profit or loss
                HStack(spacing: 3) {
                    Image(systemName: isProfitable ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 8, weight: .bold))
                    
                    Text(profitLossPercentageFormatted)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(isProfitable ? Color.theme.green : Color.theme.red)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(
                    Capsule()
                        .fill((isProfitable ? Color.theme.green : Color.theme.red).opacity(0.12))
                )
                
                // 2. Present value in dollar
                Text(presentValueFormatted)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // 3. HStack { Avg price, then (24 hr change in percent) }
                HStack(spacing: 4) {
                    Text(coin.currentPrice.asFormattedPrice())
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    HStack(spacing: 0) {
                        Text("(\(price24HChangeFormatted))")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }
                    .foregroundStyle(is24HProfitable ? Color.theme.green : Color.theme.red)
                }
                .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Previews
#Preview("Portfolio Row - Dark") {
    VStack(spacing: 12) {
        PortfolioCoinRowView(coin: DeveloperPreview.instance.coin)
        
        Divider()
            .background(Color.theme.secondaryText.opacity(0.15))
        
        PortfolioCoinRowView(coin: DeveloperPreview.instance.adaCoin)
    }
    .padding()
    .background(Color.theme.background)
    .preferredColorScheme(.dark)
}

#Preview("Portfolio Row - Light") {
    VStack(spacing: 12) {
        PortfolioCoinRowView(coin: DeveloperPreview.instance.coin)
        
        Divider()
            .background(Color.theme.secondaryText.opacity(0.15))
        
        PortfolioCoinRowView(coin: DeveloperPreview.instance.adaCoin)
    }
    .padding()
    .background(Color.theme.background)
    .preferredColorScheme(.light)
}
