//
//  MarketDataService.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 27/09/2025.
//

//
//  CoinDataService.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 16/09/2025.
//

import SwiftUI
import Combine

class MarketDataService {
    @Published var marketData: MarketDataModel? = nil
    var marketDataSubscription: AnyCancellable?
    
    init() {
        getData()
    }
    
    private func getData() {
                
        guard let url = URL(string: "https://api.coingecko.com/api/v3/global") else {
                    print("Failed to construct final URL.")
                    return
                }
        
        // Instead Set<AnyCancellable> we are storing each coin seperately so it becomes easy to identify when we want to cancel our subscription
        marketDataSubscription = NetworkingManager.download(url: url)
            .decode(type: GlobalDataModel.self, decoder: JSONDecoder())
            .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self] (returnedGlobalData) in
                self?.marketData = returnedGlobalData.data
                self?.marketDataSubscription?.cancel() // cancelling bcz making only one request (dummy data)
            })
    }
}
