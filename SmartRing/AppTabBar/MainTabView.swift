//
//  MainTabView.swift
//  SmartRing
//
//  Created by Nice Interactive on 15/10/25.
//


import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "figure.walk")
                }
            
            SleepView()
                .tabItem {
                    Label("Sleep", systemImage: "bed.double.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(.blue)
    }
}
