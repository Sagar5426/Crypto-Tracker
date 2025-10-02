//
//  DetailView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 30/09/2025.
//

import SwiftUI

// Just Created this DetailedLoadingView to handle and clean the logic of unwrapping @binding optional CoinModel
struct DetailLoadingView : View {
    @Binding var coin: CoinModel?
    
    var body: some View {
        ZStack {
            if let coin = coin {
                DetailView(coin: coin)
            }
        }
    }
}

struct DetailView: View {
    @StateObject var vm: DetailViewModel
    private let columns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]
    private let spacing: CGFloat = 20.0
    
    init(coin: CoinModel) {
        self._vm = StateObject(wrappedValue: DetailViewModel(coin: coin))
        print("Initialized DetailView for: \(coin.name) (\(coin.symbol))")
    }
    
    var body: some View {
        
        ScrollView {
            VStack(spacing: 20) {
                Text("dsad")
                    .frame(height: 150)
                OverviewTitle
                Divider()
                overviewGrid
                
                additionalTitle
                Divider()
                additionalGrid
            }
        }
        .navigationTitle(vm.coin.name)
        
    }
}

#Preview {
    NavigationStack {
        DetailView(coin:DeveloperPreview.instance.coin)
    }
}

extension DetailView {
    private var OverviewTitle: some View {
        Text("Overview")
            .font(.title).bold()
            .foregroundStyle(Color.theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
    }
    
    private var additionalTitle : some View {
        Text("Additional Details")
            .font(.title).bold()
            .foregroundStyle(Color.theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
    }
    
    private var overviewGrid : some View {
        LazyVGrid(columns: columns,
                  alignment: .leading,
                  spacing: spacing,
                  pinnedViews: []) {
            ForEach(vm.overviewStatistics) { stat in
                StatisticsView(stat: stat)
            }
        }.padding(.horizontal)
    }
    
    private var additionalGrid: some View {
        LazyVGrid(columns: columns,
                  alignment: .leading,
                  spacing: spacing,
                  pinnedViews: []) {
            ForEach(vm.additionalStatistics) { stat in
                StatisticsView(stat: stat)
            }
        }
                  .padding(.horizontal)
    }
}
