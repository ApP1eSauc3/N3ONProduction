//
//  UserSearchRow.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import SwiftUI
import Amplify

struct UserSearchRow: View {
    let user: UserSummary
    let isAdded: Bool
    let onAdd: () -> Void
    let onMessage: () -> Void  // ✅ Add this line

    @State private var avatarURL: URL?

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
        .onAppear {
            loadAvatarURL()
        }
    }

    private func loadAvatarURL() {
        guard let key = user.avatarKey else { return }

        Amplify.Storage.getURL(key: key, options: .init(accessLevel: .protected)) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    self.avatarURL = url
                case .failure(let error):
                    print("❌ Failed to load avatar for \(user.username): \(error)")
                }
            }
        }
    }
}
