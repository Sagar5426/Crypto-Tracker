//
//  PortfolioSummaryCard.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

/// The main portfolio summary card displayed on the Portfolio tab screen.
struct PortfolioSummaryCard: View {
    @EnvironmentObject private var vm: MarketViewModel
    
    /// Callback when user taps Manage on overall portfolio
    var onManageTapped: (() -> Void)? = nil
    
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
        self.onManageTapped = onAddTapped
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            topBarSection
            
            investedAndCurrentSection
            
            performanceStripSection
            
            if !vm.portfolioCoins.isEmpty {
                Divider()
                    .background(Color.theme.secondaryText.opacity(0.12))
                
                allocationSection
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.06), radius: 12, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Subviews
extension PortfolioSummaryCard {
    
    // MARK: - Top Bar (Title, Asset Count & Manage Action)
    private var topBarSection: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "briefcase.fill")
                    .font(.caption)
                    .foregroundStyle(Color.theme.accent)
                
                Text("PORTFOLIO OVERVIEW")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(0.4)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            if !vm.portfolioCoins.isEmpty {
                Text("•")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText.opacity(0.5))
                
                Text("\(vm.portfolioCoins.count) Assets")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            Spacer()
            
            if let onAdd = onManageTapped {
                Button(action: onAdd) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Manage")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.theme.accent.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Primary Invested & Current Value Cards
    private var investedAndCurrentSection: some View {
        HStack(spacing: 12) {
            // Invested Card
            primaryMetricCard(
                title: "Invested",
                value: vm.portfolioTotalInvested.asCurrencyWith2Decimals(),
                subtitle: "Cost Basis",
                systemImage: "arrow.down.left.circle.fill",
                tintColor: .blue,
                isHighlighted: false
            )
            
            // Current Value Card
            primaryMetricCard(
                title: "Current",
                value: vm.portfolioTotalValue.asCurrencyWith2Decimals(),
                subtitle: "Market Value",
                systemImage: "chart.line.uptrend.xyaxis.circle.fill",
                tintColor: .purple,
                isHighlighted: true
            )
        }
    }
    
    private func primaryMetricCard(
        title: String,
        value: String,
        subtitle: String,
        systemImage: String,
        tintColor: Color,
        isHighlighted: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tintColor)
                
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.3)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer(minLength: 0)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            
            Text(subtitle)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    isHighlighted
                        ? tintColor.opacity(0.07)
                        : Color.theme.secondaryText.opacity(0.06)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isHighlighted
                                ? tintColor.opacity(0.18)
                                : Color.theme.secondaryText.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Unified Performance Strip (Total P&L + 24h Return)
    private var performanceStripSection: some View {
        let totalColor = isProfitable ? Color.theme.green : Color.theme.red
        let dayColor = is24HProfitable ? Color.theme.green : Color.theme.red
        
        return HStack(spacing: 0) {
            // Total P&L Column
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(totalColor.opacity(0.14))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: isProfitable ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(totalColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Returns")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    HStack(spacing: 4) {
                        Text((isProfitable ? "+" : "") + vm.portfolioTotalProfitLoss.asCurrencyWith2Decimals())
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(totalColor)
                        
                        Text("(\((isProfitable ? "+" : "") + vm.portfolioTotalProfitLossPercentage.asPercentString()))")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(totalColor.opacity(0.9))
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if !vm.portfolioCoins.isEmpty {
                Rectangle()
                    .fill(Color.theme.secondaryText.opacity(0.15))
                    .frame(width: 1, height: 28)
                    .padding(.horizontal, 10)
                
                // 24h Return Column
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 9))
                        Text("24h Change")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Color.theme.secondaryText)
                    
                    HStack(spacing: 4) {
                        Text((is24HProfitable ? "+" : "") + vm.portfolioProfit24H.asCurrencyWith2Decimals())
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(dayColor)
                        
                        Text("(\(vm.portfolioProfitPercentage24H.asPercentString()))")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(dayColor.opacity(0.9))
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.theme.secondaryText.opacity(0.05))
        )
    }
    
    // MARK: - Allocation Section
    private var allocationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Asset Allocation")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                if let top = topHolding, vm.portfolioTotalValue > 0 {
                    let share = vm.portfolioShare(for: top)
                    HStack(spacing: 4) {
                        Text("Top:")
                            .foregroundStyle(Color.theme.secondaryText)
                        Text("\(top.symbol.uppercased()) \(String(format: "%.0f%%", share))")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.theme.accent)
                    }
                    .font(.caption2)
                }
            }
            
            // Proportional Segmented Multi-Color Allocation Bar
            GeometryReader { geometry in
                let count = vm.portfolioCoins.count
                let spacing: CGFloat = 3
                let totalSpacing = CGFloat(max(0, count - 1)) * spacing
                let availableWidth = max(0, geometry.size.width - totalSpacing)
                
                HStack(spacing: spacing) {
                    ForEach(vm.portfolioCoins.indices, id: \.self) { index in
                        let coin = vm.portfolioCoins[index]
                        let ratio = vm.portfolioTotalValue > 0
                            ? max(0, min(1, coin.currentHoldingsValue / vm.portfolioTotalValue))
                            : 0
                        let segmentWidth = max(CGFloat(ratio) * availableWidth, 4)
                        let color = allocationColors[index % allocationColors.count]
                        
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(color)
                            .frame(width: segmentWidth, height: 8)
                    }
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())
            
            // Legend Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
                            
                            Text(String(format: "%.1f%%", share))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.theme.secondaryText)
                            
                            Text("(\(coin.currentHoldingsValue.asCurrencyWith2Decimals()))")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.theme.secondaryText.opacity(0.75))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.theme.secondaryText.opacity(0.06))
                        )
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
    .environmentObject(MarketViewModel(isForPreview: true))
    .preferredColorScheme(.dark)
}
