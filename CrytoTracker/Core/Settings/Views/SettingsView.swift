//
//  SettingsView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 03/10/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: MarketViewModel
    
    var showsDismissButton: Bool = false
    
    @State private var cachedImageCount: Int = LocalFileManager.instance.getFolderItemCount(folderName: "coin_images")
    @State private var showClearCacheAlert: Bool = false
    @State private var showCacheClearedToast: Bool = false
    
    private let coingeckoURL = URL(string: "https://www.coingecko.com")!
    private let coingeckoApiURL = URL(string: "https://www.coingecko.com/en/api")!
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // App Brand Hero Header
                        appBrandHeader
                        
                        // Fake Cash Wallet Section
                        cashWalletCard
                        
                        // Trading & Transactions
                        tradingAndTransactionsCard
                        
                        // Data Provider Section
                        dataProviderCard
                        
                        // Storage & Cache Section
                        storageAndCacheCard
                        
                        // App Preferences Section
                        appPreferencesCard
                        
                        // Privacy & Security Card
                        privacySecurityCard
                        
                        // Disclaimer Card
                        disclaimerCard
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if showsDismissButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.accent)
                    }
                }
            }
            .alert("Clear Image Cache", isPresented: $showClearCacheAlert) {
                Button("Clear", role: .destructive) {
                    LocalFileManager.instance.clearFolder(folderName: "coin_images")
                    cachedImageCount = LocalFileManager.instance.getFolderItemCount(folderName: "coin_images")
                    HapticManager.notification(type: .success)
                    withAnimation {
                        showCacheClearedToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showCacheClearedToast = false
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove all downloaded coin icons from local storage. They will be downloaded automatically when needed.")
            }
        }
    }
}

// MARK: - Subviews & Sections
extension SettingsView {
    
