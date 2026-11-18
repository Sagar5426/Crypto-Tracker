//
//  CashWalletView.swift
//  CoinPilot
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI
import SwiftfulUI

@MainActor
struct CashWalletView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var vm: MarketViewModel
    
    // MARK: - View Model
    @StateObject private var viewModel: CashWalletViewModel
    
    // MARK: - Scroll & Geometry State
    @State private var scrollViewOffset: CGFloat = 0
    
    // Backward compatibility typealias
    typealias WalletAction = CashWalletViewModel.WalletAction
    
    // MARK: - Initializer
    
    init(viewModel: CashWalletViewModel? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel ?? CashWalletViewModel())
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.theme.screenBackground
                .ignoresSafeArea()
            
            // Dynamic ambient financial glow background
            ambientGlowBackground
            
            VStack(spacing: 0) {
                // Header pinned at top
                topBar
                    .background(
                        Color.theme.screenBackground
                            .ignoresSafeArea(edges: .top)
                            .opacity(headerBackgroundOpacity)
                    )
                
                scrollViewLayer
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.setMarketViewModel(vm)
        }
        .confirmationDialog(
            "Reset Wallet Fund",
            isPresented: $viewModel.showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Balance to $10,000.00", role: .destructive) {
                viewModel.resetWalletToDefault()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will restore your simulated USD wallet fund balance to $10,000.00.")
        }
    }
}

// MARK: - Layout & Transitions
extension CashWalletView {
    
    private var headerBackgroundOpacity: Double {
        min(1.0, max(0.0, -scrollViewOffset / 30.0))
    }
    
    private var contentFadeOpacity: Double {
        guard scrollViewOffset < 0 else { return 1.0 }
        return max(0.0, 1.0 - Double(-scrollViewOffset / 200.0))
    }
    
    // MARK: - Ambient Glow Background
    private var ambientGlowBackground: some View {
        LinearGradient(
            stops: [
                .init(color: Color.theme.green.opacity(colorScheme == .dark ? 0.12 : 0.07), location: 0.0),
                .init(color: colorScheme == .dark ? Color.theme.accent.opacity(0.03) : Color.theme.green.opacity(0.02), location: 0.25),
                .init(color: Color.clear, location: 0.55)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .top)
        .frame(height: 420 + max(0, scrollViewOffset))
        .offset(y: min(0, scrollViewOffset))
        .opacity(contentFadeOpacity)
        .allowsHitTesting(false)
    }
    
    // MARK: - Top Header Bar
    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            // Dismiss Button with chevron.down on leading side
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.theme.accent)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.theme.secondaryText.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            
            // Title & Currency Badge
            HStack(spacing: 8) {
                Text("Wallet Fund")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                
                Text("USD")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Color.theme.green.opacity(0.15))
                    .foregroundStyle(Color.theme.green)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            // Reset / Refresh Button
            Button {
                viewModel.showResetConfirmation = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.theme.accent)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.theme.secondaryText.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
    
    // MARK: - Scroll View Layer
    private var scrollViewLayer: some View {
        ScrollViewWithOnScrollChanged(
            .vertical,
            showsIndicators: false,
            content: {
                VStack(spacing: 16) {
                    // Hero Cash Balance Card
                    walletHeroCard
                    
                    // Action Mode Picker (Add Funds vs Withdraw)
                    actionSegmentedPicker
                    
                    // Amount Input & Quick Preset Chips
                    amountInputCard
                    
                    // Projected Balance Summary
                    projectedBalanceCard
                    
                    // Execute Action Button
                    executeActionButton
                    
                    // Recent Cash Activity History
                    cashActivitySection
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 50)
            },
            onScrollChanged: { offset in
                scrollViewOffset = offset.y
            }
        )
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            viewModel.refreshBalance()
        }
    }
}

// MARK: - Subviews & Component Cards
extension CashWalletView {
    
