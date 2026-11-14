//
//  LaunchView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 04/10/2025.
//

import SwiftUI

struct LaunchView: View {
    
    // making this array of characters using .map
    @State private var loadingText: [String] = "Loading your portfolio...".map {String ($0)}
    @State private var showLoadingText: Bool = false
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var counter: Int = 0
    @State private var loopsCount: Int = 0
    @Binding var showLaunchView: Bool
    
    
    var body: some View {
        ZStack {
            Color.launch.background
                .ignoresSafeArea()
            
            Image("logo-transparent")
                .resizable()
                .frame(width: 100, height: 100)
            
            ZStack {
                if showLoadingText {
                    HStack(spacing: 0) {
                        ForEach(loadingText.indices, id: \.self) { index in
                            Text(loadingText[index])
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundStyle(Color.launch.accent)
                                .offset(y: counter == index ? -5 : 0)
                        }
                    }
                    .transition(AnyTransition.scale.animation(.easeIn))
                }
            }
            .offset(y: 70)
        }
        .onAppear {
            showLoadingText.toggle()
        }
        .onReceive(timer) { _ in
            withAnimation(.spring()) {
                let lastIndex = loadingText.count-1
                if(counter > lastIndex) {
                    counter = 0
                    loopsCount += 1
                    if(loopsCount >= 2) {
                        showLaunchView = false
                    }
                } else {
                    counter += 1
                }
            }
        }
    }
}

#Preview {
    LaunchView(showLaunchView: .constant(true))
}
