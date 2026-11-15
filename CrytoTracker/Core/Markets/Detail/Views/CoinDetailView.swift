//
//  DetailView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 30/09/2025.
//

import SwiftUI

// Wrapper to handle unwrapping @binding optional CoinModel
struct DetailLoadingView: View {
    @Binding var coin: CoinModel?
    
    var body: some View {
        ZStack {
            if let coin = coin {
                CoinDetailView(coin: coin)
            }
        }
    }
}

struct CoinDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeVM: MarketViewModel
    @StateObject var vm: DetailViewModel
    @State private var showFullDescription: Bool = false
    @State private var showPortfolioSheet: Bool = false
    @State private var tradeTypeToOpen: TransactionType = .buy
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    init(coin: CoinModel) {
        self._vm = StateObject(wrappedValue: DetailViewModel(coin: coin))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Header Card
                heroHeaderCard
                
                // Interactive Chart Container Card
                chartCardSection
                
                // Personal Portfolio Holdings (with real data)
                if userHasHoldings, let holding = userHoldingCoin {
                    CoinInvestmentCardSection(coin: holding)
                }
                
                // Market Overview Grid
                overviewSection
                
                // Additional Statistics Grid
                additionalSection
                
                // About / Description Card
                if let coinDescription = vm.coinDescription, !coinDescription.isEmpty {
                    descriptionCard(description: coinDescription)
                }
                
                // Official Resources & Links
                linksSection
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color.theme.background.ignoresSafeArea())
        .navigationTitle(vm.coin.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomTradeActionBar
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.headline)
                        .foregroundStyle(Color.theme.accent)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                CoinImageView(coin: vm.coin)
                    .frame(width: 30, height: 30)
            }
        }
        .sheet(isPresented: $showPortfolioSheet) {
            PortfolioView(selectedCoin: vm.coin, initialTradeType: tradeTypeToOpen)
                .environmentObject(homeVM)
        }
    }
}

// MARK: - Subviews & Sections
extension CoinDetailView {
    
    private var isCoinWatchlisted: Bool {
        homeVM.isWatchlisted(coin: vm.coin)
    }
    
    private var userHasHoldings: Bool {
        if let holding = homeVM.portfolioCoins.first(where: { $0.id == vm.coin.id }) {
            return (holding.currentHoldings ?? 0) > 0
        }
        return false
    }
    
    private var userHoldingCoin: CoinModel? {
        homeVM.portfolioCoins.first(where: { $0.id == vm.coin.id })
    }
    
    private var availableHoldingsSubtitle: String {
        if let holding = userHoldingCoin, let qty = holding.currentHoldings, qty > 0 {
            return "\(qty.asNumberString()) \(vm.coin.symbol.uppercased())"
        }
        return "Manage Position"
    }
    
    // MARK: - Hero Header Card
    private var heroHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CoinImageView(coin: vm.coin)
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(vm.coin.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                            .lineLimit(1)
                        
                        Text(vm.coin.symbol.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.theme.secondaryText.opacity(0.12))
                            .clipShape(Capsule())
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    Text("Rank #\(vm.coin.rank)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        homeVM.toggleWatchlist(coin: vm.coin)
                    }
                } label: {
                    Image(systemName: isCoinWatchlisted ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundStyle(isCoinWatchlisted ? Color.yellow : Color.theme.secondaryText)
                        .padding(6)
                        .background(Color.theme.secondaryText.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            // 24H Price Range Bar
            if let high = vm.coin.high24H, let low = vm.coin.low24H, high > low {
                priceRangeBar(low: low, current: vm.coin.currentPrice, high: high)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - 24H High / Low Visual Bar
    private func priceRangeBar(low: Double, current: Double, high: Double) -> some View {
        let range = max(high - low, 0.0001)
        let progress = min(max(CGFloat((current - low) / range), 0), 1)
        
        return VStack(spacing: 6) {
            HStack {
                Text("24h Low: \(low.asFormattedPrice())")
                Spacer()
                Text("24h High: \(high.asFormattedPrice())")
            }
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(Color.theme.secondaryText)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.theme.secondaryText.opacity(0.15))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.theme.red, Color.orange, Color.theme.green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 6)
                    
                    // Pin indicator
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .shadow(color: Color.black.opacity(0.3), radius: 2)
                        .offset(x: max(0, min(geo.size.width * progress - 6, geo.size.width - 12)))
                }
            }
            .frame(height: 12)
        }
    }
    
