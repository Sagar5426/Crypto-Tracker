//
//  PortfolioView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 28/09/2025.
//

import SwiftUI

struct PortfolioView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: HomeViewModel
    
    // Initializer context
    private let initialCoin: CoinModel?
    
    // State
    @State private var activeCoin: CoinModel?
    @State private var selectedTab: PortfolioTab = .myHoldings
    @State private var searchText: String = ""
    @State private var filterCategory: AssetCategory = .all
    
    // Editor State
    @State private var inputMode: InputMode = .token
    @State private var quantityText: String = ""
    @State private var fiatText: String = ""
    @State private var showCheckMark = false
    @State private var coinToDelete: CoinModel? = nil
    @State private var showDeleteConfirmation = false
    
    enum PortfolioTab: String, CaseIterable, Identifiable {
        case myHoldings = "My Holdings"
        case addAsset = "Add Asset"
        var id: String { rawValue }
    }
    
    enum InputMode: String, CaseIterable, Identifiable {
        case token = "Coins"
        case fiat = "USD ($)"
        var id: String { rawValue }
    }
    
    enum AssetCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case top10 = "Top 10"
        case gainers = "Gainers"
        case losers = "Losers"
        var id: String { rawValue }
    }
    
    init(selectedCoin: CoinModel? = nil) {
        self.initialCoin = selectedCoin
        self._activeCoin = State(initialValue: selectedCoin)
        if let coin = selectedCoin {
            let current = coin.currentHoldings ?? 0
            let qText = current > 0 ? (current.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", current) : "\(current)") : ""
            self._quantityText = State(initialValue: qText)
            let fVal = current * coin.currentPrice
            self._fiatText = State(initialValue: fVal > 0 ? String(format: "%.2f", fVal) : "")
        }
    }
    
    // Computed Lists
    private var filteredHoldings: [CoinModel] {
        if searchText.isEmpty {
            return vm.portfolioCoins
        } else {
            let lower = searchText.lowercased()
            return vm.portfolioCoins.filter {
                $0.name.lowercased().contains(lower) ||
                $0.symbol.lowercased().contains(lower)
            }
        }
    }
    
    private var filteredAllCoins: [CoinModel] {
        var coins = vm.allCoins
        
        switch filterCategory {
        case .all:
            break
        case .top10:
            coins = Array(coins.prefix(10))
        case .gainers:
            coins = coins.filter { ($0.priceChangePercentage24H ?? 0) > 0 }
                         .sorted(by: { ($0.priceChangePercentage24H ?? 0) > ($1.priceChangePercentage24H ?? 0) })
        case .losers:
            coins = coins.filter { ($0.priceChangePercentage24H ?? 0) < 0 }
                         .sorted(by: { ($0.priceChangePercentage24H ?? 0) < ($1.priceChangePercentage24H ?? 0) })
        }
        
        if !searchText.isEmpty {
            let lower = searchText.lowercased()
            coins = coins.filter {
                $0.name.lowercased().contains(lower) ||
                $0.symbol.lowercased().contains(lower)
            }
        }
        
        return coins
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                if let coin = activeCoin {
                    holdingEditorView(coin: coin)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    mainAssetListView
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: activeCoin?.id)
            .alert("Remove Holding", isPresented: $showDeleteConfirmation, presenting: coinToDelete) { coin in
                Button("Remove", role: .destructive) {
                    withAnimation {
                        vm.deleteHolding(coin: coin)
                        if activeCoin?.id == coin.id {
                            activeCoin = nil
                        }
                    }
                    HapticManager.notification(type: .success)
                }
                Button("Cancel", role: .cancel) { }
            } message: { coin in
                Text("Are you sure you want to remove \(coin.name) from your portfolio?")
            }
        }
    }
}

// MARK: - Main Asset List View
extension PortfolioView {
    
