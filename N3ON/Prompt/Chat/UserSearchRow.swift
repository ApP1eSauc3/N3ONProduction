//
//  UserSearchRow.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import SwiftUI

struct UserSearchRow: View {
    let user: UserSummary
    let isAdded: Bool
    let onAdd: () -> Void
    let onMessage: () -> Void  // ✅ Add this line

    var body: some View {
        HStack(spacing: 10) {
            // DESIGN §3.4 — shared avatar component (36pt search-row size);
            // loading, caching, and placeholder live in PulsingAvatarView.
            PulsingAvatarView(
                state: .remote(avatarKey: user.avatarKey ?? "default-avatar"),
                size: 36
            )

            Text(user.username)
            Spacer()

            if user.isDJ {
                if !isAdded {
                    Button("Follow", action: onAdd)
                        .font(.caption)
                        .padding(6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)
                } else {
                    Text("Added")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Button("Message", action: onMessage)  // ✅ New button
                    .font(.caption)
                    .padding(6)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}
