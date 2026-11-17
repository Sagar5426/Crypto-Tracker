//
//  SettingsView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 03/10/2025.
//

import SwiftUI
import SwiftfulUI

@MainActor
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var vm: MarketViewModel
    
    // MARK: - View Model
    @StateObject private var viewModel: SettingsViewModel
    
    var showsDismissButton: Bool = false
    
    // MARK: - Layout State
    @State private var scrollViewOffset: CGFloat = 0
    @State private var fullHeaderSize: CGSize = .zero
    
    // MARK: - Initializer
    
    init(viewModel: SettingsViewModel? = nil, showsDismissButton: Bool = false) {
        self._viewModel = StateObject(wrappedValue: viewModel ?? SettingsViewModel())
        self.showsDismissButton = showsDismissButton
    }
    
    // MARK: - Layout & Header Fade Progress
    
    /// Header blur backdrop opacity eases in smoothly as user scrolls past 30pt
    private var headerBackgroundOpacity: Double {
        min(1.0, max(0.0, -scrollViewOffset / 30.0))
    }
    
    /// Content fade opacity for the ambient glow
    private var contentFadeOpacity: Double {
        max(0.0, 1.0 - min(1.0, max(0.0, -scrollViewOffset / 200.0)))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background & ambient glow
                Color.theme.screenBackground
                    .ignoresSafeArea()
                
                ambientGlowLayer
                
                // Scrollable content that scrolls through and underneath the sticky header
                scrollViewLayer
                
                // Sticky Header View with blur backdrop (pinned at top)
                stickyHeaderView
                
                // Floating Toast Banner
                if let message = viewModel.toastMessage {
                    toastBanner(message: message)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.setMarketViewModel(vm)
                viewModel.updateCacheCount()
            }
            .alert("Clear Image Cache", isPresented: $viewModel.showClearCacheAlert) {
                Button("Clear", role: .destructive) {
                    viewModel.clearImageCache()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will delete all cached coin icons from local storage. They will reload automatically when needed.")
            }
            .alert("Reset Cash Wallet", isPresented: $viewModel.showResetWalletAlert) {
                Button("Reset to $10,000", role: .destructive) {
                    viewModel.resetCashWallet()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will restore your wallet fund balance to the default $10,000.00.")
            }
            .fullScreenCover(isPresented: $viewModel.showProfitAndLossView) {
                NavigationStack {
                    ProfitAndLossView()
                }
            }
            .fullScreenCover(isPresented: $viewModel.showTradeBookView) {
                NavigationStack {
                    TradeBookView()
                }
            }
        }
    }
}

// MARK: - Ambient Background, Top Bar & Main Scroll Content
extension SettingsView {
    
    private var ambientGlowLayer: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: (colorScheme == .dark ? Color.theme.accent.opacity(0.12) : Color.theme.green.opacity(0.06)), location: 0.0),
                    .init(color: (colorScheme == .dark ? Color.theme.accent.opacity(0.04) : Color.theme.green.opacity(0.02)), location: 0.3),
                    .init(color: Color.clear, location: 0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            RadialGradient(
                gradient: Gradient(colors: [
                    (colorScheme == .dark ? Color.theme.accent.opacity(0.10) : Color.theme.green.opacity(0.05)),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 20,
                endRadius: 280
            )
        }
        .ignoresSafeArea(edges: .top)
        .frame(height: 320 + max(0, scrollViewOffset))
        .offset(y: min(0, scrollViewOffset))
        .opacity(contentFadeOpacity)
        .allowsHitTesting(false)
    }
    
    // MARK: - Sticky Top Header Bar (Using HeaderView with Blur Backdrop)
    private var stickyHeaderView: some View {
        HeaderView(
            title: "Settings",
            isLoading: viewModel.isLoading,
            showProBadge: true,
            showSearchButton: false,
            showsDismissButton: showsDismissButton,
            onRefresh: {
                viewModel.refreshMarketData()
            },
            onDismiss: {
                dismiss()
            }
        )
        .padding(.bottom, 8)
        .background(
            ZStack {
                Rectangle()
                    .fill(Color.clear)
                    .background(.ultraThinMaterial)
                    .overlay(colorScheme == .dark ? Color.black.opacity(0.35) : Color.clear)
                    .ignoresSafeArea(edges: .top)
                
                // Subtle bottom separator line
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.theme.secondaryText.opacity(0.12))
                        .frame(height: 0.5)
                }
            }
            .opacity(headerBackgroundOpacity)
        )
        .animation(.smooth, value: scrollViewOffset)
        .readingFrame { frame in
            if abs(fullHeaderSize.height - frame.size.height) > 1 && frame.size.height > 0 {
                fullHeaderSize = frame.size
            }
        }
    }
    
    // MARK: - Main Scroll Layer
    private var scrollViewLayer: some View {
        ScrollViewWithOnScrollChanged(
            .vertical,
            showsIndicators: false,
            content: {
                VStack(spacing: 22) {
                    // Spacer equal to header height so content begins directly below sticky header
                    Rectangle()
                        .opacity(0)
                        .frame(height: max(50, fullHeaderSize.height))
                    
                    // Hero Fintech App / Profile Card
                    heroProfileCard
                    
                    // Section 1: Financial & Trading Operations
                    financialTradingSection
                    
                    // Section 2: Preferences & Interface
                    preferencesSection
                    
                    // Section 3: Data & Local Storage
                    storageDataSection
                    
                    // Section 4: Market Data Ecosystem
                    marketDataSection
                    
                    // Section 5: Security & Privacy
                    securityPrivacySection
                    
                    // Section 6: Legal & App Info
                    legalAppInfoSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 36)
            },
            onScrollChanged: { offset in
                scrollViewOffset = min(0, offset.y)
            }
        )
        .refreshable {
            viewModel.refreshMarketData()
        }
    }
}

