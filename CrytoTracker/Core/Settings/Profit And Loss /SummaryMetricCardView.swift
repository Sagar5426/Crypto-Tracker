import SwiftUI

struct SummaryMetricCardView: View {
    @EnvironmentObject private var vm: MarketViewModel
    var viewModel: ProfitAndLossViewModel? = nil
    
    var totalCryptoVolumeOverride: Double? = nil
    var totalBuyCountOverride: Int? = nil
    var totalSellCountOverride: Int? = nil
    
    init(
        viewModel: ProfitAndLossViewModel? = nil,
        totalCryptoVolume: Double? = nil,
        totalBuyCount: Int? = nil,
        totalSellCount: Int? = nil
    ) {
        self.viewModel = viewModel
        self.totalCryptoVolumeOverride = totalCryptoVolume
        self.totalBuyCountOverride = totalBuyCount
        self.totalSellCountOverride = totalSellCount
    }
    
    private var cryptoTransactions: [TransactionEntity] {
        if let viewModel = viewModel {
            return viewModel.cryptoTransactions
        }
        return vm.transactions.filter {
            let type = ($0.transactionType ?? "").uppercased()
            return ($0.coinID ?? "") != "usd-cash" && (type == "BUY" || type == "SELL")
        }
    }
    
    private var totalCryptoVolume: Double {
        if let override = totalCryptoVolumeOverride {
            return override
        }
        if let viewModel = viewModel {
            return viewModel.totalCryptoVolume
        }
        return cryptoTransactions
            .map { $0.totalValue }
            .reduce(0, +)
    }
    
    private var totalBuyCount: Int {
        if let override = totalBuyCountOverride {
            return override
        }
        if let viewModel = viewModel {
            return viewModel.totalBuyCount
        }
        return cryptoTransactions.filter { ($0.transactionType ?? "").uppercased() == "BUY" }.count
    }
    
    private var totalSellCount: Int {
        if let override = totalSellCountOverride {
            return override
        }
        if let viewModel = viewModel {
            return viewModel.totalSellCount
        }
        return cryptoTransactions.filter { ($0.transactionType ?? "").uppercased() == "SELL" }.count
    }
    
