//
//  WatchlistDataService.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI
import CoreData

class WatchlistDataService {
    private let container: NSPersistentContainer
    private let containerName: String = "PortfolioContainer"
    private let entityName: String = "WatchlistEntity"
    
    @Published var savedEntities: [WatchlistEntity] = []
    
    init() {
        container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Error loading Core Data for Watchlist: \(error.localizedDescription)")
            }
        }
        self.getWatchlist()
    }
    
    // MARK: Public
    func toggleWatchlist(coin: CoinModel) {
        if let entity = savedEntities.first(where: { $0.coinID == coin.id }) {
            delete(entity: entity)
        } else {
            add(coin: coin)
        }
    }
    
    func isWatchlisted(coinID: String) -> Bool {
        savedEntities.contains(where: { $0.coinID == coinID })
    }
    
    // MARK: Private
    private func getWatchlist() {
        let request = NSFetchRequest<WatchlistEntity>(entityName: entityName)
        do {
            savedEntities = try container.viewContext.fetch(request)
        } catch let error {
            print("Error fetching WatchlistEntity: \(error.localizedDescription)")
        }
    }
    
    private func add(coin: CoinModel) {
        let entity = WatchlistEntity(context: container.viewContext)
        entity.coinID = coin.id
        entity.addedDate = Date()
        applyChanges()
    }
    
    private func delete(entity: WatchlistEntity) {
        container.viewContext.delete(entity)
        applyChanges()
    }
    
    private func save() {
        do {
            try container.viewContext.save()
        } catch let error {
            print("Error saving Watchlist to Core Data: \(error.localizedDescription)")
        }
    }
    
    private func applyChanges() {
        save()
        getWatchlist()
    }
}
