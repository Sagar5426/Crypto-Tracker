//
//  CrytoTrackerApp.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 30/07/2025.
//

import SwiftUI

@main
struct CrytoTrackerApp: App {
    @StateObject private var vm = MarketViewModel()
    @State private var showLaunchView: Bool = true
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color.theme.accent)]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color.theme.accent)]
        
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environmentObject(vm)
                
                // Added additional ZStack to avoid animation bug while transitioning
                ZStack {
                    if showLaunchView {
                        // for transitioning from launch screen to this
                        LaunchView(showLaunchView: $showLaunchView)
                            .transition(.move(edge: .leading))
                    }
                }
                .zIndex(2.0)
            }
            .dynamicTypeSize(.large)
        }
    }
}
