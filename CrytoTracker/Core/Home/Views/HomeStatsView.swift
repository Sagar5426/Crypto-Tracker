//
//  HomeStatView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 27/09/2025.
//

import SwiftUI

struct HomeStatsView: View {
    @EnvironmentObject var vm: HomeViewModel
    @Binding var showPortfolio: Bool
    
    var body: some View {
        HStack {
            ForEach(vm.statistics) { stat in
                // Adjust only the portfolio percentage if it's been provided as a ratio (e.g., 0.0107) instead of percent (1.07)
                let displayStat: StatisticModel = {
                    if stat.title == "Portfolio Value", let pct = stat.percentageChange {
                        // Multiply by 100 to convert ratio to percent for display
                        return StatisticModel(title: stat.title, value: stat.value, percentageChange: pct * 100)
                    } else {
                        return stat
                    }
                }()
                StatisticsView(stat: displayStat)
                    .frame(width: UIScreen.main.bounds.width/3)
            }
        }
        .frame(width: UIScreen.main.bounds.width,
               alignment: showPortfolio ? .trailing : .leading)
    }
}

#Preview {
    HomeStatsView(showPortfolio: .constant(false))
        .environmentObject(DeveloperPreview.instance.homeVM)
}
