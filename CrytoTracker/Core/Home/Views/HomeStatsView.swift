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
            ForEach(vm.statistics) {
                StatisticsView(stat: $0)
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