    var body: some View {
        let summary = viewModel?.realizedPnLSummary ?? vm.realizedPnLSummary
        let realizedPnL = summary.totalRealizedPnL
        let unrealizedPnL = viewModel?.portfolioTotalProfitLoss ?? vm.portfolioTotalProfitLoss
        let openHoldingsCount = viewModel?.openHoldingsCount ?? vm.portfolioCoins.filter { ($0.currentHoldings ?? 0) > 0 }.count
        
        let hasClosedTrades = summary.totalClosedTrades > 0
        let hasOpenPositions = openHoldingsCount > 0
        let hasAnyActivity = hasClosedTrades || hasOpenPositions
        
        let netPnL = realizedPnL + unrealizedPnL
        let totalInvestedBasis = summary.totalCostBasis + (viewModel?.portfolioTotalInvested ?? vm.portfolioTotalInvested)
        let netPercentage = totalInvestedBasis > 0 ? (netPnL / totalInvestedBasis) * 100.0 : 0.0
        
        let isNetProfitable = netPnL >= 0
        let isRealizedProfitable = summary.isProfitable
        let isUnrealizedProfitable = unrealizedPnL >= 0
        
        let netColor: Color = hasAnyActivity ? (isNetProfitable ? Color.theme.green : Color.theme.red) : Color.theme.accent
        let realizedColor: Color = hasClosedTrades ? (isRealizedProfitable ? Color.theme.green : Color.theme.red) : Color.theme.accent
        let unrealizedColor: Color = hasOpenPositions ? (isUnrealizedProfitable ? Color.theme.green : Color.theme.red) : Color.theme.accent
        
        VStack(spacing: 14) {
            // Header Row: Title & Activity Counts
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.theme.accent)
                    
                    Text("PROFIT & LOSS OVERVIEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(0.5)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(summary.totalClosedTrades) Closed")
                        .font(.system(size: 10, weight: .semibold))
                    Text("•")
                        .font(.system(size: 9))
                    Text("\(openHoldingsCount) Open")
                        .font(.system(size: 10, weight: .semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.theme.secondaryText.opacity(0.08))
                .clipShape(Capsule())
                .foregroundStyle(Color.theme.secondaryText)
            }
            
            // Total Net P&L Hero Display
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL NET RETURN")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.3)
                    .foregroundStyle(Color.theme.secondaryText)
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(hasAnyActivity && isNetProfitable ? "+" : "")\(netPnL.asCurrencyWith2Decimals())")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(netColor)
                        .monospacedDigit()
                    
                    if hasAnyActivity {
                        HStack(spacing: 3) {
                            Image(systemName: isNetProfitable ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 9, weight: .bold))
                            
                            Text("\(isNetProfitable ? "+" : "")\(netPercentage.asPercentString())")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                        .foregroundStyle(netColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(netColor.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
            }
            
            // Dual P&L Cards: Realized (Closed) & Unrealized (Open)
            HStack(alignment: .top, spacing: 10) {
                // Realized P&L Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(realizedColor)
                        Text("REALIZED")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.3)
                            .foregroundStyle(Color.theme.secondaryText)
                        Spacer(minLength: 0)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(hasClosedTrades && isRealizedProfitable ? "+" : "")\(realizedPnL.asCurrencyWith2Decimals())")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(realizedColor)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        if hasClosedTrades {
                            Text("\(isRealizedProfitable ? "+" : "")\(summary.totalRealizedPercentage.asPercentString())")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(realizedColor)
                                .monospacedDigit()
                        } else {
                            Text("0 closed orders")
                                .font(.system(size: 10.5))
                                .foregroundStyle(Color.theme.secondaryText.opacity(0.7))
                        }
                    }
                    
                    Divider()
                        .background(Color.theme.secondaryText.opacity(0.1))
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("Gains")
                                .font(.system(size: 10.5))
                                .foregroundStyle(Color.theme.secondaryText)
                            Spacer()
                            Text("+" + summary.totalRealizedGains.asCurrencyWith2Decimals())
                                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.theme.green)
                                .monospacedDigit()
                        }
                        
                        HStack {
                            Text("Losses")
                                .font(.system(size: 10.5))
                                .foregroundStyle(Color.theme.secondaryText)
                            Spacer()
                            Text("-" + summary.totalRealizedLosses.asCurrencyWith2Decimals())
                                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.theme.red)
                                .monospacedDigit()
                        }
                    }
                }
                .padding(12)
                .background(Color.theme.secondaryText.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
                )
                
                // Unrealized P&L Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 11))
                            .foregroundStyle(unrealizedColor)
                        Text("UNREALIZED")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.3)
                            .foregroundStyle(Color.theme.secondaryText)
                        Spacer(minLength: 0)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(hasOpenPositions && isUnrealizedProfitable ? "+" : "")\(unrealizedPnL.asCurrencyWith2Decimals())")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(unrealizedColor)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        if hasOpenPositions {
                            let unPct = viewModel?.portfolioTotalProfitLossPercentage ?? vm.portfolioTotalProfitLossPercentage
                            Text("\(isUnrealizedProfitable ? "+" : "")\(unPct.asPercentString())")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(unrealizedColor)
                                .monospacedDigit()
                        } else {
                            Text("0 open holdings")
                                .font(.system(size: 10.5))
                                .foregroundStyle(Color.theme.secondaryText.opacity(0.7))
                        }
                    }
                    
                    Divider()
                        .background(Color.theme.secondaryText.opacity(0.1))
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("Holdings")
                                .font(.system(size: 10.5))
                                .foregroundStyle(Color.theme.secondaryText)
                            Spacer()
                            let portVal = viewModel?.portfolioTotalValue ?? vm.portfolioTotalValue
                            Text(portVal.asCurrencyWith2Decimals())
                                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.theme.accent)
                                .monospacedDigit()
                        }
                        
                        HStack {
                            Text("Invested")
                                .font(.system(size: 10.5))
                                .foregroundStyle(Color.theme.secondaryText)
                            Spacer()
                            let portInv = viewModel?.portfolioTotalInvested ?? vm.portfolioTotalInvested
                            Text(portInv.asCurrencyWith2Decimals())
                                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.theme.secondaryText)
                                .monospacedDigit()
                        }
                    }
                }
                .padding(12)
                .background(Color.theme.secondaryText.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
                )
            }
            
            Divider()
                .background(Color.theme.secondaryText.opacity(0.12))
            
            // Volume Traded & Order Breakdown
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.theme.secondaryText)
                    Text("Traded Volume:")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    Text(totalCryptoVolume.asCurrencyWith2Decimals())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(totalBuyCount) Buys")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.green)
                    
                    Circle()
                        .fill(Color.theme.secondaryText.opacity(0.3))
                        .frame(width: 3, height: 3)
                    
                    Text("\(totalSellCount) Sells")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.red)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

typealias SummaryMetricCard = SummaryMetricCardView
typealias SummaryMetricsCard = SummaryMetricCardView

// MARK: - Previews
#if DEBUG
private func makePreviewVM() -> MarketViewModel {
    let vm = MarketViewModel(isForPreview: true)
    vm.allCoins = [
        DeveloperPreview.instance.coin,
        DeveloperPreview.instance.ethCoin,
        DeveloperPreview.instance.solCoin,
        DeveloperPreview.instance.adaCoin
    ]
    vm.portfolioCoins = vm.allCoins
    vm.loadMockTransactionsForPreview()
    return vm
}

#Preview("Summary Metric Card - Dark") {
    SummaryMetricCardView()
        .environmentObject(makePreviewVM())
        .padding(.vertical)
        .background(Color.theme.background)
        .preferredColorScheme(.dark)
}

#Preview("Summary Metric Card - Light") {
    SummaryMetricCardView()
        .environmentObject(makePreviewVM())
        .padding(.vertical)
        .background(Color.theme.background)
        .preferredColorScheme(.light)
}
#endif
