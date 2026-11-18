//
//  DetailViewModel.swift
//  CoinPilot
//
//  Created by Sagar Jangra on 01/10/2025.
//

import SwiftUI
import Combine

@MainActor
final class DetailViewModel: ObservableObject {
    
    // MARK: - Published Coin & Detail Properties
    
    @Published var coin: CoinModel
    @Published var overviewStatistics: [StatisticModel] = []
    @Published var additionalStatistics: [StatisticModel] = []
    @Published var coinDescription: String? = nil
    @Published var websiteURL: String? = nil
    @Published var redditURL: String? = nil
    
    // MARK: - Published UI & Flow States
    
    @Published var showFullDescription: Bool = false
    @Published var showPortfolioSheet: Bool = false
    @Published var tradeTypeToOpen: TransactionType = .buy
    @Published var isWatchlisted: Bool = false
    @Published var userHoldingCoin: CoinModel? = nil
    
    // MARK: - Services & Dependencies
    
    private let coinDetailService: CoinDetailDataService
    private(set) weak var marketViewModel: MarketViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(coin: CoinModel, marketViewModel: MarketViewModel? = nil) {
        self.coin = coin
        self.coinDetailService = CoinDetailDataService(coin: coin)
        self.addSubscribers()
        
        if let vm = marketViewModel {
            setMarketViewModel(vm)
        }
    }
    
    // MARK: - MarketViewModel Binding
    
    func setMarketViewModel(_ vm: MarketViewModel) {
        guard self.marketViewModel !== vm else { return }
        self.marketViewModel = vm
        
        self.isWatchlisted = vm.isWatchlisted(coin: coin)
        self.userHoldingCoin = vm.portfolioCoins.first(where: { $0.id == coin.id })
        
        // Reactively watch for live updates to watchlist
        vm.$watchlistCoinIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                guard let self = self else { return }
                self.isWatchlisted = ids.contains(self.coin.id)
            }
            .store(in: &cancellables)
        
        // Reactively watch for changes in portfolio holdings for this coin
        vm.$portfolioCoins
            .receive(on: DispatchQueue.main)
            .sink { [weak self] portfolio in
                guard let self = self else { return }
                self.userHoldingCoin = portfolio.first(where: { $0.id == self.coin.id })
            }
            .store(in: &cancellables)
        
        // Reactively update coin price/data if updated live in allCoins
        vm.$allCoins
            .receive(on: DispatchQueue.main)
            .sink { [weak self] allCoins in
                guard let self = self,
                      let updatedCoin = allCoins.first(where: { $0.id == self.coin.id }) else { return }
                self.coin = updatedCoin
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Domain Properties
    
    var userHasHoldings: Bool {
        if let holding = userHoldingCoin {
            return (holding.currentHoldings ?? 0) > 0
        }
        return false
    }
    
    var availableHoldingsSubtitle: String {
        if let holding = userHoldingCoin, let qty = holding.currentHoldings, qty > 0 {
            return "\(qty.asNumberString()) \(coin.symbol.uppercased())"
        }
        return "Manage Position"
    }
    
    var priceRangeProgress: CGFloat {
        guard let high = coin.high24H, let low = coin.low24H, high > low else { return 0.5 }
        let range = max(high - low, 0.0001)
        return min(max(CGFloat((coin.currentPrice - low) / range), 0), 1)
    }
    
    // MARK: - Intent Actions
    
    func toggleWatchlist() {
        withAnimation {
            marketViewModel?.toggleWatchlist(coin: coin)
        }
    }
    
    func openTrade(type: TransactionType) {
        tradeTypeToOpen = type
        showPortfolioSheet = true
        HapticManager.impact(style: .medium)
    }
    
    func toggleDescription() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showFullDescription.toggle()
        }
    }
    
    // MARK: - Subscribers & Statistics Mapping
    
    private func addSubscribers() {
        coinDetailService.$coinDetails
            .combineLatest($coin)
            .map(mapDataToStatistics)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] returnedArrays in
                self?.overviewStatistics = returnedArrays.overview
                self?.additionalStatistics = returnedArrays.additional
            }
            .store(in: &cancellables)
        
        // Subscribing to get links and description
        coinDetailService.$coinDetails
            .receive(on: DispatchQueue.main)
            .sink { [weak self] returnedCoinDetails in
                self?.coinDescription = returnedCoinDetails?.readableDescription
                self?.websiteURL = returnedCoinDetails?.links?.homepage?.first
                self?.redditURL = returnedCoinDetails?.links?.subredditURL
            }
            .store(in: &cancellables)
    }
    
    private func mapDataToStatistics(coinDetailModel: CoinDetailModel?, coinModel: CoinModel) -> (overview: [StatisticModel], additional: [StatisticModel]) {
        let overview = createOverviewStatistics(from: coinModel)
        let additional = createAdditionalStatistics(from: coinDetailModel, coin: coinModel)
        return (overview, additional)
    }

    private func createOverviewStatistics(from coin: CoinModel) -> [StatisticModel] {
        let price = coin.currentPrice.asCurrencyWith6Decimals()
        let pricePercentChange = coin.priceChangePercentage24H
        let priceStat = StatisticModel(title: "Current Price", value: price, percentageChange: pricePercentChange)
        
        let marketCap = "$" + (coin.marketCap?.formattedWithAbbreviations() ?? "")
        let marketCapPercentChange = coin.marketCapChangePercentage24H
        let marketCapStat = StatisticModel(title: "Market Cap", value: marketCap, percentageChange: marketCapPercentChange)
        
        let rank = "\(coin.rank)"
        let rankStat = StatisticModel(title: "Rank", value: rank)
        
        let volume = "$" + (coin.totalVolume?.formattedWithAbbreviations() ?? "")
        let volumeStat = StatisticModel(title: "24h Volume", value: volume)
        
        return [priceStat, marketCapStat, rankStat, volumeStat]
    }

    private func createAdditionalStatistics(from coinDetail: CoinDetailModel?, coin: CoinModel) -> [StatisticModel] {
        let high = coin.high24H?.asCurrencyWith6Decimals() ?? "n/a"
        let highStat = StatisticModel(title: "24h High", value: high)
        
        let low = coin.low24H?.asCurrencyWith6Decimals() ?? "n/a"
        let lowStat = StatisticModel(title: "24h Low", value: low)
        
        let priceChange = coin.priceChange24H?.asFormattedPrice() ?? "n/a"
        let pricePercentChange2 = coin.priceChangePercentage24H
        let priceChangeStat = StatisticModel(title: "24h Price Change", value: priceChange, percentageChange: pricePercentChange2)
        
        let marketCapChange = "$" + (coin.marketCapChange24H?.formattedWithAbbreviations() ?? "")
        let marketCapPercentChange2 = coin.marketCapChangePercentage24H
        let marketCapChangeStat = StatisticModel(title: "24h Market Cap Change", value: marketCapChange, percentageChange: marketCapPercentChange2)
        
        let blockTime = coinDetail?.blockTimeInMinutes ?? 0
        let blockTimeString = blockTime == 0 ? "n/a" : "\(blockTime)"
        let blockStat = StatisticModel(title: "Block Time", value: blockTimeString)
        
        let hashing = coinDetail?.hashingAlgorithm ?? "n/a"
        let hashingStat = StatisticModel(title: "Hashing Algorithm", value: hashing)
        
        return [highStat, lowStat, priceChangeStat, marketCapChangeStat, blockStat, hashingStat]
    }
}

/// Convenience backward-compatibility alias
typealias CoinDetailViewModel = DetailViewModel
