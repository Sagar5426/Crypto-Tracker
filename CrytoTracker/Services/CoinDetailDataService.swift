//
//  CoinDetailDataService.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 01/10/2025.
//

import SwiftUI
import Combine

class CoinDetailDataService {
    @Published var coinDetails: CoinDetailModel? = nil
    
    var coinDetailSubscription: AnyCancellable?
    let coin: CoinModel
    
    init(coin: CoinModel) {
        self.coin = coin
        getCoinDetails()
    }
    
    func getCoinDetails() {
                
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/\(coin.id)?localization=false&tickers=false&market_data=false&community_data=false&developer_data=false&sparkline=false") else {
                    print("Failed to construct final URL.")
                    return
                }
        
        // Instead Set<AnyCancellable> we are storing each coin seperately so it becomes easy to identify when we want to cancel our subscription
        coinDetailSubscription = NetworkingManager.download(url: url)
            .decode(type: CoinDetailModel.self, decoder: JSONDecoder())
            .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self] (returnedCoinDetails) in
                self?.coinDetails = returnedCoinDetails
                self?.coinDetailSubscription?.cancel() // cancelling bcz making only one request (dummy data)
            })
    }
}
