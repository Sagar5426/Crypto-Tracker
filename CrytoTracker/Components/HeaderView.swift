//
//  HeaderView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 15/11/2026.
//

import SwiftUI

struct HeaderView: View {
    let title: String
    @Binding var showSearchBar: Bool
    @Binding var searchText: String
    var isLoading: Bool = false
    var onRefresh: (() -> Void)? = nil
    
    @State private var isSpinning: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Main Top Bar
            HStack(alignment: .center, spacing: 12) {
                // Title + Live Badge
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.accent)
                    
                    // Live Indicator Badge
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
                
                Spacer()
                
                // Trailing Action Buttons
                HStack(spacing: 12) {
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
                    
                    // Search Toggle Button (kept in original top header position)
                    Button {
                        HapticManager.notification(type: .success)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showSearchBar.toggle()
                            if !showSearchBar {
                                searchText = ""
                                UIApplication.shared.endEditing()
                            }
                        }
                    } label: {
                        Image(systemName: showSearchBar ? "xmark" : "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(showSearchBar ? Color.theme.red : Color.theme.accent)
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(showSearchBar ? Color.theme.red.opacity(0.12) : Color.theme.secondaryText.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            
            // Expandable Search Bar in its original top header position
            if showSearchBar {
                SearchBarView(searchText: $searchText)
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
            isLoading: false
        )
    }
}
