//
//  ChartView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 02/10/2025.
//

import SwiftUI

struct ChartView: View {
    
    let coin: CoinModel
    @StateObject private var chartService: MarketChartDataService
    @State private var selectedRange: ChartTimeRange = .week
    @State private var percentage: CGFloat = 0
    @State private var scrubbedPoint: ChartPoint? = nil
    @State private var scrubLocationX: CGFloat? = nil
    
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
    
    private var maxY: Double {
        prices.max() ?? (coin.currentPrice * 1.05)
    }
    
    private var minY: Double {
        prices.min() ?? (coin.currentPrice * 0.95)
    }
    
    private var startingPrice: Double {
        prices.first ?? coin.currentPrice
    }
    
    private var activePrice: Double {
        scrubbedPoint?.price ?? (prices.last ?? coin.currentPrice)
    }
    
    private var priceDifference: Double {
        activePrice - startingPrice
    }
    
    private var percentageChange: Double {
        guard startingPrice > 0 else { return 0 }
        return (priceDifference / startingPrice) * 100
    }
    
    private var lineColor: Color {
        priceDifference >= 0 ? Color.theme.green : Color.theme.red
    }
    
    private var startingDate: Date {
        points.first?.date ?? Date().addingTimeInterval(-7 * 24 * 3600)
    }
    
    private var endingDate: Date {
        points.last?.date ?? Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            chartHeaderView
            
            timeRangePicker
            
            VStack(spacing: 8) {
                chartContainer
                    .frame(height: 220)
                
                chartDateLabels
            }
        }
        .padding(.horizontal)
        .onAppear {
            animateChart()
        }
        .onChange(of: chartService.chartPoints) { _, _ in
            animateChart()
        }
    }
    
    private func animateChart() {
        percentage = 0
        withAnimation(.easeOut(duration: 1.2)) {
            percentage = 1
        }
    }
}

// MARK: - Subviews
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
                        .scaleEffect(0.8)
                }
            }
            
            HStack(spacing: 6) {
                Image(systemName: priceDifference >= 0 ? "triangle.fill" : "triangle.fill")
                    .font(.caption2)
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
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedRange = range
                        scrubbedPoint = nil
                        scrubLocationX = nil
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
        .padding(.vertical, 4)
    }
    
    private var chartContainer: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                chartGridBackground
                
                chartYAxisLabels
                
                if prices.count > 1 {
                    chartFillArea(geometry: geometry)
                    chartStrokeLine(geometry: geometry)
                    
                    if let scrubX = scrubLocationX, let scrubPoint = scrubbedPoint {
                        chartScrubOverlay(geometry: geometry, xPosition: scrubX, point: scrubPoint)
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDrag(at: value.location, in: geometry)
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrubbedPoint = nil
                            scrubLocationX = nil
                        }
                    }
            )
        }
    }
    
    private func handleDrag(at location: CGPoint, in geometry: GeometryProxy) {
        guard prices.count > 1 else { return }
        let clampedX = min(max(0, location.x), geometry.size.width)
        let step = geometry.size.width / CGFloat(points.count - 1)
        let rawIndex = Int(round(clampedX / step))
        let clampedIndex = min(max(0, rawIndex), points.count - 1)
        
        let newPoint = points[clampedIndex]
        if scrubbedPoint?.id != newPoint.id {
            HapticManager.notification(type: .warning)
        }
        scrubbedPoint = newPoint
        scrubLocationX = CGFloat(clampedIndex) * step
    }
    
    private func chartStrokeLine(geometry: GeometryProxy) -> some View {
        Path { path in
            guard prices.count > 1 else { return }
            let yRange = max(maxY - minY, 0.000001)
            let stepX = geometry.size.width / CGFloat(prices.count - 1)
            
            for index in prices.indices {
                let xPos = CGFloat(index) * stepX
                let yPos = (1.0 - CGFloat((prices[index] - minY) / yRange)) * geometry.size.height
                
                if index == 0 {
                    path.move(to: CGPoint(x: xPos, y: yPos))
                } else {
                    path.addLine(to: CGPoint(x: xPos, y: yPos))
                }
            }
        }
        .trim(from: 0, to: percentage)
        .stroke(lineColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        .shadow(color: lineColor.opacity(0.4), radius: 8, x: 0, y: 6)
    }
    
    private func chartFillArea(geometry: GeometryProxy) -> some View {
        Path { path in
            guard prices.count > 1 else { return }
            let yRange = max(maxY - minY, 0.000001)
            let stepX = geometry.size.width / CGFloat(prices.count - 1)
            let height = geometry.size.height
            
            path.move(to: CGPoint(x: 0, y: height))
            for index in prices.indices {
                let xPos = CGFloat(index) * stepX
                let yPos = (1.0 - CGFloat((prices[index] - minY) / yRange)) * height
                path.addLine(to: CGPoint(x: xPos, y: yPos))
            }
            path.addLine(to: CGPoint(x: geometry.size.width, y: height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [lineColor.opacity(0.35), lineColor.opacity(0.01)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .opacity(percentage)
    }
    
    private func chartScrubOverlay(geometry: GeometryProxy, xPosition: CGFloat, point: ChartPoint) -> some View {
        let yRange = max(maxY - minY, 0.000001)
        let yPos = (1.0 - CGFloat((point.price - minY) / yRange)) * geometry.size.height
        
        return ZStack {
            // Vertical cursor line
            Path { path in
                path.move(to: CGPoint(x: xPosition, y: 0))
                path.addLine(to: CGPoint(x: xPosition, y: geometry.size.height))
            }
            .stroke(Color.theme.secondaryText.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            
            // Indicator Dot on line
            Circle()
                .fill(lineColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: lineColor.opacity(0.8), radius: 6)
                .position(x: xPosition, y: yPos)
        }
    }
    
    private var chartGridBackground: some View {
        VStack {
            Divider()
                .background(Color.theme.secondaryText.opacity(0.15))
            Spacer()
            Divider()
                .background(Color.theme.secondaryText.opacity(0.1))
            Spacer()
            Divider()
                .background(Color.theme.secondaryText.opacity(0.15))
        }
    }
    
    private var chartYAxisLabels: some View {
        VStack(alignment: .leading) {
            Text(maxY.formattedWithAbbreviations())
            Spacer()
            Text(((maxY + minY) / 2).formattedWithAbbreviations())
            Spacer()
            Text(minY.formattedWithAbbreviations())
        }
        .font(.system(size: 10, weight: .semibold, design: .monospaced))
        .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
        .padding(.horizontal, 4)
    }
    
    private var chartDateLabels: some View {
        HStack {
            Text(startingDate.asDayMonthYearString())
            Spacer()
            if let scrub = scrubbedPoint {
                Text(scrub.date.asDayMonthYearString())
                    .fontWeight(.bold)
                    .foregroundStyle(lineColor)
                Spacer()
            }
            Text(endingDate.asDayMonthYearString())
        }
        .font(.caption2)
        .foregroundStyle(Color.theme.secondaryText)
    }
}

#Preview {
    ChartView(coin: DeveloperPreview.instance.coin)
}
