//
//  CoinRowView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 02/08/2025.
//

import SwiftUI

struct CoinRowView: View {
    let coin: CoinModel
    let showHoldingColumn: Bool
    var isFavorite: Bool = false
    var onFavoriteTapped: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 6) {
            leftColumn
            
            Spacer(minLength: 4)
            
            if showHoldingColumn {
                centerColumn
            } else {
                miniSparkline
            }
            
            rightColumn
        }
        .font(.subheadline)
        .padding(.vertical, 2)
    }
}

// MARK: - Mini Sparkline View
struct MiniSparklineView: View {
    let data: [Double]
    let isPositive: Bool
    
    var body: some View {
        GeometryReader { geometry in
            if data.count > 1 {
                let maxY = data.max() ?? 1
                let minY = data.min() ?? 0
                let yRange = max(maxY - minY, 0.000001)
                let stepX = geometry.size.width / CGFloat(data.count - 1)
                
                Path { path in
                    for index in data.indices {
                        let x = CGFloat(index) * stepX
                        let y = (1.0 - CGFloat((data[index] - minY) / yRange)) * geometry.size.height
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    isPositive ? Color.theme.green : Color.theme.red,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}

// MARK: - Subviews
extension CoinRowView {
    
    private var leftColumn: some View {
        HStack(spacing: 8) {
            if let onFavoriteTapped = onFavoriteTapped {
                Button {
                    onFavoriteTapped()
                } label: {
                    VStack(spacing: 2) {
                        Text("\(coin.rank)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.theme.secondaryText)
                        
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.system(size: 9))
                            .foregroundStyle(isFavorite ? Color.yellow : Color.theme.secondaryText.opacity(0.35))
                    }
                    .frame(width: 20)
                }
                .buttonStyle(.plain)
            } else {
                Text("\(coin.rank)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.theme.secondaryText)
                    .frame(width: 20, alignment: .leading)
            }
            
            CoinImageView(coin: coin)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(coin.symbol.uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.theme.accent)
                    .lineLimit(1)
                
                Text(coin.name)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.7)
            }
            .layoutPriority(1)
        }
    }
    
    private var miniSparkline: some View {
        MiniSparklineView(
            data: coin.sparklineIn7D?.price ?? [],
            isPositive: (coin.priceChangePercentage24H ?? 0) >= 0
        )
        .frame(width: 38, height: 22)
        .padding(.horizontal, 2)
    }
    
    private var centerColumn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(coin.currentHoldingsValue.asCurrencyWith2Decimals())
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text("\((coin.currentHoldings ?? 0).asNumberString()) \(coin.symbol.uppercased())")
                .font(.caption2)
                .foregroundStyle(Color.theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private var rightColumn: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(coin.currentPrice.asFormattedPrice())
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            HStack(spacing: 2) {
                Image(systemName: (coin.priceChangePercentage24H ?? 0) >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 7, weight: .bold))
                
                Text(coin.priceChangePercentage24H?.asPercentString() ?? "0.00%")
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundStyle((coin.priceChangePercentage24H ?? 0) >= 0 ? Color.theme.green : Color.theme.red)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                ((coin.priceChangePercentage24H ?? 0) >= 0 ? Color.theme.green : Color.theme.red).opacity(0.12)
            )
            .clipShape(Capsule())
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct CoinRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CoinRowView(coin: DeveloperPreview.instance.coin, showHoldingColumn: false, isFavorite: true)
                .previewDisplayName("Live Price Row")
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)

            CoinRowView(coin: DeveloperPreview.instance.coin, showHoldingColumn: true)
                .previewDisplayName("Portfolio Row")
                .preferredColorScheme(.light)
                .previewLayout(.sizeThatFits)
        }
    }
}
