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

    var avatarURL: URL? {
        guard let key = user.avatarKey else { return nil }
        return URL(string: "https://your-bucket-url/\(key)")
    }

    var body: some View {
        HStack(spacing: 10) {
            if let url = avatarURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
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
            if !isAdded {
                Button("Add", action: onAdd)
                    .font(.caption)
                    .padding(6)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(6)
            } else {
                Text("Added")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}//
