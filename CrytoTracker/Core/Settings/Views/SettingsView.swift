//
//  SettingsView.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 03/10/2025.
//

import SwiftUI

struct SettingsView: View {
    let defaultURL = URL (string:"https://www.google.com")!
    let LinkedinURL = URL (string:"https://www.linkedin.com/in/sagarjangra14/")!
    let LeetcodeURL = URL (string: "https://leetcode.com/u/sagarjangra880/")!
    let coingeckoURL = URL(string:"https://www.coingecko.com")!
    let githubProfileURL = URL(string:"https://github.com/Sagar5426")!
    
    var body: some View {
        NavigationStack {
            List {
                appInfoSection
                coinGeckoSection
             }
            .tint(.blue)
            .listStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    xMarkButton()
                }
            }
        }
        
    }
}

#Preview {
    SettingsView()
}

extension SettingsView {
    private var appInfoSection: some View {
        Section{
            VStack(alignment: .leading) {
                Image("logo")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                Text("This app was made by Sagar Jangra following @SwiftfulThinking course on youtube. It uses MVVM Architecture, Combine and CoreData!")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.theme.accent)
               }
            .padding(.vertical)
            linkRow(title: "Connect on Linkedin", imageName: "linkedin", systemNameIcon: "link", brandColor: Color(red: 10/255, green: 102/255, blue: 194/255), destination: LinkedinURL)
            linkRow(title: "Leetcode Profile", imageName: "leetcode", systemNameIcon: "chevron.left.forwardslash.chevron.right", brandColor: Color(red: 255/255, green: 161/255, blue: 22/255), destination: LeetcodeURL)
            linkRow(title: "GitHub Profile", imageName: "github", systemNameIcon: "curlybraces.square", brandColor: .black, destination: githubProfileURL)
        } header: {
             Text("Crypto Tracker".uppercased())
        }
    }
    
    
    private var coinGeckoSection: some View {
        Section{
            VStack(alignment: .leading) {
                Image("coingecko")
                    .resizable()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                Text("The cryptocurrency data that is used in this app comes from a free API from CoinGecko! Prices may be slightly delayed.")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.theme.accent)
               }
            .padding(.vertical)
            linkRow(title: "Visit CoinGecko 🦎", imageName: "coingecko", systemNameIcon: "globe", brandColor: .green, destination: coingeckoURL, forceFallbackIcon: true)
        } header: {
            Text("coingecko".uppercased())
        }
    }
    
    private func platformIcon(imageName: String?, systemNameIcon: String, brandColor: Color) -> some View {
        Image(systemName: systemNameIcon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(brandColor, in: RoundedRectangle(cornerRadius: 6))
    }
    
    private func linkRow(title: String, imageName: String, systemNameIcon: String, brandColor: Color, destination: URL, forceFallbackIcon: Bool = false) -> some View {
        Link(destination: destination) {
            HStack(spacing: 12) {
                platformIcon(imageName: forceFallbackIcon ? nil : imageName, systemNameIcon: systemNameIcon, brandColor: brandColor)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.subheadline)
                    .foregroundStyle(.blue.opacity(0.6))
            }
            .padding(.vertical, 6)
        }
    }
}

