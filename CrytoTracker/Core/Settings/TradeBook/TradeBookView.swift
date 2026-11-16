//
//  TradeBookView.swift
//  CrytoTracker
//
//  Created by Antigravity on 16/11/2026.
//

import SwiftUI

/// Main TradeBook view that tracks all buy and sell trade orders executed in the application.
struct TradeBookView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: MarketViewModel
    
    // MARK: - State Properties
    @State private var searchText: String = ""
    @State private var selectedFilter: TradeFilterType = .all
    @State private var sortOption: TradeSortOption = .newest
    @State private var selectedCoinFilter: String? = nil
    @State private var isSpinning: Bool = false
    
    // Sheets & Dialogs
    @State private var selectedTradeForDetail: TransactionEntity? = nil
    @State private var tradeToEdit: TransactionEntity? = nil
    @State private var showAddTradeSheet: Bool = false
    @State private var tradeToDelete: TransactionEntity? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var selectedCoinForDetail: CoinModel? = nil
    
    // MARK: - Filter & Sort Enums
    enum TradeFilterType: String, CaseIterable, Identifiable {
        case all = "All"
        case buys = "Buys"
        case sells = "Sells"
        
        var id: String { rawValue }
    }
    
    enum TradeSortOption: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case highestValue = "Highest Value"
        case lowestValue = "Lowest Value"
        case largestAmount = "Largest Quantity"
        
        var id: String { rawValue }
    }
    
    // MARK: - Computed Trades Data
    
    /// All crypto buy and sell trades (excluding cash deposits and withdrawals)
    private var cryptoTrades: [TransactionEntity] {
        vm.transactions.filter {
            let type = ($0.transactionType ?? "").uppercased()
            return ($0.coinID ?? "") != "usd-cash" && (type == "BUY" || type == "SELL")
        }
    }
    
    /// Unique coin symbols found in trades (for horizontal coin filter pills)
    private var uniqueTradedCoins: [(symbol: String, name: String, count: Int)] {
        var counts: [String: (name: String, count: Int)] = [:]
        for tx in cryptoTrades {
            let symbol = (tx.coinSymbol ?? "").uppercased()
            let name = tx.coinName ?? symbol
            if !symbol.isEmpty {
                let existing = counts[symbol] ?? (name: name, count: 0)
                counts[symbol] = (name: existing.name, count: existing.count + 1)
            }
        }
        return counts.map { ($0.key, $0.value.name, $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    
    /// Filtered and sorted trade orders list
    private var filteredTrades: [TransactionEntity] {
        var list = cryptoTrades
        
        // 1. Filter by Trade Type
        switch selectedFilter {
        case .all:
            break
        case .buys:
            list = list.filter { ($0.transactionType ?? "").uppercased() == "BUY" }
        case .sells:
            list = list.filter { ($0.transactionType ?? "").uppercased() == "SELL" }
        }
        
        // 2. Filter by Coin Symbol Chip
        if let coinSymbol = selectedCoinFilter {
            list = list.filter { ($0.coinSymbol ?? "").uppercased() == coinSymbol.uppercased() }
        }
        
        // 3. Search Query
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter {
                ($0.coinName ?? "").lowercased().contains(query) ||
                ($0.coinSymbol ?? "").lowercased().contains(query)
            }
        }
        
        // 4. Sort
        switch sortOption {
        case .newest:
            list.sort { ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) }
        case .oldest:
            list.sort { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
        case .highestValue:
            list.sort { $0.totalValue > $1.totalValue }
        case .lowestValue:
            list.sort { $0.totalValue < $1.totalValue }
        case .largestAmount:
            list.sort { $0.amount > $1.amount }
        }
        
        return list
    }
    
    // MARK: - Metrics Calculations
    
    private var buyTrades: [TransactionEntity] {
        cryptoTrades.filter { ($0.transactionType ?? "").uppercased() == "BUY" }
    }
    
    private var sellTrades: [TransactionEntity] {
        cryptoTrades.filter { ($0.transactionType ?? "").uppercased() == "SELL" }
    }
    
    private var totalVolume: Double {
        cryptoTrades.map { $0.totalValue }.reduce(0, +)
    }
    
    private var totalBuyVolume: Double {
        buyTrades.map { $0.totalValue }.reduce(0, +)
    }
    
    private var totalSellVolume: Double {
        sellTrades.map { $0.totalValue }.reduce(0, +)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.theme.background
                .ignoresSafeArea()
            
            // Ambient trade glow background
            ambientGlowBackground
            
            VStack(spacing: 0) {
                // Top Custom Header
                topBar
                
                if cryptoTrades.isEmpty {
                    emptyTradeBookView
                } else {
                    mainScrollView
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Delete Trade", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let tx = tradeToDelete {
                    HapticManager.notification(type: .success)
                    withAnimation {
                        vm.deleteTransaction(tx)
                    }
                }
                tradeToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                tradeToDelete = nil
            }
        } message: {
            if let tx = tradeToDelete {
                Text("Are you sure you want to delete this \((tx.transactionType ?? "TRADE").uppercased()) of \(tx.amount.asNumberString()) \(tx.coinSymbol?.uppercased() ?? "")? This will automatically recalculate your portfolio.")
            } else {
                Text("Are you sure you want to delete this trade? This will automatically recalculate your portfolio.")
            }
        }
        .sheet(item: $selectedTradeForDetail) { trade in
            NavigationStack {
                TradeReceiptDetailSheet(
                    trade: trade,
                    onEdit: {
                        selectedTradeForDetail = nil
                        tradeToEdit = trade
                    },
                    onDelete: {
                        selectedTradeForDetail = nil
                        tradeToDelete = trade
                        showDeleteConfirmation = true
                    },
                    onViewCoin: { coin in
                        selectedTradeForDetail = nil
                        selectedCoinForDetail = coin
                    }
                )
            }
        }
        .sheet(isPresented: $showAddTradeSheet) {
            NavigationStack {
                TradeEditSheet(mode: .new) { coin, type, amount, price, date in
                    vm.updateTransactionAndRecalculate(
                        id: UUID().uuidString,
                        coin: coin,
                        type: type,
                        amount: amount,
                        pricePerCoin: price,
                        timestamp: date
                    )
                }
            }
        }
        .sheet(item: $tradeToEdit) { trade in
            NavigationStack {
                TradeEditSheet(mode: .edit(trade)) { coin, type, amount, price, date in
                    vm.updateTransactionAndRecalculate(
                        id: trade.id ?? UUID().uuidString,
                        coin: coin,
                        type: type,
                        amount: amount,
                        pricePerCoin: price,
                        timestamp: date
                    )
                }
            }
        }
        .fullScreenCover(item: $selectedCoinForDetail) { coin in
            NavigationStack {
                CoinDetailView(coin: coin)
            }
        }
    }
}

