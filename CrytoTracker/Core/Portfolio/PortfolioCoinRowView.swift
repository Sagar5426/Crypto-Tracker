//
//  PortfolioCoinRowView.swift
//  CoinPilot
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

/// A dedicated row view for displaying a coin holding inside the user's Portfolio.
struct PortfolioCoinRowView: View {
    let coin: CoinModel
    
    // MARK: - Computed Properties
    
    private var quantityBoughtText: String {
        (coin.currentHoldings ?? 0).asCompactQuantity()
    }
    
    private var avgBuyPriceFormatted: String {
        let avg = coin.averageBuyPrice ?? (
            (coin.currentHoldings ?? 0) > 0 ? (coin.costBasis / (coin.currentHoldings ?? 1)) : coin.currentPrice
        )
        return avg.asCompactCurrencyPrice()
    }
    
    private var investedAmountFormatted: String {
        coin.costBasis.asCompactCurrency(fallback: coin.costBasis.asCurrencyWith2Decimals())
    }
    
    private var netProfitLossFormatted: String {
        let pl = coin.profitLoss
        let prefix = isProfitable ? "+" : ""
        let formatted = pl.asCompactCurrency(fallback: pl.asCurrencyWith2Decimals())
            .replacingOccurrences(of: "$", with: "")
        return "\(prefix)\(formatted)"
    }
    
    private var isProfitable: Bool {
        coin.profitLoss >= 0
    }
    
    private var profitLossPercentageFormatted: String {
        let pct = coin.profitLossPercentage
        let raw = pct.asPercentString()
        if isProfitable && !raw.hasPrefix("+") {
            return "+\(raw)"
        }
        return raw
    }
    
    private var is24HProfitable: Bool {
        (coin.priceChangePercentage24H ?? 0) >= 0
    }
    
    private var price24HChangeFormatted: String {
        let pct = coin.priceChangePercentage24H ?? 0
        let raw = pct.asPercentString()
        if is24HProfitable && !raw.hasPrefix("+") {
            return "+\(raw)"
        }
        return raw
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Left Column
            VStack(alignment: .leading, spacing: 5) {
                // 1. Compact Qty & Avg Buy Price Badge
                qtyAndAvgHeader
                
                // 2. Coin Icon & Name
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.secondaryText.opacity(0.08))
                            .frame(width: 28, height: 28)
                        
                        CoinImageView(coin: coin)
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                    }
                    
                    Text(coin.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                // 3. Invested Amount
                HStack(spacing: 4) {
                    Text("Invested")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
                    
                    Text(investedAmountFormatted)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.theme.accent)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            
            Spacer(minLength: 6)
            
            // Right Column
            VStack(alignment: .trailing, spacing: 5) {
                // 1. Overall P&L Percentage Pill
                HStack(spacing: 3) {
                    
                    Text(profitLossPercentageFormatted)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(isProfitable ? Color.theme.green : Color.theme.red)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(
                    Capsule()
                        .fill((isProfitable ? Color.theme.green : Color.theme.red).opacity(0.12))
                )
                
                // 2. Actual Net Profit or Loss
                Text(netProfitLossFormatted)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isProfitable ? Color.theme.green : Color.theme.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                // 3. Live Price & 24h Change
                HStack(spacing: 4) {
                    Text(coin.currentPrice.asCompactCurrencyPrice())
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text("(\(price24HChangeFormatted))")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(is24HProfitable ? Color.theme.green : Color.theme.red)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }
    
    // MARK: - Subviews
    
    private var qtyAndAvgHeader: some View {
        HStack(alignment: .center, spacing: 5) {
            HStack(spacing: 2.5) {
                Text("Qty")
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.theme.secondaryText.opacity(0.7))
                
                Text(quantityBoughtText)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            // True geometric circle stays centered vertically in the HStack
            Circle()
                .fill(Color.theme.secondaryText.opacity(0.4))
                .frame(width: 3.5, height: 3.5)
            
            HStack(spacing: 2.5) {
                Text("Avg")
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.theme.secondaryText.opacity(0.7))
                
                Text(avgBuyPriceFormatted)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.theme.secondaryText)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color.theme.secondaryText.opacity(0.06))
        )
    }
}

// MARK: - Compact K / M / B / T Formatting Helpers
private extension Double {
    
    /// Extracts the active currency symbol (e.g. "$") from your existing formatter.
    var currencySymbolPrefix: String {
        let sample = (0.0).asCurrencyWith2Decimals()
        return sample.first(where: { !$0.isNumber && $0 != "." && $0 != "," && $0 != "-" && $0 != " " }).map(String.init) ?? "$"
    }
    
    /// Formats token quantities with K, M, B, T abbreviations when >= 1,000.
    func asCompactQuantity() -> String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        
        switch absValue {
        case 1_000_000_000_000...:
            return "\(sign)\((absValue / 1_000_000_000_000).trimmedAbbreviatedString())T"
        case 1_000_000_000...:
            return "\(sign)\((absValue / 1_000_000_000).trimmedAbbreviatedString())B"
        case 1_000_000...:
            return "\(sign)\((absValue / 1_000_000).trimmedAbbreviatedString())M"
        case 1_000...:
            return "\(sign)\((absValue / 1_000).trimmedAbbreviatedString())K"
        case 1...:
            return self.asNumberString()
        case 0:
            return "0"
        default:
            // Preserve up to 4 significant decimals for fractional holdings (e.g. 0.0425 BTC)
            return String(format: "%.4f", self).replacingOccurrences(
                of: #"(\.\d*?[1-9])0+$|\.0+$"#,
                with: "$1",
                options: .regularExpression
            )
        }
    }
    
    /// Formats coin unit prices using K, M, B, T for >= 1,000, or falls back to `asFormattedPrice()`.
    func asCompactCurrencyPrice() -> String {
        let absValue = abs(self)
        if absValue >= 1_000 {
            return asCompactCurrency(fallback: self.asFormattedPrice())
        }
        return self.asFormattedPrice()
    }
    
    /// Formats dollar amounts with K, M, B, T when >= 10,000, otherwise uses standard currency string.
    func asCompactCurrency(fallback: String) -> String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        let symbol = currencySymbolPrefix
        
        switch absValue {
        case 1_000_000_000_000...:
            return "\(sign)\(symbol)\((absValue / 1_000_000_000_000).trimmedAbbreviatedString())T"
        case 1_000_000_000...:
            return "\(sign)\(symbol)\((absValue / 1_000_000_000).trimmedAbbreviatedString())B"
        case 1_000_000...:
            return "\(sign)\(symbol)\((absValue / 1_000_000).trimmedAbbreviatedString())M"
        case 1_000...:
            return "\(sign)\(symbol)\((absValue / 1_000).trimmedAbbreviatedString())K"
        default:
            return fallback
        }
    }
    
    /// Formats abbreviated numbers to at most 2 decimal places and strips trailing ".00" or "0".
    func trimmedAbbreviatedString() -> String {
        let formatted = self >= 100
            ? String(format: "%.1f", self)
            : String(format: "%.2f", self)
        
        return formatted.replacingOccurrences(
            of: #"(\.\d*?[1-9])0+$|\.0+$"#,
            with: "$1",
            options: .regularExpression
        )
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
