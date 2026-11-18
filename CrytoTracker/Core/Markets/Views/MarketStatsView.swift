//
//  HomeStatsView.swift
//  CoinPilot
//
//  Created by Sagar Jangra on 27/09/2025.
//

import SwiftUI

struct MarketStatsView: View {
    @EnvironmentObject var vm: MarketViewModel
    @Binding var showPortfolio: Bool
    
    private var marketStats: [StatisticModel] {
        Array(vm.statistics.prefix(3))
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(marketStats) { stat in
                StatisticsView(stat: stat)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if stat.id != marketStats.last?.id {
                    Divider()
                        .frame(height: 32)
                        .background(Color.theme.secondaryText.opacity(0.15))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.05), radius: 8, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

#Preview {
    MarketStatsView(showPortfolio: .constant(false))
        .environmentObject(DeveloperPreview.instance.homeVM)
}
