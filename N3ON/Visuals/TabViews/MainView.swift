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
        NavigationStack{
            TabView(selection: $selectedTab) {
                MapView()
                    .environmentObject(mapViewModel)
                    .tabItem {
                        Image(systemName: "map")
                    }
                    .tag(0)
                    .toolbarBackground(
                        Color("darkGray"),
                        for: .tabBar
                    )
                    .toolbarBackground(.visible, for: .tabBar)
                    .tint(.white)
                
                UserProfileView()
                    .tabItem {
                        Image(systemName: "person")
                    }
                    .tag(1)
                    .toolbarBackground(
                        Color("darkGray"),
                        for: .tabBar
                    )
                    .toolbarBackground(.visible, for: .tabBar)
                    .tint(.white)
            }
          }
        }
    }

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
