//
//  EditTransactionSheet.swift
//  CrytoTracker
//
//  Created by Antigravity on 16/11/2026.
//

import SwiftUI

struct EditTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let coin: CoinModel
    let lot: CoinInvestmentBreakdownView.PurchaseLot
    let onSave: (Date, Double, Double) -> Void
    
    @State private var transactionDate: Date
    @State private var amountString: String
    @State private var priceString: String
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case amount
        case price
    }
    
    init(
        coin: CoinModel,
        lot: CoinInvestmentBreakdownView.PurchaseLot,
        onSave: @escaping (Date, Double, Double) -> Void
    ) {
        self.coin = coin
        self.lot = lot
        self.onSave = onSave
        
        _transactionDate = State(initialValue: lot.date)
        _amountString = State(initialValue: lot.amount.asNumberString())
        _priceString = State(initialValue: String(format: "%.2f", lot.pricePerCoin))
    }
    
    private var parsedAmount: Double? {
        Double(amountString.replacingOccurrences(of: ",", with: "."))
    }
    
    private var parsedPrice: Double? {
        Double(priceString.replacingOccurrences(of: ",", with: "."))
    }
    
    private var isValid: Bool {
        guard let amount = parsedAmount, amount > 0,
              let price = parsedPrice, price > 0 else {
            return false
        }
        return true
    }
    
    private var calculatedTotal: Double {
        (parsedAmount ?? 0) * (parsedPrice ?? 0)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        coinHeaderCard
                        
                        dateSection
                        
                        amountAndPriceSection
                        
                        totalSummaryCard
                        
                        saveButton
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Edit Purchase Lot")
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
                    .foregroundStyle(isValid ? Color.theme.accent : Color.theme.secondaryText.opacity(0.4))
                    .disabled(!isValid)
                }
            }
        }
    }
    
    // MARK: - Coin Header Card
    private var coinHeaderCard: some View {
        HStack(spacing: 12) {
            CoinImageView(coin: coin)
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(coin.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
                
                HStack(spacing: 5) {
                    Text(coin.symbol.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Text("Buy Record")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.green)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Live Price")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Text(coin.currentPrice.asFormattedPrice())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
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
                .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Purchase Date Picker
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Purchase Date & Time")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.secondaryText)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.theme.accent)
                    .font(.subheadline)
                
                DatePicker(
                    "",
                    selection: $transactionDate,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(Color.theme.accent)
                
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
    
    // MARK: - Amount & Price Inputs
    private var amountAndPriceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Quantity Input
            VStack(alignment: .leading, spacing: 6) {
                Text("Quantity Purchased")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.secondaryText)
                
                HStack {
                    TextField("0.0", text: $amountString)
                        .font(.headline)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                    
                    Text(coin.symbol.uppercased())
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
            
            // Buy Price Input
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Purchase Price per Coin")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    Spacer()
                    
                    Button {
                        priceString = String(format: "%.2f", coin.currentPrice)
                        HapticManager.selection()
                    } label: {
                        Text("Use Live Price")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.blue)
                    }
                    .buttonStyle(.plain)
                }
                
                HStack {
                    Text("$")
                        .font(.headline)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    TextField("0.00", text: $priceString)
                        .font(.headline)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .price)
                    
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
    
    // MARK: - Total Summary Card
    private var totalSummaryCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Cost Basis")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Text(calculatedTotal.asCurrencyWith2Decimals())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
            
            Spacer()
            
            let estimatedPnl = (parsedAmount ?? 0) * (coin.currentPrice - (parsedPrice ?? 0))
            let isProfitable = estimatedPnl >= 0
            VStack(alignment: .trailing, spacing: 2) {
                Text("Unrealized P&L")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
                
                Text((isProfitable ? "+" : "") + estimatedPnl.asCurrencyWith2Decimals())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(isProfitable ? Color.theme.green : Color.theme.red)
            }
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
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            saveAction()
        } label: {
            Text("Save Purchase Changes")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isValid ? Color.blue : Color.gray.opacity(0.4))
                )
        }
        .disabled(!isValid)
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
    
    private func saveAction() {
        guard let amount = parsedAmount, amount > 0,
              let price = parsedPrice, price > 0 else {
            return
        }
        HapticManager.notification(type: .success)
        onSave(transactionDate, amount, price)
        dismiss()
    }
}

// MARK: - Preview
#Preview("Edit Purchase Sheet - Dark") {
    EditTransactionSheet(
        coin: DeveloperPreview.instance.coin,
        lot: CoinInvestmentBreakdownView.PurchaseLot(
            id: "preview-lot-1",
            date: Calendar.current.date(byAdding: .day, value: -42, to: Date()) ?? Date(),
            amount: 0.5,
            pricePerCoin: 88500.0
        ),
        onSave: { _, _, _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("Edit Purchase Sheet - Light") {
    EditTransactionSheet(
        coin: DeveloperPreview.instance.adaCoin,
        lot: CoinInvestmentBreakdownView.PurchaseLot(
            id: "preview-lot-2",
            date: Calendar.current.date(byAdding: .day, value: -12, to: Date()) ?? Date(),
            amount: 1500.0,
            pricePerCoin: 0.72
        ),
        onSave: { _, _, _ in }
    )
    .preferredColorScheme(.light)
}
