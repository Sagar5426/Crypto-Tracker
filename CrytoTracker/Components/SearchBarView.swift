//
//  SearchBarView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 27/09/2025.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundStyle(searchText.isEmpty ? Color.theme.secondaryText : Color.theme.accent)
            
            TextField("Search by name or symbol...", text: $searchText)
                .font(.subheadline)
                .foregroundStyle(Color.theme.accent)
                .autocorrectionDisabled(true)
            
            if !searchText.isEmpty {
                Button {
                    UIApplication.shared.endEditing()
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.theme.background)
                .shadow(color: Color.theme.accent.opacity(0.06), radius: 6, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.theme.secondaryText.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

#Preview {
    SearchBarView(searchText: .constant(""))
}
