//
//  StatisticsView.swift
//  CoinPilot
//
//  Created by Sagar Jangra on 27/09/2025.
//

import SwiftUI

struct StatisticsView: View {
    let stat: StatisticModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stat.title)
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                .lineLimit(1)
            Text(stat.value)
                .font(.headline)
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            HStack(spacing: 4) {
                Image(systemName: "triangle.fill")
                    .font(.caption2)
                    .rotationEffect(
                        Angle(degrees: (stat.percentageChange ?? 0) >= 0 ? 0 : 180)
                    )
                
                Text(stat.percentageChange?.asPercentString() ?? "")
                    .font(.caption)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle((stat.percentageChange ?? 0) >= 0 ? Color.theme.green : Color.theme.red)
            .opacity(stat.percentageChange == nil ? 0 : 1)
        }
    }
}

#Preview {
        HStack(spacing: 10) {
            StatisticsView(stat: DeveloperPreview.instance.stat1)
            StatisticsView(stat: DeveloperPreview.instance.stat2)
            StatisticsView(stat: DeveloperPreview.instance.stat3)
        }
}
