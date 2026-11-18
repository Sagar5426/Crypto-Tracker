//
//  Color.swift
//  CoinPilot
//
//  Created by Sagar Jangra on 30/07/2025.
//

import SwiftUI

extension Color {
    static let theme = ColorTheme() //singleton
    static let launch = LaunchTheme()
}

struct ColorTheme {
    let accent = Color("AccentColor")
    let background = Color("BackgroundColor")
    let green = Color("MyGreenColor")
    let red = Color("MyRedColor")
    let secondaryText = Color("SecondaryTextColor")
    
    /// System-adaptive canvas background (pure OLED black in dark mode, standard #F2F2F7 grouped background in light mode)
    var screenBackground: Color {
        Color(uiColor: .systemGroupedBackground)
    }
    
    /// Adaptive card and container surface (pure white #FFFFFF in light mode, elevated #121212 in dark mode)
    var cardBackground: Color {
        Color("BackgroundColor")
    }
}

struct LaunchTheme {
    let accent = Color("LaunchAccentColor")
    let background = Color("LaunchBackgroundColor")
}
