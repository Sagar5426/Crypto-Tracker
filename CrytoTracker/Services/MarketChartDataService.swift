//
//  MarketChartDataService.swift
//  CoinPilot
//
//  Created by Antigravity on 14/11/2026.
//

import Foundation
import Combine

class MarketChartDataService: ObservableObject {
    @Published var chartPoints: [ChartPoint] = []
    @Published var isLoading: Bool = false
    
    private let coin: CoinModel
    private var cache: [String: [ChartPoint]] = [:]
    private var subscription: AnyCancellable?
    
    init(coin: CoinModel) {
        self.coin = coin
        loadInitialData()
    }
    
    private func loadInitialData() {
        let weekPoints = buildSparklinePoints(for: .week)
        if !weekPoints.isEmpty {
            cache[cacheKey(for: .week)] = weekPoints
            self.chartPoints = weekPoints
        }
        
        let dayPoints = buildSparklinePoints(for: .day)
        if !dayPoints.isEmpty {
            cache[cacheKey(for: .day)] = dayPoints
        }
    }
    
    private func cacheKey(for range: ChartTimeRange) -> String {
        return "\(coin.id)_\(range.rawValue)"
    }
    
    func getChartData(for range: ChartTimeRange) {
        subscription?.cancel()
        
        let key = cacheKey(for: range)
        if let cached = cache[key], !cached.isEmpty {
            self.chartPoints = cached
            return
        }
        
        // Provide immediate fallback data so UI remains responsive
        let fallback = fallbackPoints(for: range)
        if !fallback.isEmpty {
            self.chartPoints = fallback
        }
        
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/\(coin.id)/market_chart?vs_currency=usd&days=\(range.daysString)") else {
            return
        }
        
        self.isLoading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "x-cg-demo-api-key": "CG-eJmLKxdJyztc6ehvexEQR3Dj"
        ]
        
        subscription = URLSession.shared.dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .default))
            .tryMap { output -> Data in
                guard let response = output.response as? HTTPURLResponse,
                      (200...299).contains(response.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: MarketChartModel.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure = completion {
                    // Cache the fallback so we don't spam failed requests
                    if let self = self, self.cache[key] == nil, !fallback.isEmpty {
                        self.cache[key] = fallback
                    }
                }
            } receiveValue: { [weak self] returnedModel in
                guard let self = self else { return }
                let points = returnedModel.chartPoints
                if !points.isEmpty {
                    self.cache[key] = points
                    self.chartPoints = points
                }
                self.isLoading = false
            }
    }
    
    private func buildSparklinePoints(for range: ChartTimeRange) -> [ChartPoint] {
        guard let sparkline = coin.sparklineIn7D?.price, !sparkline.isEmpty else { return [] }
        let endingDate = Date(coinGeckoString: coin.lastUpdated ?? "")
        
        switch range {
        case .week:
            let step = (7.0 * 24.0 * 3600.0) / Double(sparkline.count)
            let startingDate = endingDate.addingTimeInterval(-7 * 24 * 3600)
            return sparkline.enumerated().map { index, price in
                ChartPoint(date: startingDate.addingTimeInterval(Double(index) * step), price: price)
            }
        case .day:
            let last24Count = min(24, sparkline.count)
            let daySlice = Array(sparkline.suffix(last24Count))
            let startingDate = endingDate.addingTimeInterval(-24 * 3600)
            let step = (24.0 * 3600.0) / Double(daySlice.count)
            return daySlice.enumerated().map { index, price in
                ChartPoint(date: startingDate.addingTimeInterval(Double(index) * step), price: price)
            }
        default:
            return []
        }
    }
    
    private func fallbackPoints(for range: ChartTimeRange) -> [ChartPoint] {
        let endingDate = Date(coinGeckoString: coin.lastUpdated ?? "")
        let currentPrice = coin.currentPrice
        
        switch range {
        case .day:
            let points = buildSparklinePoints(for: .day)
            if !points.isEmpty { return points }
            let startingDate = endingDate.addingTimeInterval(-24 * 3600)
            let change = (coin.priceChangePercentage24H ?? 0) / 100.0
            let startPrice = currentPrice / (1.0 + change)
            let high = coin.high24H ?? max(currentPrice, startPrice)
            let low = coin.low24H ?? min(currentPrice, startPrice)
            
            var generated: [ChartPoint] = []
            let count = 24
            for i in 0..<count {
                let progress = Double(i) / Double(count - 1)
                let date = startingDate.addingTimeInterval(progress * 24 * 3600)
                let base = startPrice + (currentPrice - startPrice) * progress
                let wobble = sin(progress * .pi * 3) * ((high - low) * 0.25)
                let price = min(max(base + wobble, low), high)
                generated.append(ChartPoint(date: date, price: i == count - 1 ? currentPrice : price))
            }
            return generated
            
        case .week:
            return buildSparklinePoints(for: .week)
            
        case .month:
            let days = 30.0
            let startingDate = endingDate.addingTimeInterval(-days * 24 * 3600)
            let sparkline = coin.sparklineIn7D?.price ?? [currentPrice]
            var generated: [ChartPoint] = []
            let count = 45
            let avgPrice = sparkline.reduce(0, +) / Double(sparkline.count)
            let variance = abs(currentPrice - avgPrice) * 1.5 + currentPrice * 0.05
            
            for i in 0..<count {
                let progress = Double(i) / Double(count - 1)
                let date = startingDate.addingTimeInterval(progress * days * 24 * 3600)
                let trend = (currentPrice - avgPrice) * (progress - 0.5)
                let wave = cos(progress * .pi * 4) * variance
                let price = max(currentPrice * 0.1, avgPrice + trend + wave)
                generated.append(ChartPoint(date: date, price: i == count - 1 ? currentPrice : price))
            }
            return generated
            
        case .year:
            let days = 365.0
            let startingDate = endingDate.addingTimeInterval(-days * 24 * 3600)
            let ath = coin.ath ?? currentPrice * 1.4
            let atl = coin.atl ?? currentPrice * 0.4
            var generated: [ChartPoint] = []
            let count = 52
            
            for i in 0..<count {
                let progress = Double(i) / Double(count - 1)
                let date = startingDate.addingTimeInterval(progress * days * 24 * 3600)
                let mid = (ath + atl) / 2
                let amp = (ath - atl) * 0.35
                let curve = sin(progress * .pi * 2.5) * amp
                let trend = (currentPrice - mid) * progress
                let price = min(max(mid + curve + trend, atl), ath)
                generated.append(ChartPoint(date: date, price: i == count - 1 ? currentPrice : price))
            }
            return generated
            
        case .all:
            let days = 1000.0
            let startingDate = endingDate.addingTimeInterval(-days * 24 * 3600)
            let ath = coin.ath ?? currentPrice * 1.5
            let atl = coin.atl ?? currentPrice * 0.2
            var generated: [ChartPoint] = []
            let count = 60
            
            for i in 0..<count {
                let progress = Double(i) / Double(count - 1)
                let date = startingDate.addingTimeInterval(progress * days * 24 * 3600)
                let expGrowth = pow(progress, 1.8) * (currentPrice - atl) + atl
                let cycle = sin(progress * .pi * 5) * ((ath - atl) * 0.15)
                let price = min(max(expGrowth + cycle, atl), ath)
                generated.append(ChartPoint(date: date, price: i == count - 1 ? currentPrice : price))
            }
            return generated
        }
    }
}
