//
//  PortfolioSummaryCard.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

/// The main portfolio summary card displayed on the Portfolio tab screen.
struct PortfolioSummaryCard: View {
    @EnvironmentObject private var vm: HomeViewModel
    
    /// Callback when user taps Manage on overall portfolio
    var onAddTapped: (() -> Void)? = nil
    
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
    
    init(onAddTapped: (() -> Void)? = nil) {
        self.onAddTapped = onAddTapped
    }
    
    // MARK: - Computed Properties
    
    private var isProfitable: Bool {
        vm.portfolioTotalProfitLoss >= 0
    }
    
    private var is24HProfitable: Bool {
        vm.portfolioProfit24H >= 0
    }
    
    private var topHolding: CoinModel? {
        vm.portfolioCoins.max(by: { $0.currentHoldingsValue < $1.currentHoldingsValue })
    }
    
    /// Top 24h best performing coin in portfolio
    private var best24HPerformer: CoinModel? {
        vm.portfolioCoins.max(by: { ($0.priceChangePercentage24H ?? -999) < ($1.priceChangePercentage24H ?? -999) })
    }
    
    /// Top 24h worst performing coin in portfolio
    private var worst24HPerformer: CoinModel? {
        vm.portfolioCoins.min(by: { ($0.priceChangePercentage24H ?? 999) < ($1.priceChangePercentage24H ?? 999) })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection
            
            financialMetricsGrid
            
            if !vm.portfolioCoins.isEmpty {
                Divider()
                    .background(Color.theme.secondaryText.opacity(0.12))
                
                // 24H Top Performers Bar
                topPerformersSection
                
                Divider()
                    .background(Color.theme.secondaryText.opacity(0.12))
                
                // Segmented Multi-Color Asset Allocation
                allocationSection
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.06), radius: 10, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Subviews
extension PortfolioSummaryCard {
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("PORTFOLIO VALUE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                if let onAdd = onAddTapped {
                    Button {
                        onAdd()
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
            }
            
            Text(vm.portfolioTotalValue.asCurrencyWith2Decimals())
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            HStack(spacing: 8) {
                totalProfitBadge
                
                if !vm.portfolioCoins.isEmpty {
                    Text("•")
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.5))
                    
                    Text("\(vm.portfolioCoins.count) Assets")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                        .lineLimit(1)
                    
                    if let top = topHolding, vm.portfolioTotalValue > 0 {
                        let share = vm.portfolioShare(for: top)
                        Text("•")
                            .foregroundStyle(Color.theme.secondaryText.opacity(0.5))
                        
                        Text("Top: \(top.symbol.uppercased()) (\(String(format: "%.0f%%", share)))")
                            .font(.caption)
                            .foregroundStyle(Color.theme.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(.top, 2)
        }
    }
    
    // MARK: - Total All-Time Profit Badge
    private var totalProfitBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: isProfitable ? "arrow.up.right" : "arrow.down.right")
            Text(isProfitable ? "+" : "")
            + Text(vm.portfolioTotalProfitLoss.asCurrencyWith2Decimals())
            + Text(" (\(vm.portfolioTotalProfitLossPercentage.asPercentString()))")
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
    
    // MARK: - Financial Metrics Grid (Invested, Current, Profit & Loss)
    private var financialMetricsGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                // Invested Amount Box
                metricBox(
                    title: "Invested",
                    value: vm.portfolioTotalInvested.asCurrencyWith2Decimals(),
                    subtitle: "Cost basis",
                    systemImage: "arrow.down.circle.fill",
                    tintColor: Color.blue
                )
                
                // Current Value Box
                metricBox(
                    title: "Current Value",
                    value: vm.portfolioTotalValue.asCurrencyWith2Decimals(),
                    subtitle: "\(vm.portfolioCoins.count) Assets",
                    systemImage: "chart.pie.fill",
                    tintColor: Color.purple
                )
                
                // Total Profit & Loss Box
                metricBox(
                    title: "Total P&L",
                    value: (isProfitable ? "+" : "") + vm.portfolioTotalProfitLoss.asCurrencyWith2Decimals(),
                    subtitle: (isProfitable ? "+" : "") + vm.portfolioTotalProfitLossPercentage.asPercentString(),
                    systemImage: isProfitable ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                    tintColor: isProfitable ? Color.theme.green : Color.theme.red
                )
            }
            
            // Secondary Performance / Context Banner
            secondaryPerformanceBanner
        }
    }
    
    @ViewBuilder
    private var secondaryPerformanceBanner: some View {
        if !vm.portfolioCoins.isEmpty {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 10))
                    Text("24h Portfolio Return:")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                HStack(spacing: 3) {
                    Image(systemName: is24HProfitable ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text((is24HProfitable ? "+" : "") + vm.portfolioProfit24H.asCurrencyWith2Decimals())
                    Text("(\(vm.portfolioProfitPercentage24H.asPercentString()))")
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
    }
    
    // MARK: - 24H Top Performers Section
    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("24h Market Movers in Portfolio")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
            }
            
            HStack(spacing: 10) {
                // Best Performer Chip
                if let best = best24HPerformer {
                    let bestPct = best.priceChangePercentage24H ?? 0
                    let isBestPositive = bestPct >= 0
                    
                    HStack(spacing: 6) {
                        CoinImageView(coin: best)
                            .frame(width: 20, height: 20)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text("Best")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.theme.secondaryText)
                                Text(best.symbol.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.theme.accent)
                            }
                            
                            HStack(spacing: 2) {
                                Image(systemName: isBestPositive ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 7, weight: .bold))
                                Text(bestPct.asPercentString())
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(isBestPositive ? Color.theme.green : Color.theme.red)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.green.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.theme.green.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // Worst / Laggard Performer Chip
                if let worst = worst24HPerformer, worst.id != best24HPerformer?.id {
                    let worstPct = worst.priceChangePercentage24H ?? 0
                    let isWorstPositive = worstPct >= 0
                    
                    HStack(spacing: 6) {
                        CoinImageView(coin: worst)
                            .frame(width: 20, height: 20)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text("Laggard")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.theme.secondaryText)
                                Text(worst.symbol.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.theme.accent)
                            }
                            
                            HStack(spacing: 2) {
                                Image(systemName: isWorstPositive ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 7, weight: .bold))
                                Text(worstPct.asPercentString())
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(isWorstPositive ? Color.theme.green : Color.theme.red)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.theme.red.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private func metricBox(
        title: String,
        value: String,
        subtitle: String,
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
            
            Text(subtitle)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(title == "Total P&L" ? tintColor : Color.theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.secondaryText.opacity(0.06))
        )
    }
    
    // MARK: - Allocation Section
    private var allocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Asset Allocation")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                Text("\(vm.portfolioCoins.count) Assets")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
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
                        
                        HStack(spacing: 5) {
                            Circle()
                                .fill(color)
                                .frame(width: 7, height: 7)
                            Text(coin.symbol.uppercased())
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.accent)
                                .lineLimit(1)
                            Text(String(format: "%.1f%%", share))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.theme.secondaryText)
                                .lineLimit(1)
                            Text("(\(coin.currentHoldingsValue.asCurrencyWith2Decimals()))")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.theme.secondaryText.opacity(0.05))
                        .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Previews as Appearing in Main Portfolio Tab
#Preview("Portfolio Tab - Dark Mode") {
    NavigationStack {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    PortfolioSummaryCard(onAddTapped: {})
                        .padding(.top, 8)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Portfolio")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.theme.accent)
                }
            }
        }
    }
    .environmentObject(DeveloperPreview.instance.homeVM)
    .preferredColorScheme(.dark)
}

#Preview("Portfolio Tab - Light Mode") {
    NavigationStack {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    PortfolioSummaryCard(onAddTapped: {})
                        .padding(.top, 8)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Portfolio")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.theme.accent)
                }
            }
        }
    }
    .environmentObject(DeveloperPreview.instance.homeVM)
    .preferredColorScheme(.light)
}

#Preview("Card Component - Populated") {
    ZStack {
        Color.theme.background
            .ignoresSafeArea()
        PortfolioSummaryCard(onAddTapped: {})
    }
    .environmentObject(DeveloperPreview.instance.homeVM)
    .preferredColorScheme(.dark)
}

#Preview("Card Component - Empty State") {
    ZStack {
        Color.theme.background
            .ignoresSafeArea()
        PortfolioSummaryCard(onAddTapped: {})
    }
    .environmentObject(HomeViewModel(isForPreview: true))
    .preferredColorScheme(.dark)
}
