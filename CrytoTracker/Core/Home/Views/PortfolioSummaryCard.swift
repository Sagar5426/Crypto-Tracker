//
//  PortfolioSummaryCard.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

struct PortfolioSummaryCard: View {
    @EnvironmentObject private var vm: HomeViewModel
    var onAddTapped: () -> Void
    
    // Palette of vibrant colors for the allocation bar
    private let allocationColors: [Color] = [
        Color.orange,
        Color.indigo,
        Color.purple,
        Color.teal,
        Color.mint,
        Color.cyan,
        Color.blue,
        Color.pink,
        Color.yellow
    ]
    
    private var isProfitable: Bool {
        vm.portfolioProfit24H >= 0
    }
    
    private var topHolding: CoinModel? {
        vm.portfolioCoins.max(by: { $0.currentHoldingsValue < $1.currentHoldingsValue })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection
            
            Divider()
                .background(Color.theme.secondaryText.opacity(0.15))
            
            if !vm.portfolioCoins.isEmpty {
                allocationSection
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.08), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.secondaryText.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - Subviews
extension PortfolioSummaryCard {
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("PORTFOLIO VALUE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                Button {
                    onAddTapped()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Manage")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.theme.accent.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            Text(vm.portfolioTotalValue.asCurrencyWith2Decimals())
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            if !vm.portfolioCoins.isEmpty {
                HStack(spacing: 8) {
                    profitBadge
                    
                    if let top = topHolding, vm.portfolioTotalValue > 0 {
                        let share = vm.portfolioShare(for: top)
                        Text("•")
                            .foregroundStyle(Color.theme.secondaryText.opacity(0.5))
                        
                        Text("\(vm.portfolioCoins.count) Assets")
                            .font(.caption)
                            .foregroundStyle(Color.theme.secondaryText)
                            .lineLimit(1)
                        
                        Text("•")
                            .foregroundStyle(Color.theme.secondaryText.opacity(0.5))
                        
                        Text("Top: \(top.symbol.uppercased()) (\(String(format: "%.0f%%", share)))")
                            .font(.caption)
                            .foregroundStyle(Color.theme.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
            }
        }
    }
    
    private var profitBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: isProfitable ? "arrow.up.right" : "arrow.down.right")
            Text(isProfitable ? "+" : "")
            + Text(vm.portfolioProfit24H.asCurrencyWith2Decimals())
            + Text(" (\(vm.portfolioProfitPercentage24H.asPercentString()))")
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
    
    private var allocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Asset Allocation")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.secondaryText)
            
            // Segmented multi-color allocation bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(vm.portfolioCoins.indices, id: \.self) { index in
                        let coin = vm.portfolioCoins[index]
                        let ratio = vm.portfolioTotalValue > 0 ? (coin.currentHoldingsValue / vm.portfolioTotalValue) : 0
                        let width = max(CGFloat(ratio) * geometry.size.width - 2, 4)
                        let color = allocationColors[index % allocationColors.count]
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: width, height: 8)
                    }
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())
            
            // Legend tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.portfolioCoins.indices, id: \.self) { index in
                        let coin = vm.portfolioCoins[index]
                        let share = vm.portfolioShare(for: coin)
                        let color = allocationColors[index % allocationColors.count]
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(color)
                                .frame(width: 6, height: 6)
                            Text(coin.symbol.uppercased())
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.accent)
                                .lineLimit(1)
                            Text(String(format: "%.1f%%", share))
                                .font(.caption2)
                                .foregroundStyle(Color.theme.secondaryText)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

#Preview {
    PortfolioSummaryCard(onAddTapped: {})
        .environmentObject(DeveloperPreview.instance.homeVM)
}
