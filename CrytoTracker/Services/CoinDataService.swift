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
    
    private func getCoins() {
        // Use URLComponents to build the URL with query parameters
                guard var urlComponents = URLComponents(string: "https://api.coingecko.com/api/v3/coins/markets") else {
                    print("Invalid base URL string.")
                    return
                }
                
        // Building full url for this api(Depends on api)
                urlComponents.queryItems = [
                    URLQueryItem(name: "vs_currency", value: "usd"),
                    URLQueryItem(name: "order", value: "market_cap_desc"),
                    URLQueryItem(name: "per_page", value: "100"),
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "sparkline", value: "true"),
                    URLQueryItem(name: "price_change_percentage", value: "24h")
                ]
                
                guard let url = urlComponents.url else {
                    print("Failed to construct final URL.")
                    return
                }
        
        // Instead Set<AnyCancellable> we are storing each coin seperately so it becomes easy to identify when we want to cancel our subscription
        coinSubscription = URLSession.shared.dataTaskPublisher(for: url)
            .subscribe(on: DispatchQueue.global(qos: .default))
            .tryMap { (output) -> Data in
                guard let response = output.response as? HTTPURLResponse, response.statusCode <= 200 && response.statusCode < 300 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .receive(on: DispatchQueue.main)
            .decode(type: [CoinModel].self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }, receiveValue: { [weak self] allCoins in
                self?.allCoins = allCoins
                self?.coinSubscription?.cancel() // cancelling bcz making only one request (dummy data)
            })
    }
}
