//
//  InviteDJSearchView.swift
//  N3ON
//
// New-message screen from the chat inbox (pencil icon): search users, follow
// DJs, and open a DJ↔DJ direct message. All work happens in
// InviteSearchBarViewModel; this view only presents the chat when it's ready.

import SwiftUI

struct InviteDJSearchView: View {
    @StateObject private var vm = InviteSearchBarViewModel()

    var body: some View {
        VStack(spacing: 0) {
            TextField("", text: $vm.searchText, prompt:
                Text("Search DJs…").foregroundColor(.white.opacity(0.3))
            )
            .font(.subheadline)
            .foregroundStyle(.white)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(16)

            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            List(vm.results) { user in
                UserSearchRow(
                    user: user,
                    isAdded: vm.followedIDs.contains(user.id),
                    onAdd: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        Task { await vm.follow(user) }
                    },
                    onMessage: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { await vm.message(user) }
                    }
                )
                .listRowBackground(Color.black)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("New Message")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
        .sheet(item: $vm.openChat) { chatVM in
            NavigationStack { ChatView(viewModel: chatVM) }
        }
    }
}

/// Class-bound Identifiable (identity = the instance) so a ready chat can be
/// presented with `.sheet(item:)`.
extension ChatViewModel: Identifiable {}
