//
//  HomeViewModel.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 03/08/2025.
//
import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var allCoins: [CoinModel] = []
    @Published var portfolioCoins: [CoinModel] = []
    
    private let dataService = CoinDataService()
    private var cancellables = Set<AnyCancellable>()
    
    
    init() {
        addSubscribers()
        }
    
    func addSubscribers() {
        dataService.$allCoins
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (returnedCoins) in
                self?.allCoins = returnedCoins
            }
            .store(in: &cancellables)
        
    }
    }