    // MARK: - Chart Card Container
    private var chartCardSection: some View {
        VStack(spacing: 0) {
            ChartView(coin: vm.coin)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Market Overview Section
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Market Overview", icon: "chart.line.uptrend.xyaxis")
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(vm.overviewStatistics) { stat in
                    statCard(stat: stat)
                }
            }
        }
    }
    
    // MARK: - Additional Dynamics Section
    private var additionalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Market Dynamics", icon: "info.circle.fill")
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(vm.additionalStatistics) { stat in
                    statCard(stat: stat)
                }
            }
        }
    }
    
    // MARK: - Stat Card
    private func statCard(stat: StatisticModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stat.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.theme.secondaryText)
                .lineLimit(1)
            
            Text(stat.value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            
            if let pct = stat.percentageChange {
                HStack(spacing: 3) {
                    Image(systemName: pct >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 8, weight: .bold))
                    Text(pct.asPercentString())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .lineLimit(1)
                }
                .foregroundStyle(pct >= 0 ? Color.theme.green : Color.theme.red)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    (pct >= 0 ? Color.theme.green : Color.theme.red).opacity(0.12)
                )
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.03), radius: 4, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Section Header
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.theme.accent)
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
        }
        .padding(.top, 4)
    }
    
    // MARK: - About Card
    private func descriptionCard(description: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "About \(vm.coin.name)", icon: "doc.plaintext.fill")
            
            VStack(alignment: .leading, spacing: 8) {
                Text(description)
                    .lineLimit(showFullDescription ? nil : 4)
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineSpacing(3)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showFullDescription.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showFullDescription ? "Show Less" : "Read More")
                        Image(systemName: showFullDescription ? "chevron.up" : "chevron.down")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
                    .padding(.vertical, 4)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.theme.background)
                    .shadow(color: Color.theme.accent.opacity(0.03), radius: 4, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Official Links Section
    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Official Resources", icon: "link")
            
            HStack(spacing: 12) {
                if let websiteString = vm.websiteURL, let url = URL(string: websiteString) {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.subheadline)
                            Text("Website")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.background)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                        )
                        .foregroundStyle(Color.theme.accent)
                    }
                }
                
                if let redditString = vm.redditURL, let url = URL(string: redditString) {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.orange)
                            Text("Reddit")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.background)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                        )
                        .foregroundStyle(Color.theme.accent)
                    }
                }
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Redesigned Floating Trade Action Dock
    private var bottomTradeActionBar: some View {
        ZStack(alignment: .bottom) {
            // Subtle progressive fade so scrolling cards blend smoothly under the dock
            LinearGradient(
                colors: [
                    Color.theme.background.opacity(0.0),
                    Color.theme.background.opacity(0.75),
                    Color.theme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 76)
            .allowsHitTesting(false)
            
            HStack(spacing: 10) {
                // Primary Buy Action
                tradeDockButton(
                    title: "Buy \(vm.coin.symbol.uppercased())",
                    subtitle: vm.coin.currentPrice.asFormattedPrice(),
                    systemImage: "arrow.down.left",
                    baseColor: Color.theme.green.opacity(0.7),
                    isProminent: true
                ) {
                    tradeTypeToOpen = .buy
                    showPortfolioSheet = true
                    HapticManager.impact(style: .medium)
                }
                
                // Secondary / Contextual Sell Action
                tradeDockButton(
                    title: "Sell \(vm.coin.symbol.uppercased())",
                    subtitle: availableHoldingsSubtitle,
                    systemImage: "arrow.up.right",
                    baseColor: Color.theme.red.opacity(0.7),
                    isProminent: userHasHoldings
                ) {
                    tradeTypeToOpen = .sell
                    showPortfolioSheet = true
                    HapticManager.impact(style: .medium)
                }
            }
            .padding(7)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.theme.background.opacity(0.82))
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .shadow(color: Color.black.opacity(0.14), radius: 16, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.theme.secondaryText.opacity(0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
    }
    
    // MARK: - Reusable Trade Dock Button
    private func tradeDockButton(
        title: String,
        subtitle: String,
        systemImage: String,
        baseColor: Color,
        isProminent: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Circular Icon Badge
                ZStack {
                    Circle()
                        .fill(
                            isProminent
                                ? Color.white.opacity(0.22)
                                : baseColor.opacity(0.16)
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isProminent ? Color.white : baseColor)
                }
                
                // Label & Contextual Subtitle
                VStack(alignment: .leading, spacing: 1.5) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(isProminent ? Color.white : baseColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Text(subtitle)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(
                            isProminent
                                ? Color.white.opacity(0.82)
                                : Color.theme.secondaryText
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                ZStack {
                    if isProminent {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        baseColor,
                                        baseColor.opacity(0.82)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(baseColor.opacity(0.10))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isProminent
                            ? Color.white.opacity(0.25)
                            : baseColor.opacity(0.28),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isProminent ? baseColor.opacity(0.28) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(TradeActionButtonStyle())
    }
}

// MARK: - Trade Action Button Style
private struct TradeActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

#Preview("DetailView - Dark") {
    NavigationStack {
        CoinDetailView(coin: DeveloperPreview.instance.coin)
            .environmentObject(DeveloperPreview.instance.homeVM)
    }
    .preferredColorScheme(.dark)
}

#Preview("DetailView - Light") {
    NavigationStack {
        CoinDetailView(coin: DeveloperPreview.instance.coin)
            .environmentObject(DeveloperPreview.instance.homeVM)
    }
    .preferredColorScheme(.light)
}
