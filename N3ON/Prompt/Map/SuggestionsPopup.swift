//
//  SuggestionsPopup.swift
//  N3ON
//
//  Created by liam howe on 25/3/2025.
//

// SuggestionsPopup.swift
import SwiftUI

struct SuggestionsPopup: View {
    @Binding var searchText: String
    let suggestions: [String]
    
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(maxHeight: 250)
            .overlay(
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(action: {
                                searchText = suggestion
                            }) {
                                VStack(alignment: .leading) {
                                    Text(suggestion)
                                        .font(.headline)
                                    Text("Tap to search")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 12)
                                .padding(.leading, 16)
                            }
                        }
                    }
                }
            )
            .cornerRadius(10.0)
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.3))
    }
}


