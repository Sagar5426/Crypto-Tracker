//
//  Color.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 30/07/2025.
//

import SwiftUI

extension Color {
    static let theme = ColorTheme() //singleton
    static let launch = LaunchTheme()
}

struct ColorTheme{
    let accent = Color("AccentColor")
    let background = Color("BackgroundColor")
    let green = Color("GreenColor")
    let red = Color("RedColor")
    let secondaryText = Color("SecondaryTextColor")
    
}

struct LaunchTheme {
    
    let accent = Color("LaunchAccentColor")
    let background = Color("LaunchBackgroundColor")
    
}
