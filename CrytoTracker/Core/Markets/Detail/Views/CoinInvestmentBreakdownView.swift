//
//  CoinInvestmentBreakdownView.swift
//  CrytoTracker
//
//  Created by Antigravity on 15/11/2026.
//

import SwiftUI
import UIKit

@MainActor
struct CoinInvestmentBreakdownView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeVM: MarketViewModel
    @StateObject private var viewModel: CoinInvestmentBreakdownViewModel
    
    typealias PurchaseLot = CoinInvestmentBreakdownViewModel.PurchaseLot
    
    init(coin: CoinModel, viewModel: CoinInvestmentBreakdownViewModel? = nil) {
        self._viewModel = StateObject(wrappedValue: viewModel ?? CoinInvestmentBreakdownViewModel(coin: coin))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.screenBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        holdingSummaryCard
                        transactionsSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("\(viewModel.currentCoin.name) Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CoinImageView(coin: viewModel.currentCoin)
                        .frame(width: 28, height: 28)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline).bold()
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                viewModel.setMarketViewModel(homeVM)
            }
            .sheet(item: $viewModel.editingLot) { lot in
                EditTransactionSheet(coin: viewModel.currentCoin, lot: lot) { updatedDate, updatedAmount, updatedPrice in
                    viewModel.updateTransaction(
                        id: lot.id,
                        updatedDate: updatedDate,
                        updatedAmount: updatedAmount,
                        updatedPrice: updatedPrice
                    )
                }
            }
        }
    }
}

// MARK: - Subviews & Sections
extension CoinInvestmentBreakdownView {
    
    // MARK: - Holding Summary Card
    private var holdingSummaryCard: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT POSITION")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    HStack(spacing: 6) {
                        Text(viewModel.currentCoin.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                        
                        Text(viewModel.currentCoin.symbol.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.theme.secondaryText.opacity(0.12))
                            .clipShape(Capsule())
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Current Price")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text(viewModel.currentCoin.currentPrice.asFormattedPrice())
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                }
            }
            
            Divider()
                .background(Color.theme.secondaryText.opacity(0.12))
            
            // Row 1: Total Quantity Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "number.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.orange)
                    Text("Total Quantity")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text("\((viewModel.currentCoin.currentHoldings ?? 0).asNumberString()) \(viewModel.currentCoin.symbol.uppercased())")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            // Row 2: Present Value Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "banknote.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.purple)
                    Text("Present Value")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text(viewModel.currentCoin.currentHoldingsValue.asCurrencyWith2Decimals())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            // Row 3: Average Buy Price Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.cyan)
                    Text("Average Buy Price")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text((viewModel.currentCoin.averageBuyPrice ?? viewModel.currentCoin.currentPrice).asFormattedPrice())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            // Row 4: Total Unrealized P&L Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.currentCoin.profitLoss >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(viewModel.currentCoin.profitLoss >= 0 ? Color.theme.green : Color.theme.red)
                    Text("Total P&L")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text("\((viewModel.currentCoin.profitLoss >= 0 ? "+" : ""))\(viewModel.currentCoin.profitLoss.asCurrencyWith2Decimals()) (\((viewModel.currentCoin.profitLoss >= 0 ? "+" : ""))\(viewModel.currentCoin.profitLossPercentage.asPercentString()))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(viewModel.currentCoin.profitLoss >= 0 ? Color.theme.green : Color.theme.red)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.05), radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Transactions Section
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.accent)
                
                Text("Purchase Transactions")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
                
                Spacer()
                
                Text("\(viewModel.purchaseLots.count) \(viewModel.purchaseLots.count == 1 ? "Lot" : "Lots")")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            .padding(.top, 4)
            
            if viewModel.purchaseLots.isEmpty {
                emptyTransactionsPlaceholder
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.purchaseLots) { lot in
                        SlideToEditTransactionRow(
                            lot: lot,
                            coin: viewModel.currentCoin,
                            swipedLotId: $viewModel.swipedLotId,
                            onEdit: {
                                viewModel.editLot(lot)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyTransactionsPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.theme.secondaryText.opacity(0.4))
            
            Text("No recorded buy transactions")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.secondaryText.opacity(0.10), lineWidth: 1)
        )
    }
}

// MARK: - Slide To Edit Transaction Row Component
private struct SlideToEditTransactionRow: View {
    let lot: CoinInvestmentBreakdownView.PurchaseLot
    let coin: CoinModel
    @Binding var swipedLotId: String?
    let onEdit: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    private let actionWidth: CGFloat = 84
    
    private var isSwipedOpen: Bool {
        swipedLotId == lot.id
    }
    
    private var totalCost: Double {
        lot.amount * lot.pricePerCoin
    }
    
    private var currentValue: Double {
        lot.amount * coin.currentPrice
    }
    
    private var lotProfitLoss: Double {
        currentValue - totalCost
    }
    
    private var lotProfitLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return ((currentValue - totalCost) / totalCost) * 100
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Background Action Button revealed on swipe
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                        swipedLotId = nil
                    }
                    onEdit()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .bold))
                        Text("Edit")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: actionWidth, height: 76)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            
            // Foreground Content Card
            HStack(spacing: 12) {
                // Left Icon & Date Info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.down.left.circle.fill")
                            .foregroundStyle(Color.theme.green)
                            .font(.subheadline)
                        
                        Text("Bought \(lot.amount.asNumberString()) \(coin.symbol.uppercased())")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                    }
                    
                    Text(lot.date.asShortDateString())
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                // Right Financial Info
                VStack(alignment: .trailing, spacing: 3) {
                    Text(totalCost.asCurrencyWith2Decimals())
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.accent)
                    
                    HStack(spacing: 2) {
                        Image(systemName: lotProfitLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 8, weight: .bold))
                        Text("\(lotProfitLoss >= 0 ? "+" : "")\(lotProfitLossPercentage.asPercentString())")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(lotProfitLoss >= 0 ? Color.theme.green : Color.theme.red)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.theme.background)
                    .shadow(color: Color.theme.accent.opacity(0.03), radius: 5, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
            )
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .onChanged { value in
                        if value.translation.width < 0 {
                            // Swiping left to reveal edit button
                            dragOffset = max(value.translation.width, -actionWidth)
                        } else if isSwipedOpen && value.translation.width > 0 {
                            // Swiping right to close
                            dragOffset = min(-actionWidth + value.translation.width, 0)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            if value.translation.width < -35 {
                                dragOffset = -actionWidth
                                swipedLotId = lot.id
                                HapticManager.impact(style: .light)
                            } else {
                                dragOffset = 0
                                if swipedLotId == lot.id {
                                    swipedLotId = nil
                                }
                            }
                        }
                    }
            )
        }
    }
}

// MARK: - Previews
#Preview("Coin Investment Breakdown - Dark") {
    CoinInvestmentBreakdownView(coin: DeveloperPreview.instance.coin)
        .environmentObject(DeveloperPreview.instance.homeVM)
        .preferredColorScheme(.dark)
}

#Preview("Coin Investment Breakdown - Light") {
    CoinInvestmentBreakdownView(coin: DeveloperPreview.instance.coin)
        .environmentObject(DeveloperPreview.instance.homeVM)
        .preferredColorScheme(.light)
}
