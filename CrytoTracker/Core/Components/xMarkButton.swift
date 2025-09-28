//
//  xMarkButton.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 28/09/2025.
//

import SwiftUI

struct xMarkButton: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.headline)
        }
    }
}

#Preview {
    xMarkButton()
}
