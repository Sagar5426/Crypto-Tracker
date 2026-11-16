//
//  CashWalletView.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

struct CashWalletView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: MarketViewModel
    
    @State private var selectedMode: WalletAction = .deposit
    @State private var amountText: String = ""
    @State private var showSuccessMessage: Bool = false
    @State private var successDescription: String = ""
    @State private var showResetConfirmation: Bool = false
    
    enum WalletAction: String, CaseIterable, Identifiable {
        case deposit = "Deposit"
        case withdraw = "Withdraw"
        var id: String { rawValue }
    }
    
    private var enteredAmount: Double {
        Double(amountText) ?? 0.0
    }
    
    private var projectedBalance: Double {
        switch selectedMode {
        case .deposit:
            return vm.cashBalance + enteredAmount
        case .withdraw:
            return max(0, vm.cashBalance - enteredAmount)
        }
    }
    
    private var isInsufficientWithdrawal: Bool {
        selectedMode == .withdraw && enteredAmount > vm.cashBalance
    }
    
    private var canExecuteAction: Bool {
        enteredAmount > 0 && !isInsufficientWithdrawal
    }
    
    private var cashTransactions: [TransactionEntity] {
        vm.transactions.filter {
            let type = ($0.transactionType ?? "").uppercased()
            return type == "DEPOSIT" || type == "WITHDRAW"
        }
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
                if !cashTransactions.isEmpty {
                    cashActivitySection
                }
            }
            .padding()
        }
        .navigationTitle("USD Cash Wallet")
        .navigationBarTitleDisplayMode(.inline)
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
                    
                    Text(vm.cashBalance.asCurrencyWith2Decimals())
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedMode = .deposit
                    amountText = ""
                }
                HapticManager.notification(type: .success)
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
                        .fill(selectedMode == .deposit ? Color.theme.green.opacity(0.8) : Color.theme.secondaryText.opacity(0.1))
                )
                .foregroundStyle(selectedMode == .deposit ? Color.white : Color.theme.secondaryText)
            }
            .buttonStyle(.plain)
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedMode = .withdraw
                    amountText = ""
                }
                HapticManager.notification(type: .success)
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
                        .fill(selectedMode == .withdraw ? Color.theme.red : Color.theme.secondaryText.opacity(0.1))
                )
                .foregroundStyle(selectedMode == .withdraw ? Color.white : Color.theme.secondaryText)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var amountInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedMode == .deposit ? "Enter Deposit Amount" : "Enter Withdrawal Amount")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.secondaryText)
            
            HStack {
                Text("$")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.secondaryText)
                
                TextField("0.00", text: $amountText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                
                if !amountText.isEmpty {
                    Button {
                        amountText = ""
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
            if selectedMode == .deposit {
                HStack(spacing: 8) {
                    ForEach([500.0, 1000.0, 5000.0, 10000.0], id: \.self) { preset in
                        Button {
                            amountText = String(format: "%.0f", preset)
                            HapticManager.notification(type: .success)
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
                    ForEach([0.25, 0.50, 0.75, 1.0], id: \.self) { fraction in
                        let title = fraction == 1.0 ? "100% MAX" : "\(Int(fraction * 100))%"
                        Button {
                            let calculated = vm.cashBalance * fraction
                            amountText = String(format: "%.2f", calculated)
                            HapticManager.notification(type: .success)
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
            if isInsufficientWithdrawal {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.theme.red)
                    Text("Cannot withdraw more than available cash (\(vm.cashBalance.asCurrencyWith2Decimals())).")
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
                Text(vm.cashBalance.asCurrencyWith2Decimals())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            Divider()
            
            HStack {
                Text(selectedMode == .deposit ? "Amount to Add" : "Amount to Withdraw")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                Spacer()
                Text((selectedMode == .deposit ? "+$" : "-$") + String(format: "%.2f", enteredAmount))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(selectedMode == .deposit ? Color.theme.green : Color.theme.red)
            }
            
            Divider()
            
            HStack {
                Text("Resulting Cash Balance")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
                Spacer()
                Text(projectedBalance.asCurrencyWith2Decimals())
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
                .stroke(isInsufficientWithdrawal ? Color.theme.red.opacity(0.4) : Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var executeActionButton: some View {
        let isDeposit = selectedMode == .deposit
        let actionColor = isDeposit ? Color.theme.green : Color.theme.red
        let title = isDeposit ? "Confirm Deposit of $\(String(format: "%.2f", enteredAmount))" : "Confirm Withdrawal of $\(String(format: "%.2f", enteredAmount))"
        
        return Button {
            executeWalletAction()
        } label: {
            HStack(spacing: 8) {
                if showSuccessMessage {
                    Image(systemName: "checkmark.circle.fill")
                    Text(successDescription)
                } else {
                    Image(systemName: isDeposit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    Text(title)
                }
            }
            .font(.headline)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canExecuteAction ? actionColor : Color.theme.secondaryText.opacity(0.2))
            .foregroundStyle(canExecuteAction ? Color.white : Color.theme.secondaryText)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: canExecuteAction ? actionColor.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!canExecuteAction || showSuccessMessage)
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
                Text("\(cashTransactions.count) records")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            
            VStack(spacing: 8) {
                ForEach(cashTransactions.prefix(5), id: \.id) { tx in
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
                    
                    if tx.id != cashTransactions.prefix(5).last?.id {
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
    
    private func executeWalletAction() {
        guard enteredAmount > 0 else { return }
        
        switch selectedMode {
        case .deposit:
            vm.depositCash(amount: enteredAmount)
            successDescription = "Deposited $\(String(format: "%.2f", enteredAmount))!"
        case .withdraw:
            let success = vm.withdrawCash(amount: enteredAmount)
            guard success else { return }
            successDescription = "Withdrawn $\(String(format: "%.2f", enteredAmount))!"
        }
        
        withAnimation(.easeIn) {
            showSuccessMessage = true
        }
        HapticManager.notification(type: .success)
        UIApplication.shared.endEditing()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showSuccessMessage = false
                amountText = ""
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