    // MARK: - Hero Cash Card
    private var walletHeroCard: some View {
        VStack(spacing: 14) {
            // Header: Category label & Simulated Capital badge
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.theme.green)
                    
                    Text("USD CASH BALANCE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.theme.green)
                    Text("Simulated Capital")
                        .font(.system(size: 10, weight: .semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.theme.green.opacity(0.12))
                .clipShape(Capsule())
                .foregroundStyle(Color.theme.green)
            }
            
            // Hero Balance
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.cashBalance.asCurrencyWith2Decimals())
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Inflow vs Outflow Ratio Bar (if transactions exist)
            if viewModel.totalDeposited > 0 || viewModel.totalWithdrawn > 0 {
                cashFlowRatioBar
            }
            
            // Dual Sub-Cards: Deposited & Withdrawn
            HStack(spacing: 10) {
                heroMetricSubCard(
                    title: "Deposited",
                    amountText: viewModel.totalDeposited.asCurrencyWith2Decimals(),
                    color: Color.theme.green,
                    systemImage: "arrow.down.left.circle.fill"
                )
                
                heroMetricSubCard(
                    title: "Withdrawn",
                    amountText: viewModel.totalWithdrawn.asCurrencyWith2Decimals(),
                    color: Color.theme.red,
                    systemImage: "arrow.up.right.circle.fill"
                )
            }
            
            Divider()
                .background(Color.theme.secondaryText.opacity(0.12))
            
            // Footer: Net Flow & Instant Settlement Status
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.theme.secondaryText)
                    Text("Net Cashflow:")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    let netFlow = viewModel.netCashFlow
                    Text((netFlow >= 0 ? "+" : "") + netFlow.asCurrencyWith2Decimals())
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(netFlow >= 0 ? Color.theme.green : Color.theme.red)
                        .monospacedDigit()
                }
                
                Spacer()
                
                Text("Live Instant Settlement")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Cash Flow Ratio Bar
    private var cashFlowRatioBar: some View {
        let depRatio = viewModel.depositRatio
        let withRatio = viewModel.withdrawRatio
        
        return VStack(spacing: 4) {
            GeometryReader { geo in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.theme.green)
                        .frame(width: max(4, geo.size.width * CGFloat(depRatio) - 1.5))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.theme.red)
                        .frame(width: max(4, geo.size.width * CGFloat(withRatio) - 1.5))
                }
            }
            .frame(height: 5)
            .clipShape(Capsule())
            
            HStack {
                Text("Inflow: \(String(format: "%.1f%%", depRatio * 100))")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(Color.theme.green)
                
                Spacer()
                
                Text("Outflow: \(String(format: "%.1f%%", withRatio * 100))")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(Color.theme.red)
            }
        }
    }
    
    // MARK: - Hero Metric Sub-Card
    private func heroMetricSubCard(
        title: String,
        amountText: String,
        color: Color,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 11))
                
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                
                Spacer(minLength: 4)
                
            }
            .foregroundStyle(color)
            
            Text(amountText)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Action Segmented Picker
    private var actionSegmentedPicker: some View {
        HStack(spacing: 8) {
            ForEach(CashWalletViewModel.WalletAction.allCases) { mode in
                let isSelected = viewModel.selectedMode == mode
                let isDeposit = mode == .deposit
                let activeColor = isDeposit ? Color.theme.green.opacity(0.8) : Color.theme.red.opacity(0.8)
                
                Button {
                    viewModel.selectMode(mode)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isDeposit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                        
                        Text(isDeposit ? "Add Funds" : "Withdraw Funds")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSelected ? activeColor : Color.theme.secondaryText.opacity(0.08))
                    )
                    .foregroundStyle(isSelected ? Color.white : Color.theme.secondaryText)
                    .shadow(color: isSelected ? activeColor.opacity(0.25) : Color.clear, radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Amount Input Card
    private var amountInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.selectedMode == .deposit ? "SPECIFY DEPOSIT AMOUNT" : "SPECIFY WITHDRAWAL AMOUNT")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                if viewModel.selectedMode == .withdraw {
                    Text("Avail: \(viewModel.cashBalance.asCurrencyWith2Decimals())")
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.theme.secondaryText)
                }
            }
            
            // Large Modern Input Field Row
            HStack(spacing: 8) {
                Text("$")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.secondaryText)
                
                TextField("0.00", text: $viewModel.amountText)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                    .keyboardType(.decimalPad)
                
                if !viewModel.amountText.isEmpty {
                    Button {
                        viewModel.clearAmount()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.theme.secondaryText.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.theme.secondaryText.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
            )
            
            // Quick Preset Chips
            if viewModel.selectedMode == .deposit {
                HStack(spacing: 8) {
                    ForEach(viewModel.depositPresets, id: \.self) { preset in
                        let isCurrent = viewModel.enteredAmount == preset
                        Button {
                            viewModel.applyDepositPreset(preset)
                        } label: {
                            Text("+$" + String(format: "%.0f", preset))
                                .font(.system(size: 11, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(isCurrent ? Color.theme.green : Color.theme.green.opacity(0.12))
                                )
                                .foregroundStyle(isCurrent ? Color.white : Color.theme.green)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(viewModel.withdrawalFractions, id: \.self) { fraction in
                        let title = fraction == 1.0 ? "MAX" : "\(Int(fraction * 100))%"
                        Button {
                            viewModel.applyWithdrawalFraction(fraction)
                        } label: {
                            Text(title)
                                .font(.system(size: 11, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color.theme.red.opacity(fraction == 1.0 ? 0.2 : 0.1))
                                )
                                .foregroundStyle(Color.theme.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Projected Balance Card
    private var projectedBalanceCard: some View {
        VStack(spacing: 10) {
            if viewModel.isInsufficientWithdrawal {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.theme.red)
                    
                    Text("Cannot withdraw more than available cash (\(viewModel.cashBalance.asCurrencyWith2Decimals())).")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.theme.red)
                    
                    Spacer()
                }
                .padding(10)
                .background(Color.theme.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
            HStack {
                Text("Current Cash Balance")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.theme.secondaryText)
                Spacer()
                Text(viewModel.cashBalance.asCurrencyWith2Decimals())
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                    .monospacedDigit()
            }
            
            Divider()
                .background(Color.theme.secondaryText.opacity(0.08))
            
            HStack {
                Text(viewModel.selectedMode == .deposit ? "Amount to Add" : "Amount to Withdraw")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.theme.secondaryText)
                Spacer()
                Text((viewModel.selectedMode == .deposit ? "+$" : "-$") + String(format: "%.2f", viewModel.enteredAmount))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.selectedMode == .deposit ? Color.theme.green : Color.theme.red)
                    .monospacedDigit()
            }
            
            Divider()
                .background(Color.theme.secondaryText.opacity(0.08))
            
            HStack {
                Text("Resulting Cash Balance")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.theme.accent)
                Spacer()
                Text(viewModel.projectedBalance.asCurrencyWith2Decimals())
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                    .monospacedDigit()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(viewModel.isInsufficientWithdrawal ? Color.theme.red.opacity(0.4) : Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Execute Action Button
    private var executeActionButton: some View {
        let isDeposit = viewModel.selectedMode == .deposit
        let actionColor = isDeposit ? Color.theme.green : Color.theme.red
        let title = isDeposit ? "Confirm Deposit of $\(String(format: "%.2f", viewModel.enteredAmount))" : "Confirm Withdrawal of $\(String(format: "%.2f", viewModel.enteredAmount))"
        
        return Button {
            viewModel.executeWalletAction()
        } label: {
            HStack(spacing: 8) {
                if viewModel.showSuccessMessage {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text(viewModel.successDescription)
                        .font(.system(size: 15, weight: .bold))
                } else {
                    Image(systemName: isDeposit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(viewModel.canExecuteAction ? actionColor : Color.theme.secondaryText.opacity(0.15))
            .foregroundStyle(viewModel.canExecuteAction ? Color.white : Color.theme.secondaryText)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: viewModel.canExecuteAction ? actionColor.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!viewModel.canExecuteAction || viewModel.showSuccessMessage)
        .buttonStyle(.plain)
    }
    
    // MARK: - Cash Activity Section
    private var cashActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text("RECENT CASH ACTIVITY")
                        .font(.system(size: 10.5, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text("\(viewModel.cashTransactions.count) records")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Color.theme.secondaryText.opacity(0.08))
                    .foregroundStyle(Color.theme.secondaryText)
                    .clipShape(Capsule())
            }
            
            if viewModel.cashTransactions.isEmpty {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.secondaryText.opacity(0.08))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "banknote")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    Text("No Cash Activity Yet")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.theme.accent)
                    
                    Text("Deposits and withdrawals will appear here automatically.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.theme.background)
                        .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
            } else {
                VStack(spacing: 0) {
                    let recentList = Array(viewModel.cashTransactions.prefix(8))
                    ForEach(recentList.indices, id: \.self) { index in
                        let tx = recentList[index]
                        let isDeposit = (tx.transactionType ?? "").uppercased() == "DEPOSIT"
                        
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill((isDeposit ? Color.theme.green : Color.theme.red).opacity(0.12))
                                    .frame(width: 34, height: 34)
                                Image(systemName: isDeposit ? "arrow.down.left" : "arrow.up.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(isDeposit ? Color.theme.green : Color.theme.red)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isDeposit ? "Deposit Funds" : "Withdraw Funds")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.theme.accent)
                                
                                Text((tx.timestamp ?? Date()).formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(Color.theme.secondaryText)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text((isDeposit ? "+$" : "-$") + String(format: "%.2f", tx.totalValue))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(isDeposit ? Color.theme.green : Color.theme.red)
                                    .monospacedDigit()
                                
                                Text("USD")
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundStyle(Color.theme.secondaryText.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        
                        if index < recentList.count - 1 {
                            Divider()
                                .background(Color.theme.secondaryText.opacity(0.08))
                                .padding(.leading, 54)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.theme.background)
                        .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        CashWalletView()
            .environmentObject(DeveloperPreview.instance.homeVM)
    }
}
