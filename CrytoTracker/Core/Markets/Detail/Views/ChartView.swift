//
//  ChartView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 02/10/2025.
//

import SwiftUI
import Charts

struct ChartView: View {
    let coin: CoinModel
    @StateObject private var chartService: MarketChartDataService
    
    @State private var selectedRange: ChartTimeRange = .week
    @State private var selectedDate: Date? = nil
    
    init(coin: CoinModel) {
        self.coin = coin
        self._chartService = StateObject(wrappedValue: MarketChartDataService(coin: coin))
    }
    
    private var points: [ChartPoint] {
        chartService.chartPoints
    }
    
    private var prices: [Double] {
        points.map { $0.price }
    }
    
    private var rawMaxY: Double {
        prices.max() ?? (coin.currentPrice * 1.05)
    }
    
    private var rawMinY: Double {
        prices.min() ?? (coin.currentPrice * 0.95)
    }
    
    private var yPadding: Double {
        let diff = rawMaxY - rawMinY
        return diff > 0 ? diff * 0.08 : (rawMaxY * 0.05)
    }
    
    private var domainMinY: Double {
        max(0, rawMinY - yPadding)
    }
    
    private var domainMaxY: Double {
        rawMaxY + yPadding
    }
    
    private var startingPrice: Double {
        prices.first ?? coin.currentPrice
    }
    
    private var scrubbedPoint: ChartPoint? {
        guard let date = selectedDate, !points.isEmpty else { return nil }
        return points.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    private var activePrice: Double {
        if selectedRange == .day && scrubbedPoint == nil {
            return coin.currentPrice
        }
        return scrubbedPoint?.price ?? (prices.last ?? coin.currentPrice)
    }
    
    private var priceDifference: Double {
        if selectedRange == .day && scrubbedPoint == nil, let diff24H = coin.priceChange24H {
            return diff24H
        }
        return activePrice - startingPrice
    }
    
    private var percentageChange: Double {
        if selectedRange == .day && scrubbedPoint == nil, let change24H = coin.priceChangePercentage24H {
            return change24H
        }
        guard startingPrice > 0 else { return 0 }
        return (priceDifference / startingPrice) * 100
    }
    
    private var lineColor: Color {
        priceDifference >= 0 ? Color.theme.green : Color.theme.red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            chartHeaderView
            
            timeRangePicker
            
            chartContent
                .frame(height: 230)
                .padding(.top, 4)
        }
        .padding(.horizontal)
        .onChange(of: selectedDate) { oldValue, newValue in
            if let newDate = newValue, let oldDate = oldValue {
                if abs(newDate.timeIntervalSince(oldDate)) > 10 {
                    HapticManager.notification(type: .warning)
                }
            } else if newValue != nil {
                HapticManager.notification(type: .warning)
            }
        }
    }
}

// MARK: - Subviews & Components
extension ChartView {
    
    private var chartHeaderView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(activePrice.asCurrencyWith6Decimals())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                    .contentTransition(.numericText())
                
                Spacer()
                
                if chartService.isLoading {
                    ProgressView()
                        .scaleEffect(0.85)
                }
            }
            
            HStack(spacing: 6) {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 8))
                    .rotationEffect(Angle(degrees: priceDifference >= 0 ? 0 : 180))
                
                Text(priceDifference >= 0 ? "+" : "")
                + Text(priceDifference.asCurrencyWith2Decimals())
                + Text(" (\(percentageChange.asPercentString()))")
                
                if let scrub = scrubbedPoint {
                    Text("• \(scrub.date.asMediumDateTimeString())")
                        .foregroundStyle(Color.theme.secondaryText)
                } else {
                    Text("• \(selectedRange.title)")
                        .foregroundStyle(Color.theme.secondaryText)
                }
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(lineColor)
        }
    }
    
    private var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(ChartTimeRange.allCases) { range in
                Button {
                    guard selectedRange != range else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedRange = range
                        selectedDate = nil
                    }
                    chartService.getChartData(for: range)
                    HapticManager.notification(type: .success)
                } label: {
                    Text(range.rawValue)
                        .font(.caption)
                        .fontWeight(selectedRange == range ? .bold : .medium)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(selectedRange == range ? lineColor.opacity(0.18) : Color.theme.secondaryText.opacity(0.08))
                        )
                        .overlay(
                            Capsule()
                                .stroke(selectedRange == range ? lineColor : Color.clear, lineWidth: 1.5)
                        )
                        .foregroundStyle(selectedRange == range ? lineColor : Color.theme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private var chartContent: some View {
        if points.count > 1 {
            Chart {
                // Gradient Area Fill
                ForEach(points) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        yStart: .value("Base", domainMinY),
                        yEnd: .value("Price", point.price)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [lineColor.opacity(0.35), lineColor.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Primary Price Line
                ForEach(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(lineColor)
                }
                
                // Scrubbing Cursor Indicator
                if let scrub = scrubbedPoint {
                    RuleMark(x: .value("Scrub Date", scrub.date))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.75))
                    
                    PointMark(
                        x: .value("Scrub Date", scrub.date),
                        y: .value("Scrub Price", scrub.price)
                    )
                    .symbol {
                        Circle()
                            .fill(lineColor)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2.5)
                            )
                            .shadow(color: lineColor.opacity(0.8), radius: 6)
                    }
                }
            }
            .chartYScale(domain: domainMinY...domainMaxY)
            .chartXSelection(value: $selectedDate)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.8))
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.12))
                    
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(doubleValue.formattedWithAbbreviations())
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.theme.secondaryText.opacity(0.85))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.8))
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.08))
                    
                    AxisValueLabel {
                        if let dateValue = value.as(Date.self) {
                            Text(formatDateForAxis(dateValue))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.theme.secondaryText)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.35), value: points)
        } else {
            ZStack {
                Color.theme.secondaryText.opacity(0.04)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                ProgressView()
                    .scaleEffect(1.1)
            }
        }
    }
    
    private func formatDateForAxis(_ date: Date) -> String {
        switch selectedRange {
        case .day:
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        case .week, .month:
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        case .year, .all:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yy"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    ChartView(coin: DeveloperPreview.instance.coin)
}
