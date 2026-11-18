//
//  MainTabView.swift
//  CoinPilot
//
//  Created by Antigravity on 14/11/2026.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var vm: MarketViewModel
    @State private var selectedTab: AppTab = .markets
    
    enum AppTab: Int, CaseIterable, Identifiable {
        case markets = 0
        case portfolio = 1
        case watchlist = 2
        case settings = 3
        
        var id: Int { rawValue }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MarketView()
                .tabItem {
                    Label("Markets", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppTab.markets)
            
            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: "briefcase.fill")
                }
                .tag(AppTab.portfolio)
            
            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "star.fill")
                }
                .tag(AppTab.watchlist)
            
            SettingsView(showsDismissButton: false)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tint(Color.theme.accent)
        .dynamicTypeSize(.large)
    }
}

#Preview {
    MainTabView()
        .environmentObject(DeveloperPreview.instance.homeVM)
}
