//
//  CoinDataService.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 16/09/2025.
//

import SwiftUI
import Combine

class CoinDataService {
    @Published var allCoins: [CoinModel] = []
    var coinSubscription: AnyCancellable?
    
    init() {
        getCoins()
    }
    
    func getCoins() {
                
        guard let url = NetworkingManager.buildUrl() else {
                    print("Failed to construct final URL.")
                    return
                }
        
        // Instead Set<AnyCancellable> we are storing each coin seperately so it becomes easy to identify when we want to cancel our subscription
        // Decoding on BG thread and updating on main
        coinSubscription = NetworkingManager.download(url: url)
            .decode(type: [CoinModel].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self] allCoins in
                self?.allCoins = allCoins
                self?.coinSubscription?.cancel() // cancelling bcz making only one request
            })
    }
}