    private var mainAssetListView: some View {
        VStack(spacing: 12) {
            // Mode Picker
            Picker("Mode", selection: $selectedTab) {
                Text("My Holdings (\(vm.portfolioCoins.count))").tag(PortfolioTab.myHoldings)
                Text("Add Asset").tag(PortfolioTab.addAsset)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 4)
            
            // Search Bar
            SearchBarView(searchText: $searchText)
                .padding(.vertical, -4)
            
            // Category Filter Pills (Add Asset tab only)
            if selectedTab == .addAsset {
                categoryPillsBar
            }
            
            // Content List
            if selectedTab == .myHoldings {
                holdingsTabContent
            } else {
                addAssetTabContent
            }
        }
        .navigationTitle("Manage Portfolio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.accent)
            }
        }
    }
    
    private var categoryPillsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AssetCategory.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            filterCategory = category
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(.caption)
                            .fontWeight(filterCategory == category ? .bold : .medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(filterCategory == category ? Color.theme.accent : Color.theme.secondaryText.opacity(0.1))
                            )
                            .foregroundStyle(filterCategory == category ? Color.theme.background : Color.theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Holdings List
    private var holdingsTabContent: some View {
        Group {
            if vm.portfolioCoins.isEmpty {
                emptyHoldingsState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredHoldings) { coin in
                            Button {
                                openEditor(for: coin)
                            } label: {
                                holdingListRow(coin: coin)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    private func holdingListRow(coin: CoinModel) -> some View {
        HStack(spacing: 12) {
            CoinImageView(coin: coin)
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(coin.symbol.uppercased())
                        .font(.headline)
                        .foregroundStyle(Color.theme.accent)
                    
                    Text("\(String(format: "%.1f%%", vm.portfolioShare(for: coin)))")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.theme.green.opacity(0.12))
                        .foregroundStyle(Color.theme.green)
                        .clipShape(Capsule())
                }
                
                Text(coin.name)
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(coin.currentHoldingsValue.asCurrencyWith2Decimals())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text("\((coin.currentHoldings ?? 0).asNumberString()) \(coin.symbol.uppercased())")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.theme.secondaryText.opacity(0.6))
                .padding(.leading, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
        .contextMenu {
            Button {
                openEditor(for: coin)
            } label: {
                Label("Edit Holding", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                coinToDelete = coin
                showDeleteConfirmation = true
            } label: {
                Label("Remove Holding", systemImage: "trash")
            }
        }
    }
    
    private var emptyHoldingsState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.theme.accent.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.theme.accent)
            }
            
            Text("No Assets In Portfolio")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
            
            Text("Track your cryptocurrency holdings with live valuations, profit & loss, and allocation breakdown.")
                .font(.subheadline)
                .foregroundStyle(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                withAnimation {
                    selectedTab = .addAsset
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Browse & Add Assets")
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.background)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.theme.accent)
                .clipShape(Capsule())
            }
            .padding(.top, 4)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Add Asset List
    private var addAssetTabContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredAllCoins) { coin in
                    let isHeld = vm.portfolioCoins.contains(where: { $0.id == coin.id })
                    
                    Button {
                        openEditor(for: coin)
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(coin.rank)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.theme.secondaryText)
                                .frame(width: 20, alignment: .leading)
                            
                            CoinImageView(coin: coin)
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(coin.symbol.uppercased())
                                    .font(.headline)
                                    .foregroundStyle(Color.theme.accent)
                                Text(coin.name)
                                    .font(.caption2)
                                    .foregroundStyle(Color.theme.secondaryText)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(coin.currentPrice.asFormattedPrice())
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.theme.accent)
                                
                                Text(coin.priceChangePercentage24H?.asPercentString() ?? "0.0%")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle((coin.priceChangePercentage24H ?? 0) >= 0 ? Color.theme.green : Color.theme.red)
                            }
                            
                            if isHeld {
                                Text("Held")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.theme.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.theme.green.opacity(0.12))
                                    .clipShape(Capsule())
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.theme.accent)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.background)
                                .shadow(color: Color.theme.accent.opacity(0.03), radius: 4, x: 0, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Dedicated Holding Editor View
extension PortfolioView {
    
    private func holdingEditorView(coin: CoinModel) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                // Coin Header Hero Card
                HStack(spacing: 12) {
                    CoinImageView(coin: coin)
                        .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(coin.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                        
                        Text(coin.symbol.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(coin.currentPrice.asFormattedPrice())
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                        
                        Text(coin.priceChangePercentage24H?.asPercentString() ?? "0.0%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle((coin.priceChangePercentage24H ?? 0) >= 0 ? Color.theme.green : Color.theme.red)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.theme.background)
                        .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
                )
                
                // Input Mode Toggle & Amount Box
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Picker("Input Mode", selection: $inputMode) {
                            ForEach(InputMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 200)
                        
                        Spacer()
                        
                        Button("Clear") {
                            quantityText = ""
                            fiatText = ""
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.red)
                        .opacity((quantityText.isEmpty && fiatText.isEmpty) ? 0 : 1)
                    }
                    
                    // Amount Field
                    HStack {
                        if inputMode == .fiat {
                            Text("$")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.theme.secondaryText)
                            
                            TextField("0.00", text: $fiatText)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .onChange(of: fiatText) { _, newFiat in
                                    syncFromFiat(newFiat: newFiat, price: coin.currentPrice)
                                }
                        } else {
                            TextField("0.00", text: $quantityText)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .onChange(of: quantityText) { _, newQty in
                                    syncFromQuantity(newQty: newQty, price: coin.currentPrice)
                                }
                            
                            Text(coin.symbol.uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.secondaryText)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.theme.secondaryText.opacity(0.08))
                    )
                    
                    // Equivalent conversion subtitle
                    if inputMode == .fiat {
                        let qty = Double(quantityText) ?? 0
                        Text("≈ \(qty.asNumberString()) \(coin.symbol.uppercased())")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.theme.secondaryText)
                    } else {
                        let val = (Double(quantityText) ?? 0) * coin.currentPrice
                        Text("≈ \(val.asCurrencyWith2Decimals())")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    // Quick Increment Pills
                    HStack(spacing: 8) {
                        ForEach([0.1, 0.5, 1.0, 5.0, 10.0], id: \.self) { increment in
                            Button {
                                addIncrement(increment: increment, price: coin.currentPrice)
                            } label: {
                                Text("+\(increment < 1 ? String(format: "%.1f", increment) : String(format: "%.0f", increment))")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.theme.accent.opacity(0.08))
                                    .clipShape(Capsule())
                                    .foregroundStyle(Color.theme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.theme.background)
                        .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
                )
                
                // Real-Time Valuation & P&L Summary Card
                let qty = Double(quantityText) ?? 0
                let totalValue = qty * coin.currentPrice
                let pnl24H = totalValue * ((coin.priceChangePercentage24H ?? 0) / 100.0)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Total Holding Valuation")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.secondaryText)
                        Spacer()
                        Text(totalValue.asCurrencyWith2Decimals())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Estimated 24h P&L")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.secondaryText)
                        Spacer()
                        Text((pnl24H >= 0 ? "+" : "") + pnl24H.asCurrencyWith2Decimals())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(pnl24H >= 0 ? Color.theme.green : Color.theme.red)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.theme.background)
                        .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
                )
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        saveHolding(for: coin)
                    } label: {
                        HStack(spacing: 8) {
                            if showCheckMark {
                                Image(systemName: "checkmark")
                            }
                            Text(showCheckMark ? "Saved!" : "Save Holdings")
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(showCheckMark ? Color.theme.green : Color.theme.accent)
                        .foregroundStyle(Color.theme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.theme.accent.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    
                    if vm.portfolioCoins.contains(where: { $0.id == coin.id }) {
                        Button {
                            coinToDelete = coin
                            showDeleteConfirmation = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("Remove from Portfolio")
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.red)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle(initialCoin != nil ? "Edit Holdings" : coin.symbol.uppercased())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if initialCoin != nil {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.theme.accent)
                } else {
                    Button {
                        withAnimation {
                            activeCoin = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(Color.theme.accent)
                    }
                }
            }
        }
    }
    
    // MARK: - Logic & Sync Helpers
    private func openEditor(for coin: CoinModel) {
        activeCoin = coin
        if let current = coin.currentHoldings, current > 0 {
            quantityText = current.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", current) : "\(current)"
            fiatText = String(format: "%.2f", current * coin.currentPrice)
        } else {
            quantityText = ""
            fiatText = ""
        }
    }
    
    private func syncFromQuantity(newQty: String, price: Double) {
        guard inputMode == .token else { return }
        if let qty = Double(newQty) {
            fiatText = String(format: "%.2f", qty * price)
        } else {
            fiatText = ""
        }
    }
    
    private func syncFromFiat(newFiat: String, price: Double) {
        guard inputMode == .fiat else { return }
        if let fiat = Double(newFiat), price > 0 {
            let qty = fiat / price
            quantityText = qty.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", qty) : String(format: "%.4f", qty)
        } else {
            quantityText = ""
        }
    }
    
    private func addIncrement(increment: Double, price: Double) {
        let current = Double(quantityText) ?? 0
        let updated = current + increment
        quantityText = String(format: updated.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f", updated)
        fiatText = String(format: "%.2f", updated * price)
        HapticManager.notification(type: .success)
    }
    
    private func saveHolding(for coin: CoinModel) {
        let amount = Double(quantityText) ?? 0
        vm.updatePortfolio(coin: coin, amount: amount)
        
        withAnimation(.easeIn) {
            showCheckMark = true
        }
        HapticManager.notification(type: .success)
        UIApplication.shared.endEditing()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                showCheckMark = false
                if initialCoin != nil {
                    dismiss()
                } else {
                    activeCoin = nil
                }
            }
        }
    }
}

#Preview {
    PortfolioView()
        .environmentObject(DeveloperPreview.instance.homeVM)
}
