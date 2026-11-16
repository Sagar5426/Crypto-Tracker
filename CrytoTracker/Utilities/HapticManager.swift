//
//  HapticManager.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 29/09/2025.
//

import SwiftUI

class HapticManager {
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "haptics_enabled") as? Bool ?? true
    }
    
    static private let notificationGenerator = UINotificationFeedbackGenerator()
    
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(type)
    }
    
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