// MARK: - Header & Ambient Subviews
extension TradeBookView {
    
    private var ambientGlowBackground: some View {
        LinearGradient(
            stops: [
                .init(color: Color.orange.opacity(0.10), location: 0.0),
                .init(color: Color.theme.accent.opacity(0.04), location: 0.25),
                .init(color: Color.clear, location: 0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            // Dismiss Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.theme.accent)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color.theme.secondaryText.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            
            // Title & Badge
            HStack(spacing: 8) {
                Text("TradeBook")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
                
                Text("\(cryptoTrades.count)")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(Color.orange)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            // Add Trade Button
            Button {
                HapticManager.selection()
                showAddTradeSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.theme.accent)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)
            
            // Refresh Button
            Button {
                HapticManager.notification(type: .success)
                withAnimation(.easeInOut(duration: 0.6)) {
                    isSpinning.toggle()
                }
                vm.reloadData()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.theme.accent)
                    .rotationEffect(.degrees(vm.isLoading || isSpinning ? 360 : 0))
                    .animation(
                        vm.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                        value: vm.isLoading
                    )
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color.theme.secondaryText.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}

// MARK: - Main Scroll Content
extension TradeBookView {
    
    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. Hero Summary Metrics Card
                metricsOverviewCard
                
                // 2. Search Bar
                SearchBarView(searchText: $searchText)
                    .padding(.top, -2)
                
                // 3. Filter Segment & Sort Row
                filterAndSortRow
                
                // 4. Horizontal Coin Filter Chips (if multiple coins traded)
                if uniqueTradedCoins.count > 1 {
                    coinFilterChipsRow
                }
                
                // 5. Trades List / Empty Filtered State
                if filteredTrades.isEmpty {
                    filteredEmptyStateView
                } else {
                    tradesListSection
                }
            }
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            vm.reloadData()
        }
    }
    
    // MARK: - Metrics Overview Card
    private var metricsOverviewCard: some View {
        VStack(spacing: 14) {
            // Top Row: Total Volume & Trade Count
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.orange)
                        
                        Text("TOTAL TRADING VOLUME")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.4)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    Text(totalVolume.asCurrencyWith2Decimals())
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("TOTAL TRADES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text("\(cryptoTrades.count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                }
            }
            
            // Buy vs Sell Split Bar
            volumeRatioBar
            
            // Metric Cards: Buys vs Sells
            HStack(spacing: 12) {
                // Buys Card
                metricSubCard(
                    title: "Total Buys",
                    countText: "\(buyTrades.count) Orders",
                    amountText: totalBuyVolume.asCurrencyWith2Decimals(),
                    color: Color.theme.green,
                    systemImage: "arrow.down.left.circle.fill"
                )
                
                // Sells Card
                metricSubCard(
                    title: "Total Sells",
                    countText: "\(sellTrades.count) Orders",
                    amountText: totalSellVolume.asCurrencyWith2Decimals(),
                    color: Color.theme.red,
                    systemImage: "arrow.up.right.circle.fill"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    private func metricSubCard(
        title: String,
        countText: String,
        amountText: String,
        color: Color,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                Text(countText)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }
            
            Text(amountText)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
    
    private var volumeRatioBar: some View {
        let buyRatio = totalVolume > 0 ? (totalBuyVolume / totalVolume) : 0.5
        let sellRatio = totalVolume > 0 ? (totalSellVolume / totalVolume) : 0.5
        
        return VStack(spacing: 4) {
            GeometryReader { geo in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.theme.green)
                        .frame(width: max(4, geo.size.width * CGFloat(buyRatio) - 1.5))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.theme.red)
                        .frame(width: max(4, geo.size.width * CGFloat(sellRatio) - 1.5))
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())
            
            HStack {
                Text("Buy: \(String(format: "%.1f%%", buyRatio * 100))")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.theme.green)
                
                Spacer()
                
                Text("Sell: \(String(format: "%.1f%%", sellRatio * 100))")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.theme.red)
            }
        }
    }
    
    // MARK: - Filter Segment & Sort Row
    private var filterAndSortRow: some View {
        HStack(spacing: 12) {
            // Type Filter Capsules
            HStack(spacing: 6) {
                ForEach(TradeFilterType.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 4) {
                            Text(filter.rawValue)
                                .font(.system(size: 12, weight: .bold))
                            
                            let count = countFor(filter: filter)
                            Text("(\(count))")
                                .font(.system(size: 10, weight: .semibold))
                                .opacity(0.8)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.orange : Color.theme.secondaryText.opacity(0.08))
                        )
                        .foregroundStyle(isSelected ? Color.white : Color.theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            // Sort Menu
            Menu {
                Picker("Sort Order", selection: $sortOption) {
                    ForEach(TradeSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11, weight: .bold))
                    Text(sortOption.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.theme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.theme.secondaryText.opacity(0.08))
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func countFor(filter: TradeFilterType) -> Int {
        switch filter {
        case .all: return cryptoTrades.count
        case .buys: return buyTrades.count
        case .sells: return sellTrades.count
        }
    }
    
    // MARK: - Coin Filter Chips Row
    private var coinFilterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All Coins" chip
                let isAllSelected = selectedCoinFilter == nil
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCoinFilter = nil
                    }
                    HapticManager.selection()
                } label: {
                    Text("All Coins")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(isAllSelected ? Color.theme.accent : Color.theme.secondaryText.opacity(0.08))
                        )
                        .foregroundStyle(isAllSelected ? Color.theme.background : Color.theme.secondaryText)
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)
                
                // Specific Coin Chips
                ForEach(uniqueTradedCoins, id: \.symbol) { item in
                    let isSelected = selectedCoinFilter == item.symbol
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedCoinFilter == item.symbol {
                                selectedCoinFilter = nil
                            } else {
                                selectedCoinFilter = item.symbol
                            }
                        }
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 4) {
                            Text(item.symbol)
                                .font(.system(size: 11, weight: .bold))
                            
                            Text("• \(item.count)")
                                .font(.system(size: 10, weight: .semibold))
                                .opacity(0.8)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.orange : Color.theme.secondaryText.opacity(0.08))
                        )
                        .foregroundStyle(isSelected ? Color.white : Color.theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, item.symbol == uniqueTradedCoins.last?.symbol ? 16 : 0)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Trades List Section
    private var tradesListSection: some View {
        LazyVStack(spacing: 10) {
            ForEach(filteredTrades, id: \.id) { trade in
                TradeRowCard(
                    trade: trade,
                    liveCoin: vm.allCoins.first { $0.id.lowercased() == (trade.coinID ?? "").lowercased() },
                    onTap: {
                        selectedTradeForDetail = trade
                    },
                    onEdit: {
                        tradeToEdit = trade
                    },
                    onDelete: {
                        tradeToDelete = trade
                        showDeleteConfirmation = true
                    }
                )
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Empty States
    private var emptyTradeBookView: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 40)
            
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 88, height: 88)
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.orange)
            }
            
            VStack(spacing: 6) {
                Text("TradeBook is Empty")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
                
                Text("Every coin buy and sell order executed in the app is automatically logged and analyzed here.")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                HapticManager.selection()
                showAddTradeSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Your First Trade")
                }
                .font(.headline)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.orange)
                .clipShape(Capsule())
                .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    private var filteredEmptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(Color.theme.secondaryText.opacity(0.6))
                .padding(.top, 32)
            
            Text("No Matching Trades")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Text("No transactions matched '\(searchText)' with the current filters.")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button {
                withAnimation {
                    searchText = ""
                    selectedFilter = .all
                    selectedCoinFilter = nil
                }
            } label: {
                Text("Reset Filters")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Trade Row Card View
struct TradeRowCard: View {
    let trade: TransactionEntity
    let liveCoin: CoinModel?
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var isBuy: Bool {
        (trade.transactionType ?? "").uppercased() == "BUY"
    }
    
    private var badgeColor: Color {
        isBuy ? Color.theme.green : Color.theme.red
    }
    
    private var executionDate: Date {
        trade.timestamp ?? Date()
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Main Row Content
                HStack(alignment: .center, spacing: 12) {
                    // Coin Icon / Badge
                    coinIconView
                    
                    // Left Column: Coin Name, Symbol & Type
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(trade.coinName ?? "Unknown")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.theme.accent)
                                .lineLimit(1)
                            
                            // BUY / SELL Badge
                            Text(isBuy ? "BUY" : "SELL")
                                .font(.system(size: 9.5, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(badgeColor.opacity(0.14))
                                .foregroundStyle(badgeColor)
                                .clipShape(Capsule())
                        }
                        
                        Text(executionDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Right Column: Quantity, Total & Price
                    VStack(alignment: .trailing, spacing: 3) {
                        // Total Trade Value
                        Text(trade.totalValue.asCurrencyWith2Decimals())
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.theme.accent)
                            .monospacedDigit()
                        
                        // Units & Unit Price
                        HStack(spacing: 4) {
                            Text((isBuy ? "+" : "-") + formatUnits(trade.amount) + " " + (trade.coinSymbol?.uppercased() ?? ""))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(badgeColor)
                            
                            Text("@ " + trade.pricePerCoin.asFormattedPrice())
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.theme.secondaryText)
                        }
                    }
                }
                
                // Live Market Context Bar (for BUY trades)
                if isBuy, let live = liveCoin, trade.pricePerCoin > 0 {
                    Divider()
                        .background(Color.theme.secondaryText.opacity(0.08))
                    
                    livePerformanceBar(currentPrice: live.currentPrice)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.theme.background)
                    .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onTap) {
                Label("View Trade Receipt", systemImage: "doc.text.magnifyingglass")
            }
            Button(action: onEdit) {
                Label("Edit Trade", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete Trade", systemImage: "trash")
            }
        }
    }
    
    private var coinIconView: some View {
        ZStack {
            Circle()
                .fill(Color.theme.secondaryText.opacity(0.08))
                .frame(width: 40, height: 40)
            
            if let coin = liveCoin {
                CoinImageView(coin: coin)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Text((trade.coinSymbol ?? "?").prefix(3).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.theme.accent)
            }
        }
    }
    
    private func livePerformanceBar(currentPrice: Double) -> some View {
        let diff = currentPrice - trade.pricePerCoin
        let diffPct = (diff / trade.pricePerCoin) * 100.0
        let totalGain = trade.amount * diff
        let isGain = diff >= 0
        let perfColor = isGain ? Color.theme.green : Color.theme.red
        
        return HStack {
            HStack(spacing: 4) {
                Text("Current Market:")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.theme.secondaryText)
                
                Text(currentPrice.asFormattedPrice())
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.theme.accent)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: isGain ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 8.5, weight: .bold))
                
                Text((isGain ? "+" : "") + diffPct.asPercentString())
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                
                Text("(\((isGain ? "+" : "") + totalGain.asCurrencyWith2Decimals()))")
                    .font(.system(size: 9.5, weight: .medium))
            }
            .foregroundStyle(perfColor)
        }
    }
    
    private func formatUnits(_ amount: Double) -> String {
        let absVal = abs(amount)
        if absVal >= 1.0 {
            return amount.asNumberString()
        } else {
            return String(format: "%.4f", amount).replacingOccurrences(
                of: #"(\.\d*?[1-9])0+$|\.0+$"#,
                with: "$1",
                options: .regularExpression
            )
        }
    }
}

