//
//  TransactionDataService.swift
//  CoinPilot
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI
import CoreData

enum TransactionType: String, CaseIterable, Identifiable {
    case buy = "BUY"
    case sell = "SELL"
    case deposit = "DEPOSIT"
    case withdraw = "WITHDRAW"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        case .deposit: return "Deposit"
        case .withdraw: return "Withdraw"
        }
    }
}

class TransactionDataService {
    private let container: NSPersistentContainer
    private let containerName: String = "PortfolioContainer"
    private let entityName: String = "TransactionEntity"
    
    @Published var savedTransactions: [TransactionEntity] = []
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    init() {
        container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Error loading Core Data for Transactions: \(error.localizedDescription)")
            }
        }
        self.getTransactions()
    }
    
    // MARK: - Public
    func addTransaction(coin: CoinModel, type: TransactionType, amount: Double, pricePerCoin: Double, timestamp: Date = Date()) {
        let entity = TransactionEntity(context: container.viewContext)
        entity.id = UUID().uuidString
        entity.coinID = coin.id
        entity.coinName = coin.name
        entity.coinSymbol = coin.symbol
        entity.transactionType = type.rawValue
        entity.amount = amount
        entity.pricePerCoin = pricePerCoin
        entity.totalValue = amount * pricePerCoin
        entity.timestamp = timestamp
        
        applyChanges()
    }
    
    func updateTransaction(id: String, type: TransactionType, amount: Double, pricePerCoin: Double, timestamp: Date) {
        if let entity = savedTransactions.first(where: { $0.id == id }) {
            entity.transactionType = type.rawValue
            entity.amount = amount
            entity.pricePerCoin = pricePerCoin
            entity.totalValue = amount * pricePerCoin
            entity.timestamp = timestamp
            applyChanges()
        }
    }
    
    func addCustomTransaction(coinID: String, coinName: String, coinSymbol: String, type: TransactionType, amount: Double, pricePerCoin: Double, totalValue: Double) {
        let entity = TransactionEntity(context: container.viewContext)
        entity.id = UUID().uuidString
        entity.coinID = coinID
        entity.coinName = coinName
        entity.coinSymbol = coinSymbol
        entity.transactionType = type.rawValue
        entity.amount = amount
        entity.pricePerCoin = pricePerCoin
        entity.totalValue = totalValue
        entity.timestamp = Date()
        
        applyChanges()
    }
    
    func deleteTransaction(entity: TransactionEntity) {
        container.viewContext.delete(entity)
        applyChanges()
    }
    
    func clearAllTransactions() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try container.viewContext.execute(deleteRequest)
            applyChanges()
        } catch {
            // Fallback to manual deletion
            for entity in savedTransactions {
                container.viewContext.delete(entity)
            }
            applyChanges()
        }
    }
    
    // MARK: - Private
    private func getTransactions() {
        let request = NSFetchRequest<TransactionEntity>(entityName: entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.timestamp, ascending: false)]
        
        do {
            savedTransactions = try container.viewContext.fetch(request)
        } catch let error {
            print("Error fetching TransactionEntity: \(error.localizedDescription)")
        }
    }
    
    private func save() {
        do {
            try container.viewContext.save()
        } catch let error {
            print("Error saving Transaction to Core Data: \(error.localizedDescription)")
        }
    }
    
    private func applyChanges() {
        save()
        getTransactions()
    }
}
