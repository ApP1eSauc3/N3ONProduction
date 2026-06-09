// EventInviteSheet.swift
// N3ON — Prompt layer
// Presented as a sheet from EventLimboView. Shows a searchable list of DJs
// (followed DJs sorted first, then all others). Tapping "Invite" opens or
// creates a DJ↔DJ chat room and sends an event invitation message.
//
// Invitation message format (stored in Message.content):
//   {"type":"event_invite","eventID":"...","eventName":"...","venueName":"...","eventDate":"<ISO8601>"}
// MessageRow detects this prefix and renders an EventInviteCard instead of a text bubble.

import SwiftUI

struct EventInviteSheet: View {
    let context: EventInviteContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var allDJs: [User] = []
    @State private var followedIDs: Set<String> = []
    @State private var invitedIDs: Set<String> = []
    @State private var isLoading = true

    // Followed DJs first, then alphabetical
    private var sortedDJs: [User] {
        allDJs.sorted { a, b in
            let aF = followedIDs.contains(a.id)
            let bF = followedIDs.contains(b.id)
            if aF != bF { return aF }
            return a.username < b.username
        }
    }

    private var filteredDJs: [User] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return sortedDJs }
        return sortedDJs.filter {
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                dragIndicator
                header
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                content
            }
        }
        .task { await loadDJs() }
    }

    // MARK: — Chrome

    private var dragIndicator: some View {
        Capsule()
            .fill(Color.white.opacity(0.2))
            .frame(width: 36, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 16)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Invite DJs")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                Text(context.eventName)
                    .font(.caption)
                    .foregroundStyle(Color("neonPurpleBackground"))
                    .lineLimit(1)
            }
            Spacer()
            Button("Done") { dismiss() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
            TextField("", text: $searchText, prompt:
                Text("Search by username").foregroundColor(.white.opacity(0.3))
            )
            .font(.subheadline)
            .foregroundStyle(.white)
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: — Content

    @ViewBuilder private var content: some View {
        if isLoading {
            Spacer()
            ProgressView().tint(Color("neonPurpleBackground"))
            Spacer()
        } else if filteredDJs.isEmpty {
            Spacer()
            Text(allDJs.isEmpty ? "No DJs found" : "No results")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    if !followedIDs.isEmpty && searchText.isEmpty {
                        sectionLabel("FOLLOWING")
                    }
                    ForEach(filteredDJs) { dj in
                        DJInviteRow(
                            dj:        dj,
                            isFollowed: followedIDs.contains(dj.id),
                            invited:   invitedIDs.contains(dj.id)
                        ) {
                            Task { await sendInvite(to: dj) }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color("neonPurpleBackground"))
            .tracking(1.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: — Load

    private func loadDJs() async {
        isLoading = true
        defer { isLoading = false }

        guard let myID = try? await AuthService.currentUserId() else { return }
        followedIDs = Set((try? await FollowService.followedDJIDs()) ?? [])
        allDJs = await EventService.allDJs(excludingID: myID)
    }

    // MARK: — Send invite

    private func sendInvite(to dj: User) async {
        guard !invitedIDs.contains(dj.id) else { return }
        guard let myUser = try? await AuthService.getCurrentUserModel() else { return }

        do {
            let room = try await ChatRoomService.openDJDirectRoom(userA: myUser, userB: dj)

            let payload: [String: String] = [
                "type":      "event_invite",
                "eventID":   context.eventID,
                "eventName": context.eventName,
                "venueName": context.venueName,
                "eventDate": ISO8601DateFormatter().string(from: context.eventDate)
            ]
            guard let jsonData   = try? JSONSerialization.data(withJSONObject: payload),
                  let jsonString = String(data: jsonData, encoding: .utf8) else { return }

            try await ChatRoomService.send(content: jsonString, in: room.id, from: myUser)
            invitedIDs.insert(dj.id)
        } catch { }
    }
}

// MARK: - DJ row

private struct DJInviteRow: View {
    let dj: User
    let isFollowed: Bool
    let invited: Bool
    let onInvite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar initial
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color("dullPurple"), Color("neonPurpleBackground").opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Text(dj.username.prefix(1).uppercased())
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                )

            // Name + rank
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(dj.username)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                    if isFollowed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Color("neonPurpleBackground"))
                    }
                }
                if let rank = dj.djRank {
                    Text("Rank \(rank)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer()

            // Invite button
            Button(action: onInvite) {
                Text(invited ? "Invited" : "Invite")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(invited
                                     ? .white.opacity(0.35)
                                     : Color("neonPurpleBackground"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(invited
                                ? Color.white.opacity(0.06)
                                : Color("neonPurpleBackground").opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule()
                        .stroke(invited
                                ? Color.clear
                                : Color("neonPurpleBackground").opacity(0.4),
                                lineWidth: 1))
            }
            .disabled(invited)
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
