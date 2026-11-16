//
//  PortfolioSummaryCard.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI
import Charts

/// The main portfolio summary card displayed on the Portfolio tab screen.
/// Flips 180 degrees to reveal an interactive asset allocation pie chart.
struct PortfolioSummaryCard: View {
    @EnvironmentObject private var vm: MarketViewModel
    
    /// Callback when user taps Manage on overall portfolio (retained for backward compatibility)
    var onManageTapped: (() -> Void)? = nil
    
    /// Controls 180° 3D card flip between Portfolio Overview and Asset Allocation Pie Chart
    @State private var isFlipped: Bool = false
    
    /// Selected coin ID for isolating in pie chart and legend breakdown
    @State private var selectedCoinID: String? = nil
    
    // Palette of vibrant colors for the allocation bar and pie chart sectors
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
    
    private var sortedCoinsForAllocation: [CoinModel] {
        vm.portfolioCoins.sorted(by: { $0.currentHoldingsValue > $1.currentHoldingsValue })
    }
    
    private func colorFor(coin: CoinModel) -> Color {
        guard let index = vm.portfolioCoins.firstIndex(where: { $0.id == coin.id }) else {
            return Color.theme.accent
        }
        return allocationColors[index % allocationColors.count]
    }
    
    var body: some View {
        ZStack {
            frontCardView
                .modifier(FlipSideModifier(angle: isFlipped ? 180 : 0, isBack: false))
            
            backCardView
                .modifier(FlipSideModifier(angle: isFlipped ? 180 : 0, isBack: true))
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Front Card View (Portfolio Overview)
extension PortfolioSummaryCard {
    
    private var frontCardView: some View {
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
        .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
        .background(cardBackground)
    }
    
    // MARK: - Front Top Bar (Title, Asset Count & Allocation Flip Action)
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
            
            Button {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                    isFlipped.toggle()
                }
                HapticManager.notification(type: .success)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                    Text("Allocation")
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
    
    // MARK: - Primary Invested & Current Value Cards
    private var investedAndCurrentSection: some View {
        HStack(spacing: 12) {
            // Invested Card
            primaryMetricCard(
                title: "Invested",
                value: vm.portfolioTotalInvested.asCurrencyWith2Decimals(),
                subtitle: nil,
                systemImage: "arrow.down.left.circle.fill",
                tintColor: .blue,
                isHighlighted: false
            )
            
            // Current Value Card
            primaryMetricCard(
                title: "Current",
                value: vm.portfolioTotalValue.asCurrencyWith2Decimals(),
                subtitle: nil,
                systemImage: "chart.line.uptrend.xyaxis.circle.fill",
                tintColor: .purple,
                isHighlighted: true
            )
        }
    }
    
    private func primaryMetricCard(
        title: String,
        value: String,
        subtitle: String?,
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
            
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
            }
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
            // Total P&L Column (Left Half)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Center Vertical Divider
            Rectangle()
                .fill(Color.theme.secondaryText.opacity(0.15))
                .frame(width: 1, height: 34)
                .padding(.horizontal, 12)
            
            // 24h Return Column (Right Half, Flush Trailing)
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 9))
                    Text("24h Change")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(Color.theme.secondaryText)
                
                Text((is24HProfitable ? "+" : "") + vm.portfolioProfit24H.asCurrencyWith2Decimals())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(dayColor)
                
                Text("(\((is24HProfitable ? "+" : "") + vm.portfolioProfitPercentage24H.asPercentString()))")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(dayColor.opacity(0.9))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.theme.secondaryText.opacity(0.05))
        )
    }
    
    // MARK: - Allocation Preview Section
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
                        let isFirst = index == 0
                        let isLast = index == vm.portfolioCoins.count - 1
                        
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
                        .padding(.leading, isFirst ? 16 : 0)
                        .padding(.trailing, isLast ? 16 : 0)
                    }
                }
                .padding(.vertical, 2)
            }
            .padding(.horizontal, -16)
        }
    }
}

// MARK: - Back Card View (Asset Allocation Pie Chart)
extension PortfolioSummaryCard {
    
    private var backCardView: some View {
        VStack(alignment: .leading, spacing: 14) {
            backTopBarSection
            
            if vm.portfolioCoins.isEmpty || vm.portfolioTotalValue <= 0 {
                emptyAllocationState
            } else {
                backPieChartSection
                
                Divider()
                    .background(Color.theme.secondaryText.opacity(0.12))
                
                backSummaryStripSection
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
        .background(cardBackground)
    }
    
    // MARK: - Back Top Bar (Title, Asset Count & Flip Back Action)
    private var backTopBarSection: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "chart.pie.fill")
                    .font(.caption)
                    .foregroundStyle(Color.theme.accent)
                
                Text("ASSET ALLOCATION")
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
            
            Button {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                    isFlipped.toggle()
                }
                HapticManager.notification(type: .success)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "eye.slash.fill")
                    Text("Overview")
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
    