// MARK: - Hero Profile Card
extension SettingsView {
    
    private var heroProfileCard: some View {
        VStack(spacing: 16) {
            // App Branding Header
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.theme.accent.opacity(colorScheme == .dark ? 0.18 : 0.08),
                                    Color.theme.accent.opacity(colorScheme == .dark ? 0.05 : 0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.theme.secondaryText.opacity(colorScheme == .dark ? 0.12 : 0.15), lineWidth: 1)
                        )
                    
                    if colorScheme == .dark {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: Color.theme.accent.opacity(0.2), radius: 6, x: 0, y: 3)
                    } else {
                        Image("logo-transparent")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundStyle(Color.theme.accent)
                            .shadow(color: Color.theme.accent.opacity(0.08), radius: 6, x: 0, y: 3)
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Crypto Tracker")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.theme.accent)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.theme.green)
                    }
                    
                    Text("Live Intelligence & Portfolio Ledger")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText)
                    
                    HStack(spacing: 6) {
                        badgeTag("v2.0.0", color: Color.theme.accent)
                        badgeTag("CoreData", color: Color.theme.secondaryText)
                        badgeTag("Offline First", color: Color.theme.green)
                    }
                    .padding(.top, 2)
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.theme.secondaryText.opacity(0.12))
            
            // Financial Snapshot Strip
            HStack(spacing: 8) {
                heroMetricItem(
                    title: "Cash Balance",
                    value: viewModel.cashBalance.asCurrencyWith2Decimals(),
                    color: Color.theme.green
                )
                
                Divider()
                    .frame(height: 28)
                    .background(Color.theme.secondaryText.opacity(0.15))
                
                heroMetricItem(
                    title: "Portfolio",
                    value: "\(viewModel.portfolioCoinsCount) Coins",
                    color: Color.theme.accent
                )
                
                Divider()
                    .frame(height: 28)
                    .background(Color.theme.secondaryText.opacity(0.15))
                
                heroMetricItem(
                    title: "Watchlist",
                    value: "\(viewModel.watchlistCoinsCount) Coins",
                    color: Color.yellow
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.04), radius: 8, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.theme.secondaryText.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    private func heroMetricItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.theme.secondaryText)
            
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func badgeTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9.5, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .foregroundStyle(color)
    }
}

// MARK: - Section 1: Financial & Trading Operations
extension SettingsView {
    
