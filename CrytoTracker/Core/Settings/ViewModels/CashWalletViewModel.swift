//
//  CashWalletViewModel.swift
//  CrytoTracker
//
//  Created by Antigravity on 18/11/2026.
//

import SwiftUI
import Combine

@MainActor
final class CashWalletViewModel: ObservableObject {
    
    // MARK: - Enums
    
    enum WalletAction: String, CaseIterable, Identifiable {
        case deposit = "Deposit"
        case withdraw = "Withdraw"
        
        var id: String { rawValue }
    }
    
    // MARK: - Published Properties
    
    @Published var selectedMode: WalletAction = .deposit
    @Published var amountText: String = ""
    @Published var showSuccessMessage: Bool = false
    @Published var successDescription: String = ""
    @Published var showResetConfirmation: Bool = false
    
    // Synced state from MarketViewModel
    @Published var cashBalance: Double = 0.0
    @Published var transactions: [TransactionEntity] = []
    
    // Preset options
    let depositPresets: [Double] = [500.0, 1000.0, 5000.0, 10000.0]
    let withdrawalFractions: [Double] = [0.25, 0.50, 0.75, 1.0]
    
    // MARK: - Dependencies & Cancellables
    
    private(set) weak var marketViewModel: MarketViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(marketViewModel: MarketViewModel? = nil) {
        if let vm = marketViewModel {
            setMarketViewModel(vm)
        }
    }
    
    // MARK: - MarketViewModel Binding
    
    func setMarketViewModel(_ vm: MarketViewModel) {
        guard self.marketViewModel !== vm else { return }
        self.marketViewModel = vm
        cancellables.removeAll()
        
        self.cashBalance = vm.cashBalance
        self.transactions = vm.transactions
        
        vm.$cashBalance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] balance in
                self?.cashBalance = balance
            }
            .store(in: &cancellables)
        
        vm.$transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] txs in
                self?.transactions = txs
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Business Logic & Calculations
    
    var enteredAmount: Double {
        Double(amountText) ?? 0.0
    }
    
    var projectedBalance: Double {
        switch selectedMode {
        case .deposit:
            return cashBalance + enteredAmount
        case .withdraw:
            return max(0, cashBalance - enteredAmount)
        }
    }
    
    var isInsufficientWithdrawal: Bool {
        selectedMode == .withdraw && enteredAmount > cashBalance
    }
    
    var canExecuteAction: Bool {
        enteredAmount > 0 && !isInsufficientWithdrawal
    }
    
    var cashTransactions: [TransactionEntity] {
        transactions.filter {
            let type = ($0.transactionType ?? "").uppercased()
            return type == "DEPOSIT" || type == "WITHDRAW"
        }
    }
    
    var depositTransactions: [TransactionEntity] {
        cashTransactions.filter { ($0.transactionType ?? "").uppercased() == "DEPOSIT" }
    }
    
    var withdrawTransactions: [TransactionEntity] {
        cashTransactions.filter { ($0.transactionType ?? "").uppercased() == "WITHDRAW" }
    }
    
    var totalDeposited: Double {
        depositTransactions.reduce(0.0) { $0 + $1.totalValue }
    }
    
    var totalWithdrawn: Double {
        withdrawTransactions.reduce(0.0) { $0 + $1.totalValue }
    }
    
    var netCashFlow: Double {
        totalDeposited - totalWithdrawn
    }
    
    var depositRatio: Double {
        let total = totalDeposited + totalWithdrawn
        guard total > 0 else { return 1.0 }
        return totalDeposited / total
    }
    
    var withdrawRatio: Double {
        let total = totalDeposited + totalWithdrawn
        guard total > 0 else { return 0.0 }
        return totalWithdrawn / total
    }
    
    // MARK: - User Intent Actions
    
    func selectMode(_ mode: WalletAction) {
        guard selectedMode != mode else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedMode = mode
            amountText = ""
        }
        HapticManager.selection()
    }
    
    func applyDepositPreset(_ preset: Double) {
        amountText = String(format: "%.0f", preset)
        HapticManager.selection()
    }
    
    func applyWithdrawalFraction(_ fraction: Double) {
        let calculated = cashBalance * fraction
        amountText = String(format: "%.2f", calculated)
        HapticManager.selection()
    }
    
    func clearAmount() {
        amountText = ""
        HapticManager.selection()
    }
    
    func resetWalletToDefault() {
        marketViewModel?.resetCashWallet(to: 10_000.0)
        showSuccessMessage = true
        successDescription = "Reset wallet to $10,000.00"
        HapticManager.notification(type: .success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            withAnimation {
                self?.showSuccessMessage = false
            }
        }
    }
    
    func refreshBalance() {
        marketViewModel?.reloadData()
        HapticManager.notification(type: .success)
    }
    
    func executeWalletAction() {
        guard enteredAmount > 0 else { return }
        guard let vm = marketViewModel else { return }
        
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            withAnimation {
                self?.showSuccessMessage = false
                self?.amountText = ""
            }
        }
    }
}
