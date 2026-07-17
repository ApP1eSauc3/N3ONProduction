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

    @State private var avatarImage: UIImage?

    var body: some View {
        HStack(spacing: 10) {
            if let avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 32, height: 32)
                    .overlay(Text(String(user.username.prefix(1))).foregroundColor(.white))
            }

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
        .task {
            guard let key = user.avatarKey else { return }
            avatarImage = try? await ImageCache.loadImage(forKey: key, access: .guest)
        }
    }
}
