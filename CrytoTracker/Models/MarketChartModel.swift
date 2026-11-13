//
//  MarketChartModel.swift
//  CrytoTracker
//
//  Created by Antigravity on 14/11/2026.
//

import Foundation

enum ChartTimeRange: String, CaseIterable, Identifiable {
    case day = "24H"
    case week = "7D"
    case month = "1M"
    case year = "1Y"
    case all = "ALL"
    
    var id: String { rawValue }
    
    var daysString: String {
        switch self {
        case .day: return "1"
        case .week: return "7"
        case .month: return "30"
        case .year: return "365"
        case .all: return "max"
        }
    }
    
    var title: String {
        switch self {
        case .day: return "Past 24 Hours"
        case .week: return "Past 7 Days"
        case .month: return "Past 30 Days"
        case .year: return "Past Year"
        case .all: return "All Time"
        }
    }
}

struct ChartPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let price: Double
}

struct MarketChartModel: Codable {
    let prices: [[Double]]?
    let marketCaps: [[Double]]?
    let totalVolumes: [[Double]]?
    
    enum CodingKeys: String, CodingKey {
        case prices
        case marketCaps = "market_caps"
        case totalVolumes = "total_volumes"
    }
    
    var chartPoints: [ChartPoint] {
        guard let prices = prices, !prices.isEmpty else { return [] }
        return prices.compactMap { point in
            guard point.count >= 2 else { return nil }
            let timestamp = point[0] / 1000.0
            let price = point[1]
            return ChartPoint(date: Date(timeIntervalSince1970: timestamp), price: price)
        }
    }
}