    private var financialTradingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "FINANCIAL & TRADING")
            
            VStack(spacing: 0) {
                // 1. Cash Wallet Row
                NavigationLink {
                    CashWalletView()
                } label: {
                    settingsRow(
                        icon: "banknote.fill",
                        iconColor: Color.theme.green,
                        title: "Wallet Fund",
                        subtitle: "Deposit, withdraw & test capital",
                        trailingContent: AnyView(
                            HStack(spacing: 6) {
                                Text(viewModel.cashBalance.asCurrencyWith2Decimals())
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.theme.green)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.theme.secondaryText.opacity(0.5))
                            }
                        )
                    )
                }
                .buttonStyle(.plain)
                
                rowDivider
                
                // 2. Profit and Loss Row
                Button {
                    viewModel.showProfitAndLossView = true
                } label: {
                    let pnl = viewModel.netTotalPnL
                    let isPositive = pnl >= 0
                    let pnlColor = isPositive ? Color.theme.green : Color.theme.red
                    
                    settingsRow(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: Color.blue,
                        title: "Profit & Loss Analytics",
                        subtitle: "Realized trades & returns breakdown",
                        trailingContent: AnyView(
                            HStack(spacing: 6) {
                                Text(pnl.asCurrencyWith2Decimals())
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(pnlColor)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.theme.secondaryText.opacity(0.5))
                            }
                        )
                    )
                }
                .buttonStyle(.plain)
                
                rowDivider
                
                // 3. TradeBook Row
                Button {
                    viewModel.showTradeBookView = true
                } label: {
                    settingsRow(
                        icon: "book.closed.fill",
                        iconColor: Color.orange,
                        title: "TradeBook Ledger",
                        subtitle: "Complete order execution history",
                        trailingContent: AnyView(
                            HStack(spacing: 6) {
                                Text("\(viewModel.cryptoTradesCount) Orders")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2.5)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundStyle(Color.orange)
                                    .clipShape(Capsule())
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.theme.secondaryText.opacity(0.5))
                            }
                        )
                    )
                }
                .buttonStyle(.plain)
            }
            .background(sectionContainerBackground)
        }
    }
}

// MARK: - Section 2: Preferences & Interface
extension SettingsView {
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "PREFERENCES & CONTROLS")
            
            VStack(spacing: 0) {
                // Haptic Feedback Toggle
                settingsRow(
                    icon: "hand.tap.fill",
                    iconColor: Color.purple,
                    title: "Haptic Feedback",
                    subtitle: "Tactile response on gestures & trades",
                    trailingContent: AnyView(
                        Toggle("", isOn: $viewModel.hapticsEnabled)
                            .labelsHidden()
                            .tint(Color.green)
                    )
                )
                
                rowDivider
                
                // Compact Numbers Toggle
                settingsRow(
                    icon: "number.circle.fill",
                    iconColor: Color.cyan,
                    title: "Compact Metrics",
                    subtitle: "Shorten large numbers ($1.2M, $45.6K)",
                    trailingContent: AnyView(
                        Toggle("", isOn: $viewModel.compactNumbers)
                            .labelsHidden()
                            .tint(Color.green)
                    )
                )
                
                rowDivider
                
                // Auto Refresh Toggle
                settingsRow(
                    icon: "arrow.clockwise.circle.fill",
                    iconColor: Color.mint,
                    title: "Live Market Sync",
                    subtitle: "Auto-refresh rates periodically",
                    trailingContent: AnyView(
                        Toggle("", isOn: $viewModel.autoRefreshEnabled)
                            .labelsHidden()
                            .tint(Color.green)
                    )
                )
                
                rowDivider
                
                // Currency Selector Menu
                Menu {
                    Picker("Select Currency", selection: $viewModel.selectedCurrency) {
                        ForEach(viewModel.supportedCurrencies, id: \.self) { curr in
                            Text(curr).tag(curr)
                        }
                    }
                } label: {
                    settingsRow(
                        icon: "dollarsign.circle.fill",
                        iconColor: Color.yellow,
                        title: "Base Currency",
                        subtitle: "Display currency for prices & metrics",
                        trailingContent: AnyView(
                            HStack(spacing: 4) {
                                Text(viewModel.selectedCurrency)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.theme.accent)
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.theme.secondaryText)
                            }
                        )
                    )
                }
                .buttonStyle(.plain)
            }
            .background(sectionContainerBackground)
        }
    }
}

// MARK: - Section 3: Data & Local Storage
extension SettingsView {
    
    private var storageDataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "DATA & LOCAL STORAGE")
            
            VStack(spacing: 0) {
                // Storage Engine Status
                settingsRow(
                    icon: "cylinder.split.1x2.fill",
                    iconColor: Color.indigo,
                    title: "Storage Engine",
                    subtitle: "Apple CoreData with encrypted SQLite",
                    trailingContent: AnyView(
                        Text("On-Device")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.theme.green.opacity(0.12))
                            .foregroundStyle(Color.theme.green)
                            .clipShape(Capsule())
                    )
                )
                
                rowDivider
                
                // Image Cache Management
                settingsRow(
                    icon: "photo.stack.fill",
                    iconColor: Color.pink,
                    title: "Coin Icon Cache",
                    subtitle: "\(viewModel.cachedImageCount) icons stored on disk",
                    trailingContent: AnyView(
                        Button {
                            viewModel.showClearCacheAlert = true
                        } label: {
                            Text("Clear")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.theme.secondaryText.opacity(0.1))
                                .foregroundStyle(Color.theme.accent)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    )
                )
                
                rowDivider
                
                // Reset Simulated Cash
                settingsRow(
                    icon: "arrow.counterclockwise.circle.fill",
                    iconColor: Color.orange,
                    title: "Reset Cash Wallet",
                    subtitle: "Restore balance to $10,000.00",
                    trailingContent: AnyView(
                        Button {
                            viewModel.showResetWalletAlert = true
                        } label: {
                            Text("Reset")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.orange.opacity(0.12))
                                .foregroundStyle(Color.orange)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    )
                )
            }
            .background(sectionContainerBackground)
        }
    }
}