    // MARK: - App Brand Header
    private var appBrandHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.theme.accent.opacity(0.15), Color.theme.accent.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.theme.accent.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            
            VStack(spacing: 4) {
                Text("Crypto Tracker")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
                
                Text("Live Market Intelligence & Portfolio Management")
                    .font(.caption)
                    .foregroundStyle(Color.theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 8) {
                Text("v2.0.0")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.theme.accent.opacity(0.1))
                    .clipShape(Capsule())
                    .foregroundStyle(Color.theme.accent)
                
                Text("SwiftUI • CoreData")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.theme.secondaryText.opacity(0.1))
                    .clipShape(Capsule())
                    .foregroundStyle(Color.theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Cash Wallet Card
    private var cashWalletCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Simulated Cash Wallet", icon: "banknote.fill")
            
            NavigationLink {
                CashWalletView()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.green.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.theme.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Available Cash Balance")
                            .font(.caption)
                            .foregroundStyle(Color.theme.secondaryText)
                        
                        Text(vm.cashBalance.asCurrencyWith2Decimals())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text("Manage")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.theme.green.opacity(0.12))
                            .clipShape(Capsule())
                            .foregroundStyle(Color.theme.green)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.theme.secondaryText.opacity(0.6))
                    }
                }
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Trading & Transactions Card
    private var tradingAndTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Trading & Orders", icon: "arrow.left.arrow.right")
            
            NavigationLink {
                TransactionHistoryView()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.accent.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.theme.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Transaction History")
                            .font(.headline)
                            .foregroundStyle(Color.theme.accent)
                        
                        Text("View all recorded buy and sell executions")
                            .font(.caption)
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text("\(vm.transactions.count)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.theme.accent.opacity(0.12))
                            .clipShape(Capsule())
                            .foregroundStyle(Color.theme.accent)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.theme.secondaryText.opacity(0.6))
                    }
                }
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Data Provider Card
    private var dataProviderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Market Data Provider", icon: "chart.xyaxis.line")
            
            HStack(spacing: 12) {
                Image("coingecko")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("CoinGecko API")
                        .font(.headline)
                        .foregroundStyle(Color.theme.accent)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.theme.green)
                            .frame(width: 7, height: 7)
                        
                        Text("Operational • Live Data")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.theme.green)
                    }
                }
                
                Spacer()
            }
            
            Text("Cryptocurrency pricing, 24-hour trade volumes, market capitalizations, and 7-day sparkline charts are provided via CoinGecko's REST API.")
                .font(.footnote)
                .foregroundStyle(Color.theme.secondaryText)
                .lineSpacing(2)
            
            Divider()
            
            HStack(spacing: 12) {
                Link(destination: coingeckoURL) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.caption)
                        Text("CoinGecko Website")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.theme.secondaryText.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Color.theme.accent)
                }
                
                Link(destination: coingeckoApiURL) {
                    HStack(spacing: 6) {
                        Image(systemName: "curlybraces")
                            .font(.caption)
                        Text("API Documentation")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.theme.secondaryText.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Color.theme.accent)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Storage & Cache Card
    private var storageAndCacheCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Data & Storage", icon: "internaldrive.fill")
            
            VStack(spacing: 12) {
                // Portfolio Stats
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "briefcase.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.accent)
                        Text("Portfolio Holdings")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.accent)
                    }
                    Spacer()
                    Text("\(vm.portfolioCoins.count) coins")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Divider()
                
                // Watchlist Stats
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.yellow)
                        Text("Watchlist Assets")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.accent)
                    }
                    Spacer()
                    Text("\(vm.watchlistCoins.count) coins")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                Divider()
                
                // Image Cache Row
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.stack.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.accent)
                        Text("Cached Coin Icons")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.accent)
                    }
                    Spacer()
                    
                    Text("\(cachedImageCount) icons")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.theme.secondaryText)
                }
            }
            .padding(.vertical, 2)
            
            // Clear Cache Action
            Button {
                showClearCacheAlert = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.caption)
                    Text(showCacheClearedToast ? "Cache Cleared!" : "Clear Image Cache")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    showCacheClearedToast ?
                    Color.theme.green.opacity(0.15) :
                    Color.theme.secondaryText.opacity(0.08)
                )
                .foregroundStyle(showCacheClearedToast ? Color.theme.green : Color.theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - App Preferences Card
    private var appPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Preferences & System", icon: "slider.horizontal.3")
            
            VStack(spacing: 12) {
                preferenceRow(title: "Base Currency", value: "USD ($)", icon: "dollarsign.circle.fill")
                Divider()
                preferenceRow(title: "Storage Engine", value: "Apple CoreData", icon: "cylinder.split.1x2.fill")
                Divider()
                preferenceRow(title: "Theme Mode", value: "System Adaptive", icon: "circle.lefthalf.filled")
                Divider()
                preferenceRow(title: "Haptic Feedback", value: "Enabled", icon: "hand.tap.fill")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func preferenceRow(title: String, value: String, icon: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.accent)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.accent)
            }
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.theme.secondaryText)
        }
    }
    
    // MARK: - Privacy & Security Card
    private var privacySecurityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Privacy & Security", icon: "lock.shield.fill")
            
            Text("Your financial privacy is paramount. Crypto Tracker does not require account creation, does not track telemetry, and stores 100% of your portfolio holdings and watchlist securely on your physical device using Apple CoreData.")
                .font(.footnote)
                .foregroundStyle(Color.theme.secondaryText)
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Disclaimer Card
    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Legal Disclaimer", icon: "exclamationmark.triangle.fill")
            
            Text("All cryptocurrency prices, historical charts, portfolio valuations, and calculations provided within this application are for informational purposes only. Nothing contained herein constitutes financial, investment, or legal advice.")
                .font(.caption2)
                .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.secondaryText.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.secondaryText.opacity(0.08), lineWidth: 1)
        )
        .padding(.bottom, 16)
    }
    
    // MARK: - Reusable Section Header
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.theme.accent)
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.accent)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DeveloperPreview.instance.homeVM)
}
