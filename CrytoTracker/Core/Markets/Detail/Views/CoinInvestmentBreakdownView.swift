//
//  CoinInvestmentBreakdownView.swift
//  CrytoTracker
//
//  Created by Antigravity on 15/11/2026.
//

import SwiftUI
import UIKit

struct CoinInvestmentBreakdownView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeVM: MarketViewModel
    let coin: CoinModel
    
    @State private var editingLot: PurchaseLot? = nil
    @State private var swipedLotId: String? = nil
    
    struct PurchaseLot: Identifiable, Equatable {
        let id: String
        let date: Date
        let amount: Double
        let pricePerCoin: Double
    }
    
    private var currentCoin: CoinModel {
        homeVM.portfolioCoins.first(where: { $0.id == coin.id }) ?? coin
    }
    
    private var purchaseLots: [PurchaseLot] {
        let buyTxs = homeVM.transactions(for: currentCoin.id)
            .filter { ($0.transactionType ?? "").uppercased() == "BUY" }
            .sorted { ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) }
        
        if !buyTxs.isEmpty {
            return buyTxs.map { tx in
                PurchaseLot(
                    id: tx.id ?? UUID().uuidString,
                    date: tx.timestamp ?? Date(),
                    amount: tx.amount,
                    pricePerCoin: tx.pricePerCoin
                )
            }
        }
        
        // Fallback for coins held without granular buy records (e.g. manual portfolio entry or preview)
        if let holdings = currentCoin.currentHoldings, holdings > 0 {
            let buyPrice = currentCoin.averageBuyPrice ?? currentCoin.currentPrice
            let fallbackDate = Calendar.current.date(byAdding: .day, value: -78, to: Date()) ?? Date()
            return [
                PurchaseLot(
                    id: "primary-lot",
                    date: fallbackDate,
                    amount: holdings,
                    pricePerCoin: buyPrice
                )
            ]
        }
        
        return []
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
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
            .navigationTitle("\(currentCoin.name) Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CoinImageView(coin: currentCoin)
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
            .sheet(item: $editingLot) { lot in
                EditTransactionSheet(coin: currentCoin, lot: lot) { updatedDate, updatedAmount, updatedPrice in
                    homeVM.updateTransactionAndRecalculate(
                        id: lot.id,
                        coin: currentCoin,
                        type: .buy,
                        amount: updatedAmount,
                        pricePerCoin: updatedPrice,
                        timestamp: updatedDate
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
                        Text(currentCoin.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                        
                        Text(currentCoin.symbol.uppercased())
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
                    
                    Text(currentCoin.currentPrice.asFormattedPrice())
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
                
                Text("\((currentCoin.currentHoldings ?? 0).asNumberString()) \(currentCoin.symbol.uppercased())")
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
                
                Text(currentCoin.currentHoldingsValue.asCurrencyWith2Decimals())
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
                
                Text((currentCoin.averageBuyPrice ?? currentCoin.currentPrice).asFormattedPrice())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            // Row 4: Total Unrealized P&L Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: currentCoin.profitLoss >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(currentCoin.profitLoss >= 0 ? Color.theme.green : Color.theme.red)
                    Text("Total P&L")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Text("\((currentCoin.profitLoss >= 0 ? "+" : ""))\(currentCoin.profitLoss.asCurrencyWith2Decimals()) (\((currentCoin.profitLoss >= 0 ? "+" : ""))\(currentCoin.profitLossPercentage.asPercentString()))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(currentCoin.profitLoss >= 0 ? Color.theme.green : Color.theme.red)
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
                
                Text("\(purchaseLots.count) \(purchaseLots.count == 1 ? "Lot" : "Lots")")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.theme.secondaryText)
            }
            .padding(.top, 4)
            
            if purchaseLots.isEmpty {
                emptyTransactionsPlaceholder
            } else {
                VStack(spacing: 10) {
                    ForEach(purchaseLots) { lot in
                        SlideToEditTransactionRow(
                            lot: lot,
                            coin: currentCoin,
                            swipedLotId: $swipedLotId,
                            onEdit: {
                                editingLot = lot
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
    @State private var rowHeight: CGFloat = 68
    private let actionButtonWidth: CGFloat = 76
    
    private var isSwipedOpen: Bool {
        swipedLotId == lot.id
    }
    
    private var currentOffset: CGFloat {
        let base: CGFloat = isSwipedOpen ? -actionButtonWidth : 0
        return base + dragOffset
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Interactive Foreground Card
            cardContent
                .offset(x: currentOffset)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                if geo.size.height > 0 { rowHeight = geo.size.height }
                            }
                            .onChange(of: geo.size.height) { _, newHeight in
                                if newHeight > 0 { rowHeight = newHeight }
                            }
                    }
                )
                .overlay(
                    SwipePanGestureOverlay(
                        onPanChanged: { translation in
                            let base: CGFloat = isSwipedOpen ? -actionButtonWidth : 0
                            let proposed = base + translation
                            
                            if proposed <= 0 {
                                let overdrag = max(-actionButtonWidth - proposed, 0)
                                dragOffset = (proposed - base) + (overdrag * 0.25)
                            } else {
                                dragOffset = min(translation * 0.15, 10)
                            }
                        },
                        onPanEnded: { translation, velocity in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                if isSwipedOpen {
                                    if translation > 20 || velocity > 120 {
                                        swipedLotId = nil
                                    } else {
                                        swipedLotId = lot.id
                                    }
                                } else {
                                    if translation < -25 || velocity < -160 {
                                        swipedLotId = lot.id
                                        HapticManager.impact(style: .light)
                                    } else {
                                        swipedLotId = nil
                                    }
                                }
                                dragOffset = 0
                            }
                        },
                        onTap: {
                            if isSwipedOpen {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                    swipedLotId = nil
                                }
                            } else {
                                onEdit()
                            }
                        }
                    )
                )
                .zIndex(1)
            
            // Action Button Revealed on Right (Placed in foreground with higher zIndex when revealed)
            actionButton
                .zIndex(isSwipedOpen ? 10 : 0)
                .allowsHitTesting(isSwipedOpen)
        }
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button {
            triggerEdit()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .bold))
                Text("Edit")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(width: actionButtonWidth - 8, height: max(50, rowHeight - 2))
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                triggerEdit()
            }
        )
        .padding(.vertical, 1)
    }
    
    private func triggerEdit() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            swipedLotId = nil
        }
        HapticManager.impact(style: .light)
        onEdit()
    }
    
    // MARK: - Card Content
    private var cardContent: some View {
        let lotPnl = lot.amount * (coin.currentPrice - lot.pricePerCoin)
        let isProfitable = lotPnl >= 0
        
        return VStack(alignment: .leading, spacing: 0) {
            // Top sub-header: Date of purchase
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.theme.secondaryText)
                
                Text(lot.date.asDayMonthYearString())
                    .fontWeight(.medium)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Spacer()
            }
            .font(.footnote)
            .padding(.bottom, 6)
            
            HStack(alignment: .bottom) {
                // Left Column: Qty bought, Price at which bought
                VStack(alignment: .leading, spacing: 2) {
                    Text("Qty \(lot.amount.asNumberString())")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text("Price \(lot.pricePerCoin.asFormattedPrice())")
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Spacer()
                
                // Right Column: How many days old purchase, P&L according to that purchase price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(daysOldText(from: lot.date))
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    HStack(spacing: 3) {
                        Text("\(isProfitable ? "+" : "")\(lotPnl.asCurrencyWith2Decimals())")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(isProfitable ? Color.theme.green : Color.theme.red)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit Purchase", systemImage: "pencil")
            }
        }
    }
    
    // MARK: - Days Old Helper
    private func daysOldText(from date: Date) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfPurchase = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: startOfPurchase, to: startOfToday)
        let days = max(0, components.day ?? 0)
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day old"
        } else {
            return "\(days) days old"
        }
    }
}

