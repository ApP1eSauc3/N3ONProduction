//
//  ChatsInboxView.swift
//  N3ON
//
// ChatsInboxVM and ChatSummary live in Workflow/ChatsInboxVM.swift.

import SwiftUI

// MARK: - View

struct ChatsInboxView: View {
    @StateObject private var vm = ChatsInboxVM()
    @State private var openVM: ChatViewModel?
    @State private var showChat = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if vm.loading {
                    ProgressView()
                        .tint(Color("neonPurpleBackground"))
                } else if vm.pinned.isEmpty && vm.others.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if !vm.pinned.isEmpty {
                                inboxSection("Active Events", rows: vm.pinned)
                            }
                            if !vm.others.isEmpty {
                                inboxSection("Messages", rows: vm.others)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .task { vm.start() }
        .sheet(isPresented: $showChat) {
            if let openVM { ChatView(viewModel: openVM) }
        }
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: InviteDJSearchView()) {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 44))
                .foregroundStyle(Color("neonPurpleBackground").opacity(0.4))
            Text("No conversations yet")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
            Text("DJs can message each other and venue owners\nthrough shared events.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private func inboxSection(_ title: String, rows: [ChatSummary]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.leading, 4)
            ForEach(rows) { row in
                ChatRow(row) { open(row) }
            }
        }
    }

    private func open(_ s: ChatSummary) {
        guard let me = vm.me else { return }
        openVM = ChatViewModel(chatRoomID: s.id, currentUserID: me)
        showChat = true
    }
}

// MARK: - Chat Row

private struct ChatRow: View {
    let row: ChatSummary
    let tap: () -> Void

    init(_ row: ChatSummary, _ tap: @escaping () -> Void) {
        self.row = row
        self.tap = tap
    }

    var body: some View {
        Button(action: tap) {
            HStack(spacing: 12) {
                // Avatar icon
                Circle()
                    .fill(row.isEvent
                          ? Color("neonPurpleBackground").opacity(0.15)
                          : Color.white.opacity(0.07))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: row.isEvent ? "music.note" : "person.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(row.isEvent
                                             ? Color("neonPurpleBackground")
                                             : Color.white.opacity(0.6))
                    )

                // Title + last message
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.title)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        if let ts = row.lastAt {
                            Text(relativeTime(ts))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }

                    if let last = row.last, !last.isEmpty {
                        Text(last)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }

                    // Expiry indicator for event rooms
                    if row.isEvent {
                        expiryLabel
                    }
                }

                // Unread badge
                if row.unread > 0 {
                    Text("\(row.unread)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color("neonPurpleBackground"))
                                .shadow(color: Color("neonPurpleBackground").opacity(0.5), radius: 6)
                        )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(row.unread > 0 ? 0.08 : 0.05))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var expiryLabel: some View {
        if row.isExpired {
            Label("Expired", systemImage: "clock.badge.xmark")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
        } else if let exp = row.expiresAt {
            let hours = Int(exp.timeIntervalSinceNow / 3600)
            if hours < 48 {
                Label("Closes in \(max(hours, 0))h", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(hours < 6
                                     ? Color("neonPurpleBackground").opacity(0.8)
                                     : Color.white.opacity(0.35))
            }
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
