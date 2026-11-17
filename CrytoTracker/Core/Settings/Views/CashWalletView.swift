//
//  CashWalletView.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

@MainActor
struct CashWalletView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: MarketViewModel
    
    // MARK: - View Model
    @StateObject private var viewModel: CashWalletViewModel
    
    // Backward compatibility typealias
    typealias WalletAction = CashWalletViewModel.WalletAction
    
    // MARK: - Initializer
    
    init(viewModel: CashWalletViewModel? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel ?? CashWalletViewModel())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Cash Balance Card
                walletHeroCard
                
                // Action Selector (Deposit vs Withdraw)
                actionPicker
                
                // Amount Input & Presets Card
                amountInputCard
                
                // Projected Balance & Execution Summary
                projectedBalanceCard
                
                // Action Button
                executeActionButton
                
                // Cash Activity History
                if !viewModel.cashTransactions.isEmpty {
                    cashActivitySection
                }
            }
            .padding()
        }
        .navigationTitle("USD Cash Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setMarketViewModel(vm)
        }
    }
}

// MARK: - Subviews
extension CashWalletView {
    
    private var walletHeroCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "banknote.fill")
                            .font(.caption)
                            .foregroundStyle(Color.theme.green)
                        Text("WALLET FUND")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    Text(viewModel.cashBalance.asCurrencyWith2Decimals())
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                        .contentTransition(.numericText())
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.theme.green.opacity(0.12))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.theme.green)
                }
            }
            
            Divider()
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.green)
                    Text("Ready for simulated crypto trading")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text("USD ($)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.theme.secondaryText.opacity(0.1))
                    .clipShape(Capsule())
                    .foregroundStyle(Color.theme.accent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var actionPicker: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.selectMode(.deposit)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Add Money")
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.selectedMode == .deposit ? Color.theme.green.opacity(0.8) : Color.theme.secondaryText.opacity(0.1))
                )
                .foregroundStyle(viewModel.selectedMode == .deposit ? Color.white : Color.theme.secondaryText)
            }
            .buttonStyle(.plain)
            
            Button {
                viewModel.selectMode(.withdraw)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Withdraw")
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.selectedMode == .withdraw ? Color.theme.red : Color.theme.secondaryText.opacity(0.1))
                )
                .foregroundStyle(viewModel.selectedMode == .withdraw ? Color.white : Color.theme.secondaryText)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var amountInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.selectedMode == .deposit ? "Enter Deposit Amount" : "Enter Withdrawal Amount")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.secondaryText)
            
            HStack {
                Text("$")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.secondaryText)
                
                TextField("0.00", text: $viewModel.amountText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                
                if !viewModel.amountText.isEmpty {
                    Button {
                        viewModel.clearAmount()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.theme.secondaryText.opacity(0.08))
            )
            
            // Quick preset pills
            if viewModel.selectedMode == .deposit {
                HStack(spacing: 8) {
                    ForEach(viewModel.depositPresets, id: \.self) { preset in
                        Button {
                            viewModel.applyDepositPreset(preset)
                        } label: {
                            Text("+$\(Int(preset))")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.theme.green.opacity(0.12))
                                .clipShape(Capsule())
                                .foregroundStyle(Color.theme.green)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
            } else {
                HStack(spacing: 8) {
                    ForEach(viewModel.withdrawalFractions, id: \.self) { fraction in
                        let title = fraction == 1.0 ? "100% MAX" : "\(Int(fraction * 100))%"
                        Button {
                            viewModel.applyWithdrawalFraction(fraction)
                        } label: {
                            Text(title)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.theme.red.opacity(fraction == 1.0 ? 0.2 : 0.1))
                                .clipShape(Capsule())
                                .foregroundStyle(Color.theme.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var projectedBalanceCard: some View {
        VStack(spacing: 10) {
            if viewModel.isInsufficientWithdrawal {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.theme.red)
                    Text("Cannot withdraw more than available cash (\(viewModel.cashBalance.asCurrencyWith2Decimals())).")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.red)
                    Spacer()
                }
                .padding(10)
                .background(Color.theme.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            HStack {
                Text("Current Cash Balance")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                Spacer()
                Text(viewModel.cashBalance.asCurrencyWith2Decimals())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            Divider()
            
            HStack {
                Text(viewModel.selectedMode == .deposit ? "Amount to Add" : "Amount to Withdraw")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                Spacer()
                Text((viewModel.selectedMode == .deposit ? "+$" : "-$") + String(format: "%.2f", viewModel.enteredAmount))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(viewModel.selectedMode == .deposit ? Color.theme.green : Color.theme.red)
            }
            
            Divider()
            
            HStack {
                Text("Resulting Cash Balance")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
                Spacer()
                Text(viewModel.projectedBalance.asCurrencyWith2Decimals())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(viewModel.isInsufficientWithdrawal ? Color.theme.red.opacity(0.4) : Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var executeActionButton: some View {
        let isDeposit = viewModel.selectedMode == .deposit
        let actionColor = isDeposit ? Color.theme.green.opacity(0.8) : Color.theme.red.opacity(0.8)
        let title = isDeposit ? "Confirm Deposit of $\(String(format: "%.2f", viewModel.enteredAmount))" : "Confirm Withdrawal of $\(String(format: "%.2f", viewModel.enteredAmount))"
        
        return Button {
            viewModel.executeWalletAction()
        } label: {
            HStack(spacing: 8) {
                if viewModel.showSuccessMessage {
                    Image(systemName: "checkmark.circle.fill")
                    Text(viewModel.successDescription)
                } else {
                    Image(systemName: isDeposit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    Text(title)
                }
            }
            .font(.headline)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(viewModel.canExecuteAction ? actionColor : Color.theme.secondaryText.opacity(0.2))
            .foregroundStyle(viewModel.canExecuteAction ? Color.white : Color.theme.secondaryText)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: viewModel.canExecuteAction ? actionColor.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!viewModel.canExecuteAction || viewModel.showSuccessMessage)
        .buttonStyle(.plain)
    }
    
    private var cashActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Cash Activity")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
                Spacer()
                Text("\(viewModel.cashTransactions.count) records")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.cashTransactions.prefix(5), id: \.id) { tx in
                    let isDeposit = (tx.transactionType ?? "").uppercased() == "DEPOSIT"
                    HStack {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill((isDeposit ? Color.theme.green : Color.theme.red).opacity(0.12))
                                    .frame(width: 32, height: 32)
                                Image(systemName: isDeposit ? "arrow.down" : "arrow.up")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(isDeposit ? Color.theme.green : Color.theme.red)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isDeposit ? "Deposit Funds" : "Withdraw Funds")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.theme.accent)
                                
                                Text((tx.timestamp ?? Date()).formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(Color.theme.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        Text((isDeposit ? "+$" : "-$") + String(format: "%.2f", tx.totalValue))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(isDeposit ? Color.theme.green : Color.theme.red)
                    }
                    .padding(.vertical, 4)
                    
                    if tx.id != viewModel.cashTransactions.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.theme.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        CashWalletView()
            .environmentObject(DeveloperPreview.instance.homeVM)
    }
}
