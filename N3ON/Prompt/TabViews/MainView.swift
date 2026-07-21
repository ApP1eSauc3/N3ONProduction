//
//  MainView.swift
//  N3ON
//
//  Created by liam howe on 24/6/2024.
//


import SwiftUI

struct MainView: View {
    @StateObject var mapViewModel = MapViewModel()
    @State private var selectedTab: Int = 0
    
    var body: some View {
            TabView(selection: $selectedTab) {
                MapView()
                    .environmentObject(mapViewModel)
                    .tabItem {
                        // HIG: image-only controls need an accessible name.
                        Label("Map", systemImage: "map")
                    }
                    .tag(0)

                UserProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .tag(1)
            }
        .toolbarBackground(Color.black, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(Color("neonPurpleBackground"))
          
        }
    }

 
