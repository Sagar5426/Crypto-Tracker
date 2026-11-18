//
//  WalletDataService.swift
//  CoinPilot
//
//  Created by Antigravity on 14/11/2026.
//

import Foundation
import Combine

class WalletDataService {
    private let userDefaultsKey = "simulated_usd_cash_balance"
    private let defaultStartingBalance: Double = 10_000.0
    
    @Published var cashBalance: Double = 0.0
    
    init() {
        if let savedBalance = UserDefaults.standard.object(forKey: userDefaultsKey) as? Double {
            self.cashBalance = savedBalance
        } else {
            self.cashBalance = defaultStartingBalance
            UserDefaults.standard.set(defaultStartingBalance, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Public Actions
    
    func deposit(amount: Double) {
        guard amount > 0 else { return }
        cashBalance += amount
        save()
    }
    
    @discardableResult
    func withdraw(amount: Double) -> Bool {
        guard amount > 0, cashBalance >= amount else { return false }
        cashBalance -= amount
        save()
        return true
    }
    
    @discardableResult
    func deduct(amount: Double) -> Bool {
        guard amount > 0, cashBalance >= amount else { return false }
        cashBalance -= amount
        save()
        return true
    }
    
    func credit(amount: Double) {
        guard amount > 0 else { return }
        cashBalance += amount
        save()
    }
    
    func resetBalance(amount: Double = 10_000.0) {
        cashBalance = max(0, amount)
        save()
    }
    
    // MARK: - Persistence
    private func save() {
        UserDefaults.standard.set(cashBalance, forKey: userDefaultsKey)
    }
}
