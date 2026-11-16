//
//  LaunchView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 04/10/2025.
//

import SwiftUI
import Combine

struct LaunchView: View {
    @Binding var showLaunchView: Bool
    
    // Wave animation characters
    @State private var loadingText: [String] = "Loading your portfolio...".map { String($0) }
    @State private var showElements: Bool = false
    @State private var counter: Int = 0
    @State private var progress: CGFloat = 0.0
    @State private var pulseAura: Bool = false
    @State private var logoScale: CGFloat = 0.92
    @State private var isDismissing: Bool = false
    
    // Timer for wave ripple and progress bar (~20 ticks/sec)
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    private let totalTicks: CGFloat = 38.0 // ~1.9 seconds total
    
    var body: some View {
        ZStack {
            // Background with ambient radial glow centered behind logo
            Color.launch.background
                .ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    Color.launch.accent.opacity(pulseAura ? 0.18 : 0.06),
                    Color.launch.background
                ],
                center: UnitPoint(x: 0.5, y: 0.44),
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulseAura)
            
            // Logo & Halo Rings moved above center to prevent overlapping text
            ZStack {
                // Outer glowing pulse ring
                Circle()
                    .stroke(Color.launch.accent.opacity(pulseAura ? 0.22 : 0.05), lineWidth: 1.5)
                    .frame(width: 145, height: 145)
                    .scaleEffect(pulseAura ? 1.12 : 0.95)
                
                // Inner pulse ring
                Circle()
                    .stroke(Color.launch.accent.opacity(pulseAura ? 0.42 : 0.12), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAura ? 1.06 : 0.96)
                
                // App Logo
                Image("logo-transparent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .scaleEffect(logoScale)
                    .shadow(color: Color.launch.accent.opacity(0.35), radius: 14, x: 0, y: 0)
            }
            .offset(y: -45)
            
            // Text & Progress section positioned comfortably below the rings
            VStack(spacing: 10) {
                // App Branding Title
                Text("CRYPTO TRACKER")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .tracking(3.5)
                    .foregroundStyle(Color.launch.accent)
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 8)
                
                // Animated wave text
                HStack(spacing: 0) {
                    ForEach(loadingText.indices, id: \.self) { index in
                        let isPeak = counter == index
                        let isAdjacent = counter - 1 == index || counter + 1 == index
                        
                        Text(loadingText[index])
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                isPeak
                                    ? Color.launch.accent
                                    : isAdjacent
                                        ? Color.launch.accent.opacity(0.8)
                                        : Color.launch.accent.opacity(0.5)
                            )
                            .offset(y: isPeak ? -5 : (isAdjacent ? -2.5 : 0))
                    }
                }
                .opacity(showElements ? 1.0 : 0.0)
                .offset(y: showElements ? 0 : 6)
                
                // Sleek progress bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.launch.accent.opacity(0.18))
                        .frame(width: 150, height: 3.5)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.launch.accent.opacity(0.6),
                                    Color.launch.accent
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(3.5, 150 * progress), height: 3.5)
                        .shadow(color: Color.launch.accent.opacity(0.6), radius: 4, x: 0, y: 0)
                }
                .padding(.top, 4)
                .opacity(showElements ? 1.0 : 0.0)
            }
            .offset(y: 90)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissLaunch()
        }
        .onAppear {
            startAnimation()
        }
        .onReceive(timer) { _ in
            handleTimerTick()
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeOut(duration: 0.55)) {
            showElements = true
            logoScale = 1.0
        }
        
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            pulseAura = true
        }
    }
    
    private func handleTimerTick() {
        guard !isDismissing else { return }
        
        // Progress step
        progress = min(1.0, progress + (1.0 / totalTicks))
        
        // Letter wave step
        withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
            let lastIndex = loadingText.count - 1
            if counter > lastIndex {
                counter = 0
            } else {
                counter += 1
            }
        }
        
        // When completed, auto-dismiss with gentle delay
        if progress >= 1.0 {
            isDismissing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                dismissLaunch()
            }
        }
    }
    
    private func dismissLaunch() {
        guard showLaunchView else { return }
        isDismissing = true
        HapticManager.impact(style: .light)
        withAnimation(.easeInOut(duration: 0.45)) {
            showLaunchView = false
        }
    }
}

#Preview {
    LaunchView(showLaunchView: .constant(true))
}
