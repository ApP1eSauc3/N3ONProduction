//
//  SearchField.swift
//  N3ON
//
//  Created by liam howe on 25/3/2025.
//

// SearchField.swift
import SwiftUI

struct SearchField: View {
    @Binding var searchText: String
    @Binding var isEditing: Bool
    @FocusState.Binding var isSearchFieldFocused: Bool
    @EnvironmentObject var viewModel: MapViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search places...", text: $searchText, onEditingChanged: { editing in
                isEditing = editing
            })
            .focused($isSearchFieldFocused)
            .onChange(of: searchText) { newValue in
                guard !newValue.isEmpty else { return }
                Task {
                    await viewModel.fetchSuggestions(query: newValue)
                }
            }
        }
        .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isEditing ? Color.white : Color.white.opacity(0.25))
                .cornerRadius(10.0)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
        }