// MARK: - Section 4: Market Data Ecosystem
extension SettingsView {
    
    private var marketDataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "MARKET DATA PROVIDER")
            
            VStack(spacing: 14) {
                // CoinGecko Header
                HStack(spacing: 12) {
                    Image("coingecko")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CoinGecko REST API")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.theme.accent)
                        
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.theme.green)
                                .frame(width: 6, height: 6)
                            
                            Text("Operational • Live Market Stream")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.theme.green)
                        }
                    }
                    
                    Spacer()
                }
                
                Text("Prices, 24-hour trading volumes, market capitalizations, high/low records, and 7-day sparklines are supplied by CoinGecko's cryptocurrency API.")
                    .font(.footnote)
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineSpacing(2)
                
                Divider()
                    .background(Color.theme.secondaryText.opacity(0.12))
                
                // Action Links
                HStack(spacing: 10) {
                    Link(destination: viewModel.coingeckoURL) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.caption)
                            Text("CoinGecko Web")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                
                            Spacer(minLength: 2)
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.theme.secondaryText.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Color.theme.accent)
                    }
                    
                    Link(destination: viewModel.coingeckoApiURL) {
                        HStack(spacing: 6) {
                            Image(systemName: "curlybraces")
                                .font(.caption)
                            Text("API Docs")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Spacer(minLength: 2)
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.theme.secondaryText.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Color.theme.accent)
                    }
                }
            }
            .padding(16)
            .background(sectionContainerBackground)
        }
    }
}

// MARK: - Section 5 & 6: Security, Privacy & Legal
extension SettingsView {
    
    private var securityPrivacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "SECURITY & FINANCIAL PRIVACY")
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.green.opacity(0.14))
                            .frame(width: 32, height: 32)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.theme.green)
                    }
                    
                    Text("100% On-Device Storage")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.theme.accent)
                }
                
                Text("Crypto Tracker does not require account registration, does not collect analytics telemetry, and never uploads your portfolio holdings or trade history to external servers. All personal financial data resides exclusively inside local CoreData storage.")
                    .font(.footnote)
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineSpacing(2)
            }
            .padding(16)
            .background(sectionContainerBackground)
        }
    }
    
    private var legalAppInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "ABOUT & LEGAL")
            
            VStack(spacing: 0) {
                // Version & Build
                settingsRow(
                    icon: "info.circle.fill",
                    iconColor: Color.theme.secondaryText,
                    title: "Application Version",
                    subtitle: "Native SwiftUI & Combine engine",
                    trailingContent: AnyView(
                        Text("2.0.0 (42)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.theme.secondaryText)
                    )
                )
                
                rowDivider
                
                // Legal Disclaimer
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.yellow)
                        
                        Text("Financial Disclaimer")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.theme.accent)
                    }
                    
                    Text("Cryptocurrency values fluctuate substantially. All data and calculations within Crypto Tracker are provided solely for educational and portfolio simulation purposes, and do not constitute financial, investment, tax, or legal advice.")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.secondaryText.opacity(0.8))
                        .lineSpacing(2)
                }
                .padding(14)
            }
            .background(sectionContainerBackground)
        }
    }
}

// MARK: - Reusable UI Components & Helpers
extension SettingsView {
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(Color.theme.secondaryText)
            .padding(.leading, 6)
            .padding(.top, 4)
    }
    
    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        trailingContent: AnyView
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 34, height: 34)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.theme.accent)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 8)
            
            trailingContent
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private var rowDivider: some View {
        Divider()
            .background(Color.theme.secondaryText.opacity(0.10))
            .padding(.leading, 56)
    }
    
    private var sectionContainerBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.theme.background)
            .shadow(color: Color.theme.accent.opacity(0.04), radius: 6, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.theme.secondaryText.opacity(0.10), lineWidth: 1)
            )
    }
    
    private func toastBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.theme.green)
            Text(message)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.theme.background)
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 5)
                .overlay(
                    Capsule()
                        .stroke(Color.theme.green.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.top, 10)
    }
}

#Preview {
    SettingsView()
        .environmentObject(DeveloperPreview.instance.homeVM)
}