    // MARK: - Pie Chart & Asset Breakdown Section
    private var backPieChartSection: some View {
        HStack(spacing: 14) {
            // Left: Swift Charts Donut Pie Chart with central live inspector
            donutChartView
            
            // Right: Scrollable list of assets with weights & values
            assetBreakdownList
        }
        .frame(height: 140)
    }
    
    private var donutChartView: some View {
        ZStack {
            Chart(vm.portfolioCoins) { coin in
                let isSelected = selectedCoinID == coin.id
                let hasSelection = selectedCoinID != nil
                
                SectorMark(
                    angle: .value("Holdings", coin.currentHoldingsValue),
                    innerRadius: .ratio(0.62),
                    outerRadius: isSelected ? .ratio(1.05) : .ratio(1.0),
                    angularInset: 1.5
                )
                .cornerRadius(3)
                .foregroundStyle(colorFor(coin: coin))
                .opacity(hasSelection ? (isSelected ? 1.0 : 0.35) : 1.0)
            }
            .chartLegend(.hidden)
            .frame(width: 140, height: 140)
            
            donutCenterInfo
        }
        .frame(width: 140, height: 140)
    }
    
    private var donutCenterInfo: some View {
        VStack(spacing: 2) {
            if let selectedCoin = vm.portfolioCoins.first(where: { $0.id == selectedCoinID }) {
                Text(selectedCoin.symbol.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.theme.accent)
                
                Text(selectedCoin.currentHoldingsValue.asCurrencyWith2Decimals())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                
                Text(String(format: "%.1f%%", vm.portfolioShare(for: selectedCoin)))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(colorFor(coin: selectedCoin))
            } else {
                Text("TOTAL")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.theme.secondaryText)
                    .tracking(0.5)
                
                Text(vm.portfolioTotalValue.asCurrencyWith2Decimals())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                
                Text("100%")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.theme.secondaryText)
            }
        }
        .multilineTextAlignment(.center)
        .padding(6)
        .allowsHitTesting(false)
    }
    
    private var assetBreakdownList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                ForEach(sortedCoinsForAllocation) { coin in
                    let isSelected = selectedCoinID == coin.id
                    let share = vm.portfolioShare(for: coin)
                    let color = colorFor(coin: coin)
                    
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            if selectedCoinID == coin.id {
                                selectedCoinID = nil
                            } else {
                                selectedCoinID = coin.id
                            }
                        }
                        HapticManager.notification(type: .success)
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                            
                            Text(coin.symbol.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.theme.accent)
                            
                            Spacer(minLength: 4)
                            
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(String(format: "%.1f%%", share))
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.theme.accent)
                                
                                Text(coin.currentHoldingsValue.asCurrencyWith2Decimals())
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Color.theme.secondaryText)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSelected ? color.opacity(0.18) : Color.theme.secondaryText.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isSelected ? color.opacity(0.6) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Back Summary Strip Section
    private var backSummaryStripSection: some View {
        HStack(spacing: 12) {
            if let top = topHolding, vm.portfolioTotalValue > 0 {
                let share = vm.portfolioShare(for: top)
                HStack(spacing: 4) {
                    Text("Top:")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    Text("\(top.symbol.uppercased()) \(String(format: "%.1f%%", share))")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                }
            }
            
            Spacer()
            
            if selectedCoinID != nil {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCoinID = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 9, weight: .bold))
                        Text("Show All")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.theme.accent.opacity(0.1))
                    .clipShape(Capsule())
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.7))
                    Text("Tap asset to isolate")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }
    
    // MARK: - Empty Allocation State
    private var emptyAllocationState: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .strokeBorder(Color.theme.secondaryText.opacity(0.2), style: StrokeStyle(lineWidth: 10, dash: [4, 4]))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "chart.pie")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.theme.secondaryText)
            }
            .padding(.top, 12)
            
            Text("No Holdings Recorded")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Text("Add crypto assets to see your asset allocation pie chart.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.theme.secondaryText)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Reusable Card Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.theme.background)
            .shadow(color: Color.theme.accent.opacity(0.06), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
            )
    }
}

// MARK: - 3D Card Flip Animation Modifier
struct FlipSideModifier: AnimatableModifier {
    var angle: Double
    let isBack: Bool
    
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
    
    func body(content: Content) -> some View {
        let isVisible = isBack ? (angle >= 90) : (angle < 90)
        
        return content
            .opacity(isVisible ? 1 : 0)
            .accessibilityHidden(!isVisible)
            .allowsHitTesting(isVisible)
            .rotation3DEffect(
                .degrees(isBack ? angle - 180 : angle),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.3
            )
    }
}

// MARK: - Previews
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