// MARK: - Trade Receipt Detail Sheet
struct TradeReceiptDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: MarketViewModel
    
    let trade: TransactionEntity
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onViewCoin: (CoinModel) -> Void
    
    @State private var hasCopiedID: Bool = false
    
    private var isBuy: Bool {
        (trade.transactionType ?? "").uppercased() == "BUY"
    }
    
    private var badgeColor: Color {
        isBuy ? Color.theme.green : Color.theme.red
    }
    
    private var liveCoin: CoinModel? {
        vm.allCoins.first { $0.id.lowercased() == (trade.coinID ?? "").lowercased() }
    }
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Receipt Card
                    receiptCard
                    
                    // Live Market ROI Card (if live data available)
                    if let live = liveCoin, trade.pricePerCoin > 0 {
                        liveMarketComparisonCard(coin: live)
                    }
                    
                    // Transaction Identifier Card
                    transactionMetadataCard
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding(16)
            }
        }
        .navigationTitle("Trade Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            }
        }
    }
    
    private var receiptCard: some View {
        VStack(spacing: 16) {
            // Coin Hero Header
            HStack(spacing: 12) {
                if let live = liveCoin {
                    CoinImageView(coin: live)
                        .frame(width: 48, height: 48)
                } else {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text((trade.coinSymbol ?? "?").prefix(3).uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.orange)
                        )
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(trade.coinName ?? "Unknown Coin")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                    
                    HStack(spacing: 6) {
                        Text((trade.coinSymbol ?? "").uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.secondaryText)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(Color.theme.secondaryText.opacity(0.5))
                        
                        Text("Order Filled")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.green)
                    }
                }
                
                Spacer()
                
                // BUY / SELL Badge
                Text(isBuy ? "BUY ORDER" : "SELL ORDER")
                    .font(.system(size: 11, weight: .heavy))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(badgeColor.opacity(0.14))
                    .foregroundStyle(badgeColor)
                    .clipShape(Capsule())
            }
            
            Divider()
            
            // Detail Rows
            VStack(spacing: 12) {
                receiptRow(title: "Execution Date", value: (trade.timestamp ?? Date()).formatted(date: .long, time: .shortened))
                receiptRow(title: "Quantity Executed", value: "\(trade.amount.asNumberString()) \((trade.coinSymbol ?? "").uppercased())")
                receiptRow(title: "Execution Price", value: trade.pricePerCoin.asFormattedPrice())
                receiptRow(title: "Total Consideration", value: trade.totalValue.asCurrencyWith2Decimals(), isBold: true)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
    }
    
    private func liveMarketComparisonCard(coin: CoinModel) -> some View {
        let diff = coin.currentPrice - trade.pricePerCoin
        let diffPct = (diff / trade.pricePerCoin) * 100.0
        let totalGain = trade.amount * diff
        let isGain = diff >= 0
        let gainColor = isGain ? Color.theme.green : Color.theme.red
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LIVE PERFORMANCE SINCE TRADE")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(0.3)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
                
                Button {
                    onViewCoin(coin)
                } label: {
                    HStack(spacing: 3) {
                        Text("View Market")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.blue)
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Current Live Price")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text(coin.currentPrice.asFormattedPrice())
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text(isBuy ? "Unrealized Gain / Loss" : "Price Drift")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    HStack(spacing: 4) {
                        Image(systemName: isGain ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                            .fontWeight(.bold)
                        
                        Text((isGain ? "+" : "") + diffPct.asPercentString())
                            .font(.subheadline)
                            .fontWeight(.bold)
                        
                        Text("(\((isGain ? "+" : "") + totalGain.asCurrencyWith2Decimals()))")
                            .font(.caption)
                    }
                    .foregroundStyle(gainColor)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(gainColor.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(gainColor.opacity(0.18), lineWidth: 1)
        )
    }
    
    private var transactionMetadataCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRANSACTION ID")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(Color.theme.secondaryText)
            
            HStack {
                Text(trade.id ?? "Unknown ID")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
                
                Spacer()
                
                Button {
                    if let id = trade.id {
                        UIPasteboard.general.string = id
                        HapticManager.notification(type: .success)
                        withAnimation {
                            hasCopiedID = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                hasCopiedID = false
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: hasCopiedID ? "checkmark" : "doc.on.doc")
                        Text(hasCopiedID ? "Copied" : "Copy")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(hasCopiedID ? Color.theme.green : Color.theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.theme.secondaryText.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.theme.secondaryText.opacity(0.05))
        )
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 10) {
            Button(action: onEdit) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                    Text("Edit Trade Details")
                }
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.theme.accent)
                .foregroundStyle(Color.theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            Button(role: .destructive, action: onDelete) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Delete Trade from Book")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.theme.red.opacity(0.1))
                .foregroundStyle(Color.theme.red)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.top, 4)
    }
    
    private func receiptRow(title: String, value: String, isBold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(isBold ? .bold : .semibold)
                .foregroundStyle(Color.theme.accent)
        }
    }
}

