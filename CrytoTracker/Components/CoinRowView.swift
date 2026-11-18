//
//  CoinRowView.swift
//  CoinPilot
//
//  Created by Sagar Jangra on 02/08/2025.
//

import SwiftUI

struct CoinRowView: View {
    let coin: CoinModel
    var isFavorite: Bool = false
    var onFavoriteTapped: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 10) {
            leftColumn
            
            Spacer(minLength: 6)
            
            miniSparkline
            
            rightColumn
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Mini Sparkline View
struct MiniSparklineView: View {
    let data: [Double]
    let isPositive: Bool
    
    private var strokeColor: Color {
        isPositive ? Color.theme.green : Color.theme.red
    }
    
    var body: some View {
        GeometryReader { geometry in
            if data.count > 1 {
                let maxY = data.max() ?? 1
                let minY = data.min() ?? 0
                let yRange = max(maxY - minY, 0.000001)
                let verticalInset: CGFloat = 2
                let drawableHeight = max(geometry.size.height - (verticalInset * 2), 1)
                let stepX = geometry.size.width / CGFloat(data.count - 1)
                
                let linePath = Path { path in
                    for index in data.indices {
                        let x = CGFloat(index) * stepX
                        let normalizedY = CGFloat((data[index] - minY) / yRange)
                        let y = verticalInset + (1.0 - normalizedY) * drawableHeight
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                
                ZStack {
                    // Subtle gradient fill under the sparkline
                    linePath
                        .applying(CGAffineTransform.identity)
                        .fill(Color.clear)
                        .overlay(
                             Path { path in
                                path.addPath(linePath)
                                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                                path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                                path.closeSubpath()
                            }
                            .fill(
                                LinearGradient(
                                    colors: [
                                        strokeColor.opacity(0.22),
                                        strokeColor.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        )
                    
                    // Main sparkline stroke
                    linePath
                        .stroke(
                            strokeColor,
                            style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
                        )
                }
            }
        }
    }
}

// MARK: - Subviews
extension CoinRowView {
    
    // MARK: - Left Column (Rank/Star, Icon, Symbol & Name)
    private var leftColumn: some View {
        HStack(spacing: 10) {
            rankAndFavoriteView
            
            ZStack {
                Circle()
                    .fill(Color.theme.secondaryText.opacity(0.06))
                    .frame(width: 36, height: 36)
                
                CoinImageView(coin: coin)
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(coin.symbol.uppercased())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                        .lineLimit(1)
                    
                    if isFavorite && onFavoriteTapped == nil {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.yellow)
                    }
                }
                
                Text(coin.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .layoutPriority(1)
        }
    }
    
    @ViewBuilder
    private var rankAndFavoriteView: some View {
        if let onFavoriteTapped = onFavoriteTapped {
            Button(action: onFavoriteTapped) {
                VStack(spacing: 3) {
                    Text("\(coin.rank)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isFavorite ? Color.yellow : Color.theme.secondaryText.opacity(0.35))
                }
                .frame(width: 24, height: 34)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            Text("\(coin.rank)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 24, alignment: .center)
        }
    }
    
    // MARK: - Center Column (7D Sparkline or Holdings Value)
    private var miniSparkline: some View {
        MiniSparklineView(
            data: coin.sparklineIn7D?.price ?? [],
            isPositive: (coin.priceChangePercentage24H ?? 0) >= 0
        )
        .frame(width: 52, height: 26)
        .padding(.horizontal, 4)
    }
    
    
    
    // MARK: - Right Column (Live Price & Change / P&L Badge)
    private var rightColumn: some View {
        let isPositive =  ((coin.priceChangePercentage24H ?? 0) >= 0)
        
        let rawPercent =  (coin.priceChangePercentage24H?.asPercentString() ?? "0.00%")
        
        let formattedPercent = (isPositive && !rawPercent.hasPrefix("+"))
            ? "+\(rawPercent)"
            : rawPercent
        
        let badgeColor = isPositive ? Color.theme.green : Color.theme.red
        
        return VStack(alignment: .trailing, spacing: 4) {
            Text(coin.currentPrice.asFormattedPrice())
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            HStack(spacing: 2.5) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 8, weight: .bold))
                
                Text(formattedPercent)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .foregroundStyle(badgeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(
                Capsule()
                    .fill(badgeColor.opacity(0.12))
            )
        }
        .frame(width: 88, alignment: .trailing)
    }
}

// MARK: - Previews
#Preview("Market & Portfolio Rows - Dark") {
    VStack(spacing: 12) {
        CoinRowView(
            coin: DeveloperPreview.instance.coin,
            isFavorite: true,
            onFavoriteTapped: {}
        )
        
        Divider()
            .background(Color.theme.secondaryText.opacity(0.15))
        
        CoinRowView(
            coin: DeveloperPreview.instance.coin
        )
    }
    .padding(16)
    .background(Color.theme.background)
    .preferredColorScheme(.dark)
}

#Preview("Market & Portfolio Rows - Light") {
    VStack(spacing: 12) {
        CoinRowView(
            coin: DeveloperPreview.instance.coin,
            isFavorite: false,
            onFavoriteTapped: {}
        )
        
        Divider()
            .background(Color.theme.secondaryText.opacity(0.15))
        
        CoinRowView(
            coin: DeveloperPreview.instance.coin
        )
    }
    .padding(16)
    .background(Color.theme.background)
    .preferredColorScheme(.light)
}
