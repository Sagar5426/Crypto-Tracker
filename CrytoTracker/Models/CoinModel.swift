//
//  CoinModel.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 31/07/2025.
//

import Foundation

struct CoinModel: Identifiable, Codable, Equatable, Hashable {
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
    let investedAmount: Double?
    let averageBuyPrice: Double?
    
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
        case investedAmount
        case averageBuyPrice
    }
    
    func updateHoldings(amount: Double, investedAmount: Double? = nil, averageBuyPrice: Double? = nil) -> CoinModel {
        return CoinModel(
            id: id,
            symbol: symbol,
            name: name,
            image: image,
            currentPrice: currentPrice,
            marketCap: marketCap,
            marketCapRank: marketCapRank,
            fullyDilutedValuation: fullyDilutedValuation,
            totalVolume: totalVolume,
            high24H: high24H,
            low24H: low24H,
            priceChange24H: priceChange24H,
            priceChangePercentage24H: priceChangePercentage24H,
            marketCapChange24H: marketCapChange24H,
            marketCapChangePercentage24H: marketCapChangePercentage24H,
            circulatingSupply: circulatingSupply,
            totalSupply: totalSupply,
            maxSupply: maxSupply,
            ath: ath,
            athChangePercentage: athChangePercentage,
            athDate: athDate,
            atl: atl,
            atlChangePercentage: atlChangePercentage,
            atlDate: atlDate,
            lastUpdated: lastUpdated,
            sparklineIn7D: sparklineIn7D,
            priceChangePercentage24HInCurrency: priceChangePercentage24HInCurrency,
            currentHoldings: amount,
            investedAmount: investedAmount,
            averageBuyPrice: averageBuyPrice
        )
    }
    
    var currentHoldingsValue: Double {
        return (currentHoldings ?? 0) * currentPrice
    }
    
    var costBasis: Double {
        if let invested = investedAmount, invested > 0 {
            return invested
        }
        return currentHoldingsValue
    }
    
    var profitLoss: Double {
        return currentHoldingsValue - costBasis
    }
    
    var profitLossPercentage: Double {
        guard costBasis > 0 else { return 0.0 }
        return (profitLoss / costBasis) * 100.0
    }
    
    var rank: Int {
        return Int(marketCapRank ?? 0)
    }
}

// MARK: - Extension Initializer for Backward Compatibility
extension CoinModel {
    init(
        id: String,
        symbol: String,
        name: String,
        image: String,
        currentPrice: Double,
        marketCap: Double?,
        marketCapRank: Double?,
        fullyDilutedValuation: Double?,
        totalVolume: Double?,
        high24H: Double?,
        low24H: Double?,
        priceChange24H: Double?,
        priceChangePercentage24H: Double?,
        marketCapChange24H: Double?,
        marketCapChangePercentage24H: Double?,
        circulatingSupply: Double?,
        totalSupply: Double?,
        maxSupply: Double?,
        ath: Double?,
        athChangePercentage: Double?,
        athDate: String?,
        atl: Double?,
        atlChangePercentage: Double?,
        atlDate: String?,
        lastUpdated: String?,
        sparklineIn7D: SparklineIn7D?,
        priceChangePercentage24HInCurrency: Double?,
        currentHoldings: Double?
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.image = image
        self.currentPrice = currentPrice
        self.marketCap = marketCap
        self.marketCapRank = marketCapRank
        self.fullyDilutedValuation = fullyDilutedValuation
        self.totalVolume = totalVolume
        self.high24H = high24H
        self.low24H = low24H
        self.priceChange24H = priceChange24H
        self.priceChangePercentage24H = priceChangePercentage24H
        self.marketCapChange24H = marketCapChange24H
        self.marketCapChangePercentage24H = marketCapChangePercentage24H
        self.circulatingSupply = circulatingSupply
        self.totalSupply = totalSupply
        self.maxSupply = maxSupply
        self.ath = ath
        self.athChangePercentage = athChangePercentage
        self.athDate = athDate
        self.atl = atl
        self.atlChangePercentage = atlChangePercentage
        self.atlDate = atlDate
        self.lastUpdated = lastUpdated
        self.sparklineIn7D = sparklineIn7D
        self.priceChangePercentage24HInCurrency = priceChangePercentage24HInCurrency
        self.currentHoldings = currentHoldings
        self.investedAmount = nil
        self.averageBuyPrice = nil
    }
}

// MARK: - SparklineIn7D
struct SparklineIn7D: Codable, Equatable, Hashable {
    let price: [Double]?
}
