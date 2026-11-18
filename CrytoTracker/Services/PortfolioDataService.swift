//
//  PortfolioDataService.swift
//  CoinPilot
//
//  Created by Sagar Jangra on 28/09/2025.
//

import SwiftUI
import CoreData

// MARK: - CoreData KVC Accessors for Dynamic Attributes
extension PortfolioEntity {
    var storedInvestedAmount: Double {
        get { (value(forKey: "investedAmount") as? Double) ?? 0.0 }
        set { setValue(newValue, forKey: "investedAmount") }
    }
    
    var storedAverageBuyPrice: Double {
        get { (value(forKey: "averageBuyPrice") as? Double) ?? 0.0 }
        set { setValue(newValue, forKey: "averageBuyPrice") }
    }
}

class PortfolioDataService {
    private let container: NSPersistentContainer
    private let containerName: String = "PortfolioContainer"
    private let entityName: String = "PortfolioEntity"
    
    @Published var savedEntities: [PortfolioEntity] = []
    
    init() {
        container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Error loading Core Data \(error.localizedDescription)")
            }
        }
        self.getPortfolio()
    }
    
    // MARK: Public
    func updatePortfolio(
        coin: CoinModel,
        amount: Double,
        investedAmount: Double? = nil,
        averageBuyPrice: Double? = nil
    ) {
        // check if coin is already in portfolio
        if let entity = savedEntities.first(where: { $0.coinID == coin.id }) {
            if amount > 0 {
                update(entity: entity, amount: amount, investedAmount: investedAmount, averageBuyPrice: averageBuyPrice)
            } else {
                delete(entity: entity)
            }
        } else if amount > 0 {
            add(coin: coin, amount: amount, investedAmount: investedAmount, averageBuyPrice: averageBuyPrice)
        }
    }
    
    // MARK: Private
    private func getPortfolio() {
        let request = NSFetchRequest<PortfolioEntity>(entityName: entityName)
        do {
            savedEntities = try container.viewContext.fetch(request)
        } catch let error {
            print("Error fetching PortfolioEntity \(error.localizedDescription)")
        }
    }
    
    private func add(
        coin: CoinModel,
        amount: Double,
        investedAmount: Double?,
        averageBuyPrice: Double?
    ) {
        let entity = PortfolioEntity(context: container.viewContext)
        entity.coinID = coin.id
        entity.amount = amount
        entity.storedInvestedAmount = investedAmount ?? (amount * coin.currentPrice)
        entity.storedAverageBuyPrice = averageBuyPrice ?? coin.currentPrice
        applyChanges()
    }
    
    private func update(
        entity: PortfolioEntity,
        amount: Double,
        investedAmount: Double?,
        averageBuyPrice: Double?
    ) {
        entity.amount = amount
        if let invested = investedAmount {
            entity.storedInvestedAmount = invested
        }
        if let avgPrice = averageBuyPrice {
            entity.storedAverageBuyPrice = avgPrice
        }
        applyChanges()
    }
    
    private func delete(entity: PortfolioEntity) {
        container.viewContext.delete(entity)
        applyChanges()
    }
    
    private func save() {
        do {
            try container.viewContext.save()
        } catch let error {
            print("Error saving to core data \(error.localizedDescription)")
        }
    }
    
    private func applyChanges() {
        save()
        getPortfolio()
    }
}
