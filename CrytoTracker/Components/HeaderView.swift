//
//  HeaderView.swift
//  CoinPilot
//
//  Created by Sagar Jangra on 15/11/2026.
//

import SwiftUI

extension View {
    /// Applies Apple's native Liquid Glass effect when running on supported OS,
    /// falling back gracefully to ultraThinMaterial blur.
    @ViewBuilder
    func appleGlassEffect() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular)
        } else {
            self.background(.ultraThinMaterial)
        }
    }
}

struct HeaderView: View {
    let title: String
    var showSearchBar: Binding<Bool>? = nil
    var searchText: Binding<String>? = nil
    var isLoading: Bool = false
    var showLiveBadge: Bool = false
    var showProBadge: Bool = false
    var showSearchButton: Bool = true
    var showsDismissButton: Bool = false
    var onRefresh: (() -> Void)? = nil
    var onAdd: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    
    @State private var isSpinning: Bool = false
    
    init(
        title: String,
        showSearchBar: Binding<Bool>? = nil,
        searchText: Binding<String>? = nil,
        isLoading: Bool = false,
        showLiveBadge: Bool = false,
        showProBadge: Bool = false,
        showSearchButton: Bool = true,
        showsDismissButton: Bool = false,
        onRefresh: (() -> Void)? = nil,
        onAdd: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.showSearchBar = showSearchBar
        self.searchText = searchText
        self.isLoading = isLoading
        self.showLiveBadge = showLiveBadge
        self.showProBadge = showProBadge
        self.showSearchButton = showSearchButton
        self.showsDismissButton = showsDismissButton
        self.onRefresh = onRefresh
        self.onAdd = onAdd
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Main Top Bar
            HStack(alignment: .center, spacing: 12) {
                // Title + Live / Pro Badge
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                    
                    // Live Indicator Badge (only shown when enabled, e.g. in Markets tab)
                    if showLiveBadge {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.theme.green)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.theme.green)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.theme.green.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    
                    // PRO Badge (e.g. in Settings tab)
                    if showProBadge {
                        Text("PRO")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Color.theme.background)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Color.theme.accent)
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                // Trailing Action Buttons
                HStack(spacing: 12) {
                    // Optional Add Button (e.g. for Portfolio)
                    if let onAdd = onAdd {
                        Button {
                            HapticManager.notification(type: .success)
                            onAdd()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.theme.accent)
                                .frame(width: 38, height: 38)
                                .background(
                                    Circle()
                                        .fill(Color.theme.secondaryText.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Refresh Button
                    Button {
                        HapticManager.notification(type: .success)
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isSpinning.toggle()
                        }
                        onRefresh?()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.theme.accent)
                            .rotationEffect(.degrees(isLoading || isSpinning ? 360 : 0))
                            .animation(
                                isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: isLoading
                            )
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(Color.theme.secondaryText.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // Search Toggle Button (in top header, when enabled)
                    if showSearchButton, let showSearchBar = showSearchBar {
                        Button {
                            HapticManager.notification(type: .success)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showSearchBar.wrappedValue.toggle()
                                if !showSearchBar.wrappedValue {
                                    searchText?.wrappedValue = ""
                                    UIApplication.shared.endEditing()
                                }
                            }
                        } label: {
                            Image(systemName: showSearchBar.wrappedValue ? "xmark" : "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(showSearchBar.wrappedValue ? Color.theme.red : Color.theme.accent)
                                .frame(width: 38, height: 38)
                                .background(
                                    Circle()
                                        .fill(showSearchBar.wrappedValue ? Color.theme.red.opacity(0.12) : Color.theme.secondaryText.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Optional Dismiss Button (e.g. for modal screens)
                    if showsDismissButton, let onDismiss = onDismiss {
                        Button {
                            onDismiss()
                        } label: {
                            Text("Close")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.theme.accent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color.theme.secondaryText.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Expandable Search Bar in top header
            if let showSearchBar = showSearchBar, let searchText = searchText, showSearchBar.wrappedValue && showSearchButton {
                SearchBarView(searchText: searchText)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    ZStack {
        Color.theme.background.ignoresSafeArea()
        HeaderView(
            title: "Markets",
            showSearchBar: .constant(false),
            searchText: .constant(""),
            isLoading: false,
            showLiveBadge: true
        )
    }
}
