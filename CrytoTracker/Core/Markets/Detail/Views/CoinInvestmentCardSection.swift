//
//  CoinInvestmentCardSection.swift
//  CrytoTracker
//
//  Created by Antigravity on 15/11/2026.
//

import SwiftUI

struct CoinInvestmentCardSection: View {
    let coin: CoinModel
    var onViewBreakdownTapped: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader
            
            CoinInvestmentCard(
                coin: coin,
                onViewBreakdownTapped: onViewBreakdownTapped
            )
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
        Color.theme.background.ignoresSafeArea()
        CoinInvestmentCardSection(
            coin: DeveloperPreview.instance.coin,
            onViewBreakdownTapped: {}
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Coin Investment Card Section - Loss (Dark)") {
    ZStack {
        Color.theme.background.ignoresSafeArea()
        CoinInvestmentCardSection(
            coin: DeveloperPreview.instance.adaCoin,
            onViewBreakdownTapped: {}
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Coin Investment Card Section - Light Mode") {
    ZStack {
        Color.theme.background.ignoresSafeArea()
        CoinInvestmentCardSection(
            coin: DeveloperPreview.instance.coin,
            onViewBreakdownTapped: {}
        )
        .padding()
    }
    .preferredColorScheme(.light)
}
