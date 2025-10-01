//
//  HapticManager.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 29/09/2025.
//

import SwiftUI

class HapticManager {
    static private let generator = UINotificationFeedbackGenerator()
    
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        generator.notificationOccurred(type)
    }
}

