//
//  InviteSearchBar.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import SwiftUI
import Combine

struct InviteSearchBar: View {
    let title: String
    @Binding var entries: [String]
    @StateObject private var viewModel = InviteSearchBarViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)

            TextField("Search usernames", text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if !viewModel.results.isEmpty {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.results) { user in
                            UserSearchRow(user: user, isAdded: entries.contains(user.username)) {
                                if !entries.contains(user.username) {
                                    entries.append(user.username)
                                }
                            }
                        }
                    }
                }
            }

            ScrollView(.horizontal) {
                HStack {
                    ForEach(entries, id: \ .self) {
                        Text($0)
                            .padding(8)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}
