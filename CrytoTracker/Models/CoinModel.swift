//
//  CoinModel.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 31/07/2025.
//

import Foundation
// api key call
/*

 let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets")!
 var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
 let queryItems: [URLQueryItem] = [
   URLQueryItem(name: "vs_currency", value: "inr"),
   URLQueryItem(name: "order", value: "market_cap_desc"),
   URLQueryItem(name: "per_page", value: "250"),
   URLQueryItem(name: "page", value: "1"),
   URLQueryItem(name: "sparkline", value: "true"),
   URLQueryItem(name: "price_change_percentage", value: "24h"),
 ]
 components.queryItems = components.queryItems.map { $0 + queryItems } ?? queryItems

 var request = URLRequest(url: components.url!)
 request.httpMethod = "GET"
 request.timeoutInterval = 10
 request.allHTTPHeaderFields = [
   "accept": "application/json",
   "x-cg-demo-api-key": "CG-eJmLKxdJyztc6ehvexEQR3Dj"
 ]

 let (data, _) = try await URLSession.shared.data(for: request)
 print(String(decoding: data, as: UTF8.self))
*/

// api response json
/*
 {
    "id": "bitcoin",
    "symbol": "btc",
    "name": "Bitcoin",
    "image": "https://coin-images.coingecko.com/coins/images/1/large/bitcoin.png?1696501400",
    "current_price": 10385262,
    "market_cap": 206630749856516,
    "market_cap_rank": 1,
    "fully_diluted_valuation": 206630749856516,
    "total_volume": 3967149025433,
    "high_24h": 10409317,
    "low_24h": 10179761,
    "price_change_24h": 57989,
    "price_change_percentage_24h": 0.56151,
    "market_cap_change_24h": 1067195009546,
    "market_cap_change_percentage_24h": 0.51916,
    "circulating_supply": 19899771,
    "total_supply": 19899771,
    "max_supply": 21000000,
    "ath": 10561648,
    "ath_change_percentage": -1.68604,
    "ath_date": "2025-07-14T07:56:01.937Z",
    "atl": 3993.42,
    "atl_change_percentage": 259917.13008,
    "atl_date": "2013-07-05T00:00:00.000Z",
    "roi": null,
    "last_updated": "2025-07-31T11:02:12.360Z",
    "sparkline_in_7d": {
      "price": [
        117731.59658011796,
        117421.54712428327,
        118515.7845286962
      ]
    },
    "price_change_percentage_24h_in_currency": 0.5615133142361227
  }
 */

struct CoinModel: Identifiable, Codable {
    let id, symbol, name: String
    let image: String
    let currentPrice: Double
    let marketCap, marketCapRank, fullyDilutedValuation: Double?
    let totalVolume, high24H, low24H, priceChange24H: Double?
    let priceChangePercentage24H: Double?
    let marketCapChange24H: Double?
    let marketCapChangePercentage24H: Double?
    let circulatingSupply, totalSupply, maxSupply, ath: Double?
    let athChangePercentage: Double?
    let athDate: String?
    let atl, atlChangePercentage: Double?
    let atlDate: String?
    let lastUpdated: String?
    let sparklineIn7D: SparklineIn7D?
    let priceChangePercentage24HInCurrency: Double?
    let currentHoldings: Double?
    
    enum CodingKeys: String, CodingKey {
            case id, symbol, name, image
            case currentPrice = "current_price"
            case marketCap = "market_cap"
            case marketCapRank = "market_cap_rank"
            case fullyDilutedValuation = "fully_diluted_valuation"
            case totalVolume = "total_volume"
            case high24H = "high_24h"
            case low24H = "low_24h"
            case priceChange24H = "price_change_24h"
            case priceChangePercentage24H = "price_change_percentage_24h"
            case marketCapChange24H = "market_cap_change_24h"
            case marketCapChangePercentage24H = "market_cap_change_percentage_24h"
            case circulatingSupply = "circulating_supply"
            case totalSupply = "total_supply"
            case maxSupply = "max_supply"
            case ath
            case athChangePercentage = "ath_change_percentage"
            case athDate = "ath_date"
            case atl
            case atlChangePercentage = "atl_change_percentage"
            case atlDate = "atl_date"
            case lastUpdated = "last_updated"
            case sparklineIn7D = "sparkline_in_7d"
            case priceChangePercentage24HInCurrency = "price_change_percentage_24h_in_currency"
            case currentHoldings
        }
    
    func updateHoldings(amount: Double) -> CoinModel {
           return CoinModel(id: id, symbol: symbol, name: name, image: image, currentPrice: currentPrice, marketCap: marketCap, marketCapRank: marketCapRank, fullyDilutedValuation: fullyDilutedValuation, totalVolume: totalVolume, high24H: high24H, low24H: low24H, priceChange24H: priceChange24H, priceChangePercentage24H: priceChangePercentage24H, marketCapChange24H: marketCapChange24H, marketCapChangePercentage24H: marketCapChangePercentage24H, circulatingSupply: circulatingSupply, totalSupply: totalSupply, maxSupply: maxSupply, ath: ath, athChangePercentage: athChangePercentage, athDate: athDate, atl: atl, atlChangePercentage: atlChangePercentage, atlDate: atlDate, lastUpdated: lastUpdated, sparklineIn7D: sparklineIn7D, priceChangePercentage24HInCurrency: priceChangePercentage24HInCurrency, currentHoldings: amount)
       }
       
       var currentHoldingsValue: Double {
           return (currentHoldings ?? 0) * currentPrice
       }
       
       var rank: Int {
           return Int(marketCapRank ?? 0)
       }
    
}




  // MARK: - SparklineIn7D
struct SparklineIn7D: Codable{
      let price: [Double]?
  }


