//
//  HapticManager.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 29/09/2025.
//

import SwiftUI

class HapticManager {
    static private let notificationGenerator = UINotificationFeedbackGenerator()
    
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }
    
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

