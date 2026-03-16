//
//  InviteDJView.swift
//  N3ON
//

import SwiftUI

struct InviteDJsView: View {
    @EnvironmentObject var draft: EventDraftViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Invite DJs")
                .font(.title2.bold())
                .foregroundColor(.white)

            TextField("Search DJs by username", text: $draft.searchQuery)
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(10)
                .foregroundColor(.white)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(
                        draft.djSuggestions.filter {
                            draft.searchQuery.isEmpty || $0.contains(draft.searchQuery)
                        },
                        id: \.self
                    ) { username in
                        Button {
                            draft.addDJ(username)
                        } label: {
                            HStack {
                                Text(username)
                                Spacer()
                                if draft.invitedDJUsernames.contains(username) {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        }
                    }
                }
            }

            if !draft.invitedDJUsernames.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invited DJs:")
                        .foregroundColor(.gray)
                    ForEach(draft.invitedDJUsernames, id: \.self) { username in
                        HStack {
                            Text(username)
                            Spacer()
                            Button {
                                draft.removeDJ(username)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color("neonPurpleBackground"))
        .onAppear {
            draft.djSuggestions = ["DJ Zeta", "Nova", "Bassline", "Echo"]
        }
    }
}

#Preview {
    InviteDJsView()
        .environmentObject(EventDraftViewModel())
}
