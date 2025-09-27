//
//  UIApplication.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 27/09/2025.
//

import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
