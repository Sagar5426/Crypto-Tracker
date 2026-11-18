//
//  CoinInvestmentBreakdownViewModel.swift
//  CoinPilot
//
//  Created by Antigravity on 18/11/2026.
//

import SwiftUI
import Combine

@MainActor
final class CoinInvestmentBreakdownViewModel: ObservableObject {
    
    struct PurchaseLot: Identifiable, Equatable {
        let id: String
        let date: Date
        let amount: Double
        let pricePerCoin: Double
    }
    
    // MARK: - Published Properties
    
    @Published var coin: CoinModel
    @Published var currentCoin: CoinModel
    @Published var purchaseLots: [PurchaseLot] = []
    @Published var editingLot: PurchaseLot? = nil
    
    // MARK: - Dependencies
    
    private(set) weak var marketViewModel: MarketViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(coin: CoinModel, marketViewModel: MarketViewModel? = nil) {
        self.coin = coin
        self.currentCoin = coin
        if let vm = marketViewModel {
            setMarketViewModel(vm)
        }
    }
    
    // MARK: - MarketViewModel Binding
    
    func setMarketViewModel(_ vm: MarketViewModel) {
        guard self.marketViewModel !== vm else { return }
        self.marketViewModel = vm
        cancellables.removeAll()
        
        recalculate(from: vm)
        
        // Listen to changes in portfolio coins and transactions
        vm.$portfolioCoins
            .combineLatest(vm.$transactions)
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak vm] _, _ in
                guard let self = self, let vm = vm else { return }
                self.recalculate(from: vm)
            }
            .store(in: &cancellables)
    }
    
    private func recalculate(from vm: MarketViewModel) {
        let updatedCoin = vm.portfolioCoins.first(where: { $0.id == coin.id }) ?? coin
        self.currentCoin = updatedCoin
        
        let buyTxs = vm.transactions(for: updatedCoin.id)
            .filter { ($0.transactionType ?? "").uppercased() == "BUY" }
            .sorted { ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) }
        
        if !buyTxs.isEmpty {
            self.purchaseLots = buyTxs.map { tx in
                PurchaseLot(
                    id: tx.id ?? UUID().uuidString,
                    date: tx.timestamp ?? Date(),
                    amount: tx.amount,
                    pricePerCoin: tx.pricePerCoin
                )
            }
        } else if let holdings = updatedCoin.currentHoldings, holdings > 0 {
            let buyPrice = updatedCoin.averageBuyPrice ?? updatedCoin.currentPrice
            let fallbackDate = Calendar.current.date(byAdding: .day, value: -78, to: Date()) ?? Date()
            self.purchaseLots = [
                PurchaseLot(
                    id: "primary-lot",
                    date: fallbackDate,
                    amount: holdings,
                    pricePerCoin: buyPrice
                )
            ]
        } else {
            self.purchaseLots = []
        }
    }
    
    // MARK: - Intent Actions
    
    func editLot(_ lot: PurchaseLot) {
        editingLot = lot
    }
    
    func updateTransaction(id: String, updatedDate: Date, updatedAmount: Double, updatedPrice: Double) {
        marketViewModel?.updateTransactionAndRecalculate(
            id: id,
            coin: currentCoin,
            type: .buy,
            amount: updatedAmount,
            pricePerCoin: updatedPrice,
            timestamp: updatedDate
        )
        if let vm = marketViewModel {
            recalculate(from: vm)
        }
    }
}
