//
//  MainView.swift
//  N3ON
//
//  Created by liam howe on 24/6/2024.
//

import SwiftUI

struct MainView: View {
    
    @StateObject var mapViewModel = MapViewModel()
    
    var body: some View {
        TabView{
            MapView(viewModel: mapViewModel)
                .tabItem{
                    Image(systemName:"map")

            }
                .toolbarBackground(Color("neonPurpleBackground"), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            UserProfileView()
                .tabItem{
                    Image(systemName:"person")
                }
                .toolbarBackground(Color("neonPurpleBackground"), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
            ChatView()
                .tabItem{
                    Image(systemName:"Message")
                }
                .toolbarBackground(Color("neonPurpleBackground"), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            
        }
        
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
