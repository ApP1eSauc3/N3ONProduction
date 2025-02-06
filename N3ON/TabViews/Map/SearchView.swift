//
//  SearchView.swift
//  N3ON
//
//  Created by liam howe on 22/6/2024.
//

import SwiftUI


struct SearchView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Searching...")
            } else if viewModel.mapItems.isEmpty {
                Text("no results found").foregroundColor(.gray)
            } else {
                List(viewModel.mapItems, id: \.self) { item in
                    Text(item.name ?? "Unknown place")
                }
            }
        }
        .searchable(text: $viewModel.searchText)  // Use the SwiftUI native searchable modifier
        .onSubmit {
            viewModel.searchForPlaces()  // Trigger search when submit is pressed
        }
    }
}