// MARK: - Trade Add / Edit Sheet
struct TradeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: MarketViewModel
    
    enum SheetMode {
        case new
        case edit(TransactionEntity)
    }
    
    let mode: SheetMode
    let onSave: (CoinModel, TransactionType, Double, Double, Date) -> Void
    
    @State private var selectedCoin: CoinModel?
    @State private var tradeType: TransactionType = .buy
    @State private var tradeDate: Date = Date()
    @State private var amountString: String = ""
    @State private var priceString: String = ""
    @State private var coinSearchText: String = ""
    @State private var showCoinPicker: Bool = false
    
    init(mode: SheetMode, onSave: @escaping (CoinModel, TransactionType, Double, Double, Date) -> Void) {
        self.mode = mode
        self.onSave = onSave
    }
    
    private var parsedAmount: Double? {
        Double(amountString.replacingOccurrences(of: ",", with: "."))
    }
    
    private var parsedPrice: Double? {
        Double(priceString.replacingOccurrences(of: ",", with: "."))
    }
    
    private var isValid: Bool {
        guard selectedCoin != nil,
              let amt = parsedAmount, amt > 0,
              let prc = parsedPrice, prc > 0 else {
            return false
        }
        return true
    }
    
    private var calculatedTotal: Double {
        (parsedAmount ?? 0) * (parsedPrice ?? 0)
    }
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 18) {
                    // Coin Selection Card
                    coinSelectorCard
                    
                    // Order Type Segment (BUY / SELL)
                    orderTypeSegment
                    
                    // Date & Time Picker Card
                    datePickerCard
                    
                    // Quantity & Price Inputs
                    amountAndPriceCard
                    
                    // Total Consideration Summary
                    totalCard
                    
                    // Save Button
                    saveButton
                }
                .padding(16)
            }
        }
        .navigationTitle(isEditing ? "Edit Trade" : "Log Trade")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(Color.theme.secondaryText)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveAction()
                }
                .fontWeight(.bold)
                .foregroundStyle(isValid ? Color.orange : Color.theme.secondaryText.opacity(0.4))
                .disabled(!isValid)
            }
        }
        .onAppear {
            setupInitialValues()
        }
        .sheet(isPresented: $showCoinPicker) {
            NavigationStack {
                coinPickerModal
            }
        }
    }
    
    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
    
    private func setupInitialValues() {
        switch mode {
        case .new:
            selectedCoin = vm.allCoins.first
            if let coin = selectedCoin {
                priceString = String(format: "%.2f", coin.currentPrice)
            }
        case .edit(let tx):
            selectedCoin = vm.allCoins.first { $0.id.lowercased() == (tx.coinID ?? "").lowercased() }
            if let typeStr = tx.transactionType?.uppercased(), let type = TransactionType(rawValue: typeStr) {
                tradeType = type
            }
            tradeDate = tx.timestamp ?? Date()
            amountString = tx.amount.asNumberString()
            priceString = String(format: "%.2f", tx.pricePerCoin)
        }
    }
    
    private var coinSelectorCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CRYPTOCURRENCY")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.secondaryText)
            
            Button {
                showCoinPicker = true
            } label: {
                HStack(spacing: 12) {
                    if let coin = selectedCoin {
                        CoinImageView(coin: coin)
                            .frame(width: 34, height: 34)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(coin.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.accent)
                            
                            Text(coin.symbol.uppercased())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.theme.secondaryText)
                        }
                    } else {
                        Image(systemName: "circle.grid.cross.fill")
                            .font(.title2)
                            .foregroundStyle(Color.orange)
                        
                        Text("Select a Coin")
                            .font(.headline)
                            .foregroundStyle(Color.theme.accent)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.theme.background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var orderTypeSegment: some View {
        HStack(spacing: 10) {
            // BUY Option
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    tradeType = .buy
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.left.circle.fill")
                    Text("BUY ORDER")
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tradeType == .buy ? Color.theme.green : Color.theme.secondaryText.opacity(0.08))
                )
                .foregroundStyle(tradeType == .buy ? Color.white : Color.theme.secondaryText)
            }
            .buttonStyle(.plain)
            
            // SELL Option
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    tradeType = .sell
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.circle.fill")
                    Text("SELL ORDER")
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tradeType == .sell ? Color.theme.red : Color.theme.secondaryText.opacity(0.08))
                )
                .foregroundStyle(tradeType == .sell ? Color.white : Color.theme.secondaryText)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var datePickerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRADE EXECUTION DATE & TIME")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.secondaryText)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.orange)
                
                DatePicker(
                    "",
                    selection: $tradeDate,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(Color.orange)
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.theme.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
            )
        }
    }
    
    private var amountAndPriceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Quantity Input
            VStack(alignment: .leading, spacing: 6) {
                Text("QUANTITY")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
                
                HStack {
                    TextField("0.0", text: $amountString)
                        .font(.headline)
                        .keyboardType(.decimalPad)
                    
                    if let coin = selectedCoin {
                        Text(coin.symbol.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.theme.background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
            }
            
            // Price Input
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("EXECUTION PRICE PER COIN")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Spacer()
                    
                    if let coin = selectedCoin {
                        Button {
                            priceString = String(format: "%.2f", coin.currentPrice)
                            HapticManager.selection()
                        } label: {
                            Text("Use Live ($\(coin.currentPrice.asFormattedPrice()))")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                HStack {
                    Text("$")
                        .font(.headline)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    TextField("0.00", text: $priceString)
                        .font(.headline)
                        .keyboardType(.decimalPad)
                    
                    Text("USD")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.theme.background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }
    
    private var totalCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TOTAL CONSIDERATION")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Text(calculatedTotal.asCurrencyWith2Decimals())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            Spacer()
            
            Text(tradeType == .buy ? "BUY OUTFLOW" : "SELL INFLOW")
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((tradeType == .buy ? Color.theme.green : Color.theme.red).opacity(0.12))
                .foregroundStyle(tradeType == .buy ? Color.theme.green : Color.theme.red)
                .clipShape(Capsule())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.secondaryText.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
    }
    
    private var saveButton: some View {
        Button {
            saveAction()
        } label: {
            Text(isEditing ? "Update Trade Order" : "Log Trade to Book")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isValid ? Color.orange : Color.gray.opacity(0.4))
                )
        }
        .disabled(!isValid)
        .buttonStyle(.plain)
        .padding(.top, 6)
    }
    
    private var coinPickerModal: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            VStack(spacing: 12) {
                SearchBarView(searchText: $coinSearchText)
                    .padding(.top, 8)
                
                let filtered = vm.allCoins.filter {
                    guard !coinSearchText.isEmpty else { return true }
                    return $0.name.lowercased().contains(coinSearchText.lowercased()) ||
                           $0.symbol.lowercased().contains(coinSearchText.lowercased())
                }
                
                List(filtered) { coin in
                    Button {
                        selectedCoin = coin
                        if priceString.isEmpty || priceString == "0.00" {
                            priceString = String(format: "%.2f", coin.currentPrice)
                        }
                        showCoinPicker = false
                    } label: {
                        HStack(spacing: 12) {
                            CoinImageView(coin: coin)
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(coin.name)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.theme.accent)
                                
                                Text(coin.symbol.uppercased())
                                    .font(.caption2)
                                    .foregroundStyle(Color.theme.secondaryText)
                            }
                            
                            Spacer()
                            
                            Text(coin.currentPrice.asFormattedPrice())
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.theme.accent)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Select Coin")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    showCoinPicker = false
                }
                .foregroundStyle(Color.theme.accent)
            }
        }
    }
    
    private func saveAction() {
        guard let coin = selectedCoin,
              let amt = parsedAmount, amt > 0,
              let prc = parsedPrice, prc > 0 else {
            return
        }
        HapticManager.notification(type: .success)
        onSave(coin, tradeType, amt, prc, tradeDate)
        dismiss()
    }
}

// MARK: - Previews
#Preview("TradeBook - Populated") {
    NavigationStack {
        TradeBookView()
            .environmentObject(DeveloperPreview.instance.homeVM)
    }
    .preferredColorScheme(.dark)
}

#Preview("TradeBook - Empty") {
    NavigationStack {
        TradeBookView()
            .environmentObject(MarketViewModel(isForPreview: true))
    }
    .preferredColorScheme(.dark)
}
