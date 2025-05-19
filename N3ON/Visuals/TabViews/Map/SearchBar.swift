//
//  SearchBar.swift
//  N3ON
//
//  Created by liam howe on 24/3/2025.
//

// SearchBar.swift
import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var isEditing: Bool
    @FocusState.Binding var isSearchFieldFocused: Bool
    @EnvironmentObject var viewModel: MapViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            SearchField(
                searchText: $searchText,
                isEditing: $isEditing,
                isSearchFieldFocused: $isSearchFieldFocused
            )
            .environmentObject(viewModel)
            
            if !searchText.isEmpty && isEditing {
                SuggestionsPopup(searchText: $searchText, suggestions: viewModel.searchSuggestions)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: isEditing)
    }
}

