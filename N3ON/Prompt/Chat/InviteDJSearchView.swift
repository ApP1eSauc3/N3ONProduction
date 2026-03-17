//
//  InviteDJSearchView.swift
//  N3ON
//

import SwiftUI

struct InviteDJSearchView: View {
    @StateObject private var vm = InviteSearchBarViewModel()

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search DJs…", text: $vm.searchText)
                .textFieldStyle(.roundedBorder)
                .padding()

            List(vm.results) { user in
                UserSearchRow(
                    user: user,
                    isAdded: false,
                    onAdd: {},
                    onMessage: {}
                )
            }
        }
        .navigationTitle("Invite DJ")
    }
}
