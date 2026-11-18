//
//  ChartViewModel.swift
//  CoinPilot
//
//  Created by Antigravity on 18/11/2026.
//

import SwiftUI
import Combine

@MainActor
final class ChartViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var coin: CoinModel
    @Published var selectedRange: ChartTimeRange = .week
    @Published var selectedDate: Date? = nil
    @Published var points: [ChartPoint] = []
    @Published var isLoading: Bool = false
    
    // MARK: - Services & Subscriptions
    
    private let chartService: MarketChartDataService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(coin: CoinModel) {
        self.coin = coin
        self.chartService = MarketChartDataService(coin: coin)
        addSubscribers()
    }
    
    private func addSubscribers() {
        chartService.$chartPoints
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fetchedPoints in
                self?.points = fetchedPoints
            }
            .store(in: &cancellables)
        
        chartService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Domain & Formatting Properties
    
    var prices: [Double] {
        points.map { $0.price }
    }
    
    var rawMaxY: Double {
        prices.max() ?? (coin.currentPrice * 1.05)
    }
    
    var rawMinY: Double {
        prices.min() ?? (coin.currentPrice * 0.95)
    }
    
    var yPadding: Double {
        let diff = rawMaxY - rawMinY
        return diff > 0 ? diff * 0.08 : (rawMaxY * 0.05)
    }
    
    var domainMinY: Double {
        max(0, rawMinY - yPadding)
    }
    
    var domainMaxY: Double {
        rawMaxY + yPadding
    }
    
    var startingPrice: Double {
        prices.first ?? coin.currentPrice
    }
    
    var scrubbedPoint: ChartPoint? {
        guard let date = selectedDate, !points.isEmpty else { return nil }
        return points.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    var activePrice: Double {
        if selectedRange == .day && scrubbedPoint == nil {
            return coin.currentPrice
        }
        return scrubbedPoint?.price ?? (prices.last ?? coin.currentPrice)
    }
    
    var priceDifference: Double {
        if selectedRange == .day && scrubbedPoint == nil, let diff24H = coin.priceChange24H {
            return diff24H
        }
        return activePrice - startingPrice
    }
    
    var percentageChange: Double {
        if selectedRange == .day && scrubbedPoint == nil, let change24H = coin.priceChangePercentage24H {
            return change24H
        }
        guard startingPrice > 0 else { return 0 }
        return (priceDifference / startingPrice) * 100
    }
    
    var lineColor: Color {
        priceDifference >= 0 ? Color.theme.green : Color.theme.red
    }
    
    // MARK: - User Intent Actions
    
    func selectRange(_ range: ChartTimeRange) {
        guard selectedRange != range else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedRange = range
            selectedDate = nil
        }
        chartService.getChartData(for: range)
        HapticManager.notification(type: .success)
    }
    
    func onScrubDateChanged(oldValue: Date?, newValue: Date?) {
        if let newDate = newValue, let oldDate = oldValue {
            if abs(newDate.timeIntervalSince(oldDate)) > 10 {
                HapticManager.notification(type: .warning)
            }
        } else if newValue != nil {
            HapticManager.notification(type: .warning)
        }
    }
}
