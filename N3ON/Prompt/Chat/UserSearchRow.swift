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
    let onMessage: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // DESIGN §3.4 — shared avatar component (36pt search-row size);
            // loading, caching, and placeholder live in PulsingAvatarView.
            PulsingAvatarView(
                state: .remote(avatarKey: user.avatarKey ?? "default-avatar"),
                size: 36
            )

            Text(user.username)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()

            if user.isDJ {
                // Buttons in a List row need .borderless, or a tap anywhere on
                // the row fires every button in it.
                Button(isAdded ? "Following" : "Follow", action: onAdd)
                    .buttonStyle(.borderless)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isAdded ? .white.opacity(0.5) : Color("neonPurpleBackground"))
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .disabled(isAdded)

                Button("Message", action: onMessage)
                    .buttonStyle(.borderless)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(Color("neonPurpleBackground").opacity(0.85))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
