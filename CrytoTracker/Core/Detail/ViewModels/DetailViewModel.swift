//
//  DetailViewModel.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 01/10/2025.
//

import SwiftUI
import Combine

class DetailViewModel: ObservableObject {
    private let coinDetailService: CoinDetailDataService
    private var cancellables = Set<AnyCancellable>()
    
    init(coin: CoinModel) {
        coinDetailService = CoinDetailDataService(coin: coin)
        self.addSubscribers()
    }
    
    private func addSubscribers() {
        coinDetailService.$coinDetails
            .sink { [weak self] (returnedCoinDetails) in
                print("Received coin detail data: \(returnedCoinDetails)")
            }
            .store(in: &cancellables)
        
    }
}

