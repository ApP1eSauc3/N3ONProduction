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
            searchResultsList()
                .searchable(text: $viewModel.searchText)
                .onSubmit {
                    Task {
                     await viewModel.searchForPlaces()
                    }
                }
                .listStyle(.plain)
            
            Spacer() // Pushes list up
        }
    }

    /// Extracted `List` to improve compiler performance
    @ViewBuilder
    private func searchResultsList() -> some View {
        List {
            if viewModel.isLoading {
                ProgressView("Searching...")
            } else if viewModel.mapItems.isEmpty {
                Text("No results found").foregroundColor(.gray)
            } else {
                ForEach(viewModel.mapItems, id: \.self) { item in
                    Text(item.name ?? "Unknown place")
                }
            }
        }
    }
}
