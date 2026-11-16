//
//  LaunchView.swift
//  CryptoTracker
//
//  Created by Sagar Jangra on 04/10/2025.
//  Refined with Subtle Ambiance, Exact 2s Timing, and Synchronized Waves.
//

import SwiftUI
import Combine

struct LaunchView: View {
    @Binding var showLaunchView: Bool
    
    // Core Animation States
    @State private var loadingText: [String] = "Loading your portfolio...".map { String($0) }
    @State private var counter: Int = -1
    @State private var progress: CGFloat = 0.0
    
    // Staggered Entrance Phases
    @State private var phase: LaunchPhase = .idle
    
    // Continuous Ambient States
    @State private var pulseGlow: Bool = false
    @State private var isDismissing: Bool = false
    
    // 2.0 seconds total duration at ~33 ticks/sec (60 ticks total)
    private let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()
    private let totalTicks: CGFloat = 60.0
    
    enum LaunchPhase {
        case idle
        case backgroundIn
        case logoIn
        case contentIn
        case active
    }
    
    var body: some View {
        ZStack {
            // 1. Immersive Deep Background
            Color.launch.background
                .ignoresSafeArea()
            
            // 2. Ultra-Subtle Radial Background Glow (Very low intensity & tight spread)
            RadialGradient(
                colors: [
                    Color.launch.accent.opacity(pulseGlow ? 0.08 : 0.02),
                    Color.launch.background.opacity(0.0)
                ],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 5,
                endRadius: 140
            )
            .ignoresSafeArea()
            .scaleEffect(phase == .idle ? 0.6 : 1.0)
            .opacity(phase == .idle ? 0.0 : 1.0)
            .animation(.easeOut(duration: 1.0), value: phase)
            
            // 3. Central Logo & Layered Halo Rings
            ZStack {
                // Outer Ambient Ring
                Circle()
                    .stroke(Color.launch.accent.opacity(pulseGlow ? 0.15 : 0.02), lineWidth: 1)
                    .frame(width: 150, height: 150)
                    .scaleEffect(pulseGlow ? 1.06 : 0.98)
                
                // Inner Core Ring with Accent Gradient
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.launch.accent.opacity(0.35), Color.launch.accent.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 115, height: 115)
                    .scaleEffect(pulseGlow ? 1.02 : 0.99)
                
                // App Logo with Depth Shadow & Tilt Entry
                Image("logo-transparent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.launch.accent.opacity(0.35), radius: 14, x: 0, y: 6)
            }
            .scaleEffect(logoScaleForCurrentPhase())
            .rotationEffect(.degrees(phase == .idle ? -10 : 0))
            .opacity(phase == .idle ? 0 : 1)
            .offset(y: -48)
            
            // 4. Typography & Sleek Progress Section
            VStack(spacing: 16) {
                // App Branding Title
                Text("CRYPTO TRACKER")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .tracking(4.5)
                    .foregroundStyle(Color.launch.accent)
                
                // Wave Text Animation
                HStack(spacing: 1) {
                    ForEach(loadingText.indices, id: \.self) { index in
                        let isPeak = counter == index
                        let isAdjacent = (counter - 1 == index) || (counter + 1 == index)
                        
                        Text(loadingText[index])
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(
                                isPeak
                                    ? Color.launch.accent
                                    : isAdjacent
                                    ? Color.launch.accent.opacity(0.75)
                                    : Color.launch.accent.opacity(0.4)
                            )
                            .offset(y: isPeak ? -5 : (isAdjacent ? -2 : 0))
                    }
                }
                
                // Sleek Custom Capsule Progress Bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.launch.accent.opacity(0.15))
                        .frame(width: 150, height: 3.5)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.launch.accent.opacity(0.5), Color.launch.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(3.5, 150 * smoothProgress()), height: 3.5)
                        .shadow(color: Color.launch.accent.opacity(0.6), radius: 5, x: 0, y: 0)
                }
                .padding(.top, 2)
            }
            .offset(y: 86)
            .opacity(contentOpacityForCurrentPhase())
            .offset(y: contentOffsetYForCurrentPhase())
        }
        .scaleEffect(isDismissing ? 1.04 : 1.0)
        .opacity(isDismissing ? 0.0 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissLaunch()
        }
        .onAppear {
            runEntranceSequence()
        }
        .onReceive(timer) { _ in
            handleTimerTick()
        }
    }
    
    // MARK: - Phase Animation Helpers
    
    private func runEntranceSequence() {
        withAnimation(.easeOut(duration: 0.35)) {
            phase = .backgroundIn
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                phase = .logoIn
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                phase = .contentIn
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            phase = .active
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
        }
    }
    
    private func logoScaleForCurrentPhase() -> CGFloat {
        switch phase {
        case .idle: return 0.8
        case .backgroundIn: return 0.85
        case .logoIn, .contentIn, .active: return 1.0
        }
    }
    
    private func contentOpacityForCurrentPhase() -> Double {
        switch phase {
        case .idle, .backgroundIn, .logoIn: return 0.0
        case .contentIn, .active: return 1.0
        }
    }
    
    private func contentOffsetYForCurrentPhase() -> CGFloat {
        switch phase {
        case .idle, .backgroundIn, .logoIn: return 10.0
        case .contentIn, .active: return 0.0
        }
    }
    
    private func smoothProgress() -> CGFloat {
        let p = progress
        // Smooth easing curve mapped strictly over 2.0s
        return p < 0.5 ? 2 * p * p : -1 + (4 - 2 * p) * p
    }
    
    // MARK: - Tick & Dismissal Controllers
    
    private func handleTimerTick() {
        guard !isDismissing, phase == .active else { return }
        
        // Advance progress toward 1.0 over exactly 60 ticks (~2.0 seconds)
        progress = min(1.0, progress + (1.0 / totalTicks))
        
        // Drive wave index forward so text completes exactly 2 full sweeps by progress == 1.0
        withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
            let totalSteps = loadingText.count + 6 // includes padding steps for smooth wave entry/exit
            let waveCycleSpeed = progress * CGFloat(totalSteps * 2)
            counter = Int(waveCycleSpeed) % loadingText.count
        }
        
        if progress >= 1.0 {
            isDismissing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                dismissLaunch()
            }
        }
    }
    
    private func dismissLaunch() {
        guard showLaunchView else { return }
        isDismissing = true
        HapticManager.impact(style: .medium)
        
        withAnimation(.easeInOut(duration: 0.4)) {
            showLaunchView = false
        }
    }
}

#Preview {
    LaunchView(showLaunchView: .constant(true))
}
