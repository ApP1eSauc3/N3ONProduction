// EndorsementInboxView.swift
// N3ON — Prompt layer
// Shown for senior DJs to review incoming endorsement requests from DJs they've worked with.
// Senior DJ accepts or declines — each accepted endorsement counts toward the candidate's rank promotion.

import SwiftUI

struct EndorsementInboxView: View {
    let userID: String
    let currentRank: Int

    @StateObject private var vm = EndorsementViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if vm.isLoadingInbox {
                    ProgressView().tint(.white)
                } else if vm.incomingRequests.isEmpty {
                    emptyState
                } else {
                    requestList
                }
            }
        }
        .navigationTitle("Endorsement Requests")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            vm.currentRank = currentRank
            await vm.loadInbox(userID: userID)
        }
    }

    // MARK: — Empty

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.15))
            Text("No pending requests")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.4))
            Text("When a DJ you've worked with requests your endorsement, it'll appear here.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: — List

    private var requestList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if let err = vm.actionError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(12)
                        .frame(maxWidth: .infinity)
                }

                ForEach(vm.incomingRequests, id: \.id) { req in
                    requestRow(req)
                    Divider().background(Color.white.opacity(0.06))
                }
            }
            .padding(.top, 8)
        }
    }

    private func requestRow(_ req: EndorsementRequest) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // DJ header
            HStack(spacing: 12) {
                PulsingAvatarView(
                    state: .remote(avatarKey: req.fromUser?.avatarKey ?? "default-avatar"),
                    audioKey: nil,
                    size: 48
                )
                VStack(alignment: .leading, spacing: 3) {
                    Text("@\(req.fromUser?.username ?? "—")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Text("Rank \(req.fromUser?.djRank ?? 0)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("·")
                            .foregroundStyle(.white.opacity(0.3))
                        Text("Requesting Rank \(req.targetRank)")
                            .font(.caption)
                            .foregroundStyle(Color("neonPurpleBackground"))
                    }
                }
                Spacer()
                Text(req.timestamp.foundationDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
            }

            // Message
            Text(req.message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Actions
            HStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    Task { await vm.decline(request: req) }
                } label: {
                    Text("Decline")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task { await vm.accept(request: req) }
                } label: {
                    Text("Accept")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color("neonPurpleBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: Color("neonPurpleBackground").opacity(0.55), radius: 12)
                        .shadow(color: Color("neonPurpleBackground").opacity(0.85), radius: 4)
                }
            }
        }
        .padding(16)
    }
}
