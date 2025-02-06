//
//  MapView.swift
//  N3ON
//
//  Created by liam howe on 22/6/2024.
//

import SwiftUI
import MapKit
import Combine


struct MapView: View {

    @ObservedObject var viewModel: MapViewModel
    @StateObject private var locationManager = LocationManager()


    var body: some View {
        NavigationStack {
            VStack{
                ZStack {
                    SearchView(viewModel: viewModel)
                    if let userLocation = locationManager.userLocation {
                        CustomMapView(region: $viewModel.mapRegion) //use customMapView
                        
                        .onAppear {
                            viewModel.setMapRegion(for: userLocation.coordinate)
                        }
                        .onChange(of: locationManager.userLocation) { newLocation in
                            if let newLocation = newLocation {
                                viewModel.setMapRegion(for: newLocation.coordinate)
                            }
                        }
                        .ignoresSafeArea()
                        
                        Circle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 32, height: 32)
                    } else {
                        Text("Fetching location...")
                    }
                }
            }
        }
    }

}

//struct MapView_Previews: PreviewProvider {
//    static var previews: some View {
//        MapView()
//    }
//}
