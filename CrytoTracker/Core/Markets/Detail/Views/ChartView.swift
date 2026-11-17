//
//  ChartView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 02/10/2025.
//

import SwiftUI
import Charts

@MainActor
struct ChartView: View {
    @StateObject private var viewModel: ChartViewModel
    
    init(coin: CoinModel, viewModel: ChartViewModel? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel ?? ChartViewModel(coin: coin))
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
        .onChange(of: viewModel.selectedDate) { oldValue, newValue in
            viewModel.onScrubDateChanged(oldValue: oldValue, newValue: newValue)
        }
    }
}

// MARK: - Subviews & Components
extension ChartView {
    
    private var chartHeaderView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.activePrice.asCurrencyWith6Decimals())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                    .contentTransition(.numericText())
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.85)
                }
            }
            
            HStack(spacing: 6) {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 8))
                    .rotationEffect(Angle(degrees: viewModel.priceDifference >= 0 ? 0 : 180))
                
                Text(viewModel.priceDifference >= 0 ? "+" : "")
                + Text(viewModel.priceDifference.asCurrencyWith2Decimals())
                + Text(" (\(viewModel.percentageChange.asPercentString()))")
                
                if let scrub = viewModel.scrubbedPoint {
                    Text("• \(scrub.date.asMediumDateTimeString())")
                        .foregroundStyle(Color.theme.secondaryText)
                } else {
                    Text("• \(viewModel.selectedRange.title)")
                        .foregroundStyle(Color.theme.secondaryText)
                }
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(viewModel.lineColor)
        }
    }
    
    private var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(ChartTimeRange.allCases) { range in
                Button {
                    viewModel.selectRange(range)
                } label: {
                    Text(range.rawValue)
                        .font(.caption)
                        .fontWeight(viewModel.selectedRange == range ? .bold : .medium)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedRange == range ? viewModel.lineColor.opacity(0.18) : Color.theme.secondaryText.opacity(0.08))
                        )
                        .overlay(
                            Capsule()
                                .stroke(viewModel.selectedRange == range ? viewModel.lineColor : Color.clear, lineWidth: 1.5)
                        )
                        .foregroundStyle(viewModel.selectedRange == range ? viewModel.lineColor : Color.theme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private var chartContent: some View {
        if viewModel.points.count > 1 {
            Chart {
                // Gradient Area Fill
                ForEach(viewModel.points) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        yStart: .value("Base", viewModel.domainMinY),
                        yEnd: .value("Price", point.price)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [viewModel.lineColor.opacity(0.35), viewModel.lineColor.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Primary Price Line
                ForEach(viewModel.points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price)
                    )
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(viewModel.lineColor)
                }
                
                // Scrubbing Cursor Indicator
                if let scrub = viewModel.scrubbedPoint {
                    RuleMark(x: .value("Scrub Date", scrub.date))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.75))
                    
                    PointMark(
                        x: .value("Scrub Date", scrub.date),
                        y: .value("Scrub Price", scrub.price)
                    )
                    .symbol {
                        Circle()
                            .fill(viewModel.lineColor)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2.5)
                            )
                            .shadow(color: viewModel.lineColor.opacity(0.8), radius: 6)
                    }
                }
            }
            .chartYScale(domain: viewModel.domainMinY...viewModel.domainMaxY)
            .chartXSelection(value: $viewModel.selectedDate)
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
            .animation(.easeInOut(duration: 0.35), value: viewModel.points)
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
        switch viewModel.selectedRange {
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
