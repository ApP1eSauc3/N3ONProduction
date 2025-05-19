//
//  VenueTabView.swift
//  N3ON
//
//  Created by liam howe on 12/7/2024.
//

import SwiftUI

struct VenueTabView: View {
    var body: some View {
        TabView{
            VenueTabView()
                .tabItem{
                    Image(systemName:"person")

            }
                .toolbarBackground(Color("neonPurpleBackground"), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)

                }
                .toolbarBackground(Color("neonPurpleBackground"), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
        
            }
        

        struct VenueDetailView: View {
            var body: some View {
                Text("Venue Details")
                    .padding()
            }
        }

struct VenueTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
