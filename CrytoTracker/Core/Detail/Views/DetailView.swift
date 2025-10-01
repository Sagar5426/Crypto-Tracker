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
    
    init(coin: CoinModel) {
        self._vm = StateObject(wrappedValue: DetailViewModel(coin: coin))
        print("Initialized DetailView for: \(coin.name) (\(coin.symbol))")
    }
    
    var body: some View {
        
        Text("Hello")
    }
}

#Preview {
    DetailView(coin:DeveloperPreview.instance.coin)
}