// MARK: - Directional Pan Gesture Overlay
/// Ensures horizontal swiping never intercepts or stutters vertical scrolling in the parent ScrollView.
private struct SwipePanGestureOverlay: UIViewRepresentable {
    var onPanChanged: (CGFloat) -> Void
    var onPanEnded: (CGFloat, CGFloat) -> Void
    var onTap: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        pan.cancelsTouchesInView = false
        view.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.delegate = context.coordinator
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onPanChanged = onPanChanged
        context.coordinator.onPanEnded = onPanEnded
        context.coordinator.onTap = onTap
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPanChanged: onPanChanged, onPanEnded: onPanEnded, onTap: onTap)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onPanChanged: (CGFloat) -> Void
        var onPanEnded: (CGFloat, CGFloat) -> Void
        var onTap: () -> Void
        
        init(
            onPanChanged: @escaping (CGFloat) -> Void,
            onPanEnded: @escaping (CGFloat, CGFloat) -> Void,
            onTap: @escaping () -> Void
        ) {
            self.onPanChanged = onPanChanged
            self.onPanEnded = onPanEnded
            self.onTap = onTap
        }
        
        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let translation = recognizer.translation(in: view).x
            let velocity = recognizer.velocity(in: view).x
            
            switch recognizer.state {
            case .changed:
                onPanChanged(translation)
            case .ended, .cancelled:
                onPanEnded(translation, velocity)
            default:
                break
            }
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            if recognizer.state == .ended {
                onTap()
            }
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if let pan = gestureRecognizer as? UIPanGestureRecognizer {
                guard let view = pan.view else { return false }
                let velocity = pan.velocity(in: view)
                // Strictly require horizontal velocity to dominate vertical velocity
                return abs(velocity.x) > abs(velocity.y) * 1.5 && abs(velocity.x) > 25
            }
            return true
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Never recognize simultaneously with vertical scroll view
            if otherGestureRecognizer is UIPanGestureRecognizer && !(otherGestureRecognizer.view === gestureRecognizer.view) {
                return false
            }
            return true
        }
    }
}

// MARK: - Previews
#Preview("Breakdown - Profitable (Dark)") {
    CoinInvestmentBreakdownView(coin: DeveloperPreview.instance.coin)
        .environmentObject(DeveloperPreview.instance.homeVM)
        .preferredColorScheme(.dark)
}

#Preview("Breakdown - Loss (Dark)") {
    CoinInvestmentBreakdownView(coin: DeveloperPreview.instance.adaCoin)
        .environmentObject(DeveloperPreview.instance.homeVM)
        .preferredColorScheme(.dark)
}

#Preview("Breakdown - Light Mode") {
    CoinInvestmentBreakdownView(coin: DeveloperPreview.instance.coin)
        .environmentObject(DeveloperPreview.instance.homeVM)
        .preferredColorScheme(.light)
}
