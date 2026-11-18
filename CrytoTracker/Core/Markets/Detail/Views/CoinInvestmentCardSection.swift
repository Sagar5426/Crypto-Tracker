//
//  CoinInvestmentCardSection.swift
//  CoinPilot
//
//  Created by Antigravity on 15/11/2026.
//

import SwiftUI

struct CoinInvestmentCardSection: View {
    @EnvironmentObject private var homeVM: MarketViewModel
    let coin: CoinModel
    var onViewBreakdownTapped: (() -> Void)? = nil
    
    @State private var showBreakdownSheet: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader
            
            CoinInvestmentCard(
                coin: coin,
                onViewBreakdownTapped: {
                    if let onViewBreakdownTapped {
                        onViewBreakdownTapped()
                    } else {
                        showBreakdownSheet = true
                        HapticManager.notification(type: .success)
                    }
                }
            )
        }
        .sheet(isPresented: $showBreakdownSheet) {
            CoinInvestmentBreakdownView(coin: coin)
                .environmentObject(homeVM)
        }
    }
    
    private var sectionHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "briefcase.fill")
                .font(.subheadline)
                .foregroundStyle(Color.theme.accent)
            
            Text("Investment")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
        }
        .padding(.top, 4)
    }
}

// MARK: - Previews
#Preview("Coin Investment Card Section - Profitable (Dark)") {
    ZStack {
        Color.theme.screenBackground.ignoresSafeArea()
        CoinInvestmentCardSection(
            coin: DeveloperPreview.instance.coin
        )
        .padding()
    }
    .environmentObject(DeveloperPreview.instance.homeVM)
    .preferredColorScheme(.dark)
}

#Preview("Coin Investment Card Section - Loss (Dark)") {
    ZStack {
        Color.theme.screenBackground.ignoresSafeArea()
        CoinInvestmentCardSection(
            coin: DeveloperPreview.instance.adaCoin
        )
        .padding()
    }
    .environmentObject(DeveloperPreview.instance.homeVM)
    .preferredColorScheme(.dark)
}

#Preview("Coin Investment Card Section - Light Mode") {
    ZStack {
        Color.theme.screenBackground.ignoresSafeArea()
        CoinInvestmentCardSection(
            coin: DeveloperPreview.instance.coin
        )
        .padding()
    }
    .environmentObject(DeveloperPreview.instance.homeVM)
    .preferredColorScheme(.light)
}
