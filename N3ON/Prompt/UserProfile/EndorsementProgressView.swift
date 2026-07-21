// EndorsementProgressView.swift
// N3ON — Prompt layer
// Shows a candidate DJ's rank promotion progress and lets them request endorsements
// from eligible senior DJs they've worked with.

import SwiftUI

struct EndorsementProgressView: View {
    let userID: String
    let currentRank: Int

    @StateObject private var vm: EndorsementViewModel = EndorsementViewModel()
    @State private var showEndorserPicker = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    rankHeader
                    progressCard
                    sentRequestsList
                    requestButton
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Rank Progression")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            vm.currentRank = currentRank
            await vm.loadProgress(userID: userID)
        }
        .sheet(isPresented: $showEndorserPicker) {
            EndorserPickerSheet(vm: vm, userID: userID)
        }
    }

    // MARK: — Rank header

    private var rankHeader: some View {
        HStack(spacing: 16) {
            rankBadge(rank: currentRank, label: "Current")
            Image(systemName: "arrow.right")
                .foregroundStyle(.white.opacity(0.4))
            rankBadge(rank: vm.targetRank, label: "Target")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func rankBadge(rank: Int, label: String) -> some View {
        VStack(spacing: 6) {
            Text("Rank \(rank)")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(label == "Target" ? Color("neonPurpleBackground") : .white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: — Progress card

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ENDORSEMENTS FOR RANK \(vm.targetRank)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("neonPurpleBackground"))
                .tracking(1.5)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(vm.isEligibleToPromote
                              ? Color("neonPurpleBackground")
                              : Color("neonPurpleBackground").opacity(0.6))
                        .frame(width: geo.size.width * vm.progressFraction, height: 8)
                        .shadow(color: Color("neonPurpleBackground").opacity(vm.isEligibleToPromote ? 0.8 : 0), radius: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: vm.progressFraction)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(vm.approvedCount) of \(vm.required) endorsements accepted")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Spacer()
                if vm.pendingCount > 0 {
                    Text("\(vm.pendingCount) pending")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            if vm.isEligibleToPromote {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("neonPurpleBackground"))
                    Text("Eligible for promotion — a moderator will review your recent events.")
                        .font(.caption)
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: — Sent requests list

    @ViewBuilder
    private var sentRequestsList: some View {
        if !vm.sentRequests.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("REQUESTS SENT")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("neonPurpleBackground"))
                    .tracking(1.5)

                ForEach(vm.sentRequests, id: \.id) { req in
                    sentRequestRow(req)
                }
            }
        } else if vm.isLoadingProgress {
            ProgressView().tint(.white).frame(maxWidth: .infinity)
        }
    }

    private func sentRequestRow(_ req: EndorsementRequest) -> some View {
        HStack(spacing: 12) {
            PulsingAvatarView(
                state: .remote(avatarKey: req.toUser?.avatarKey ?? "default-avatar"),
                audioKey: nil,
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("@\(req.toUser?.username ?? "—")")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text(req.message)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            statusPill(req.status)
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func statusPill(_ status: String) -> some View {
        let (label, color): (String, Color) = {
            switch status {
            case "approved": return ("Accepted", Color("neonPurpleBackground"))
            case "rejected": return ("Declined", .red.opacity(0.7))
            default:         return ("Pending", .white.opacity(0.35))
            }
        }()
        return Text(label)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: — Request button

    @ViewBuilder
    private var requestButton: some View {
        let alreadyHasEnough = vm.isEligibleToPromote
        let hasPending = vm.pendingCount > 0

        if !alreadyHasEnough {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task {
                    await vm.loadEligibleEndorsers(userID: userID)
                    showEndorserPicker = true
                }
            } label: {
                HStack(spacing: 8) {
                    if vm.isLoadingEndorsers {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "person.badge.plus")
                        Text("Request Endorsement")
                            .font(.headline)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .background(vm.isLoadingEndorsers
                        ? AnyShapeStyle(Color.white.opacity(0.08))
                        : AnyShapeStyle(Color("neonPurpleBackground")))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color("neonPurpleBackground").opacity(vm.isLoadingEndorsers ? 0 : 0.55), radius: 18)
            .shadow(color: Color("neonPurpleBackground").opacity(vm.isLoadingEndorsers ? 0 : 0.85), radius: 5)
            .disabled(vm.isLoadingEndorsers)

            if hasPending {
                Text("You have pending requests — wait for a response before sending more.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .padding(.top, -8)
            }
        }
    }
}

// MARK: — Endorser picker sheet

private struct EndorserPickerSheet: View {
    @ObservedObject var vm: EndorsementViewModel
    let userID: String

    @State private var selectedEndorser: User?
    @State private var message = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if vm.eligibleEndorsers.isEmpty && !vm.isLoadingEndorsers {
                    noEligibleState
                } else {
                    content
                }
            }
            .navigationTitle("Choose a DJ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
            }
        }
        .onChangeCompat(of: vm.didSend) { _, sent in
            if sent { dismiss() }
        }
    }

    private var noEligibleState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.2))
            Text("No eligible DJs found")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.5))
            Text("You need to have worked at the same event as a Rank \(vm.targetRank) DJ.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            if selectedEndorser == nil {
                endorserList
            } else {
                messageComposer
            }
        }
    }

    private var endorserList: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("These Rank \(vm.targetRank) DJs worked the same events as you.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                ForEach(vm.eligibleEndorsers, id: \.id) { dj in
                    Button {
                        selectedEndorser = dj
                        vm.didSend = false
                    } label: {
                        HStack(spacing: 14) {
                            PulsingAvatarView(
                                state: .remote(avatarKey: dj.avatarKey ?? "default-avatar"),
                                audioKey: nil,
                                size: 44
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text("@\(dj.username)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("Rank \(dj.djRank ?? 0)")
                                    .font(.caption)
                                    .foregroundStyle(Color("neonPurpleBackground"))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.04))
                    }
                    Divider().background(Color.white.opacity(0.06))
                }
            }
        }
    }

    private var messageComposer: some View {
        VStack(spacing: 20) {
            // Chosen DJ header
            if let dj = selectedEndorser {
                HStack(spacing: 12) {
                    Button { selectedEndorser = nil } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Color("neonPurpleBackground"))
                    }
                    PulsingAvatarView(
                        state: .remote(avatarKey: dj.avatarKey ?? "default-avatar"),
                        audioKey: nil,
                        size: 36
                    )
                    Text("@\(dj.username)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }

            // Message field
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR MESSAGE")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("neonPurpleBackground"))
                    .tracking(1.5)
                    .padding(.horizontal, 16)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $message)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(.white)
                        .padding(12)
                        .frame(minHeight: 120)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 16)

                    if message.isEmpty {
                        Text("Describe the event you worked together and why you deserve this endorsement…")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.25))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
            }

            if let err = vm.sendError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.horizontal, 16)
            }

            Spacer()

            // Send button
            Button {
                guard let dj = selectedEndorser else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { await vm.sendRequest(toUserID: dj.id, message: message) }
            } label: {
                Group {
                    if vm.isSending {
                        ProgressView().tint(.white)
                    } else {
                        Text("Send Request")
                            .font(.headline)
                            .foregroundStyle(message.isEmpty ? .white.opacity(0.3) : .white)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .background(message.isEmpty
                        ? AnyShapeStyle(Color.white.opacity(0.08))
                        : AnyShapeStyle(Color("neonPurpleBackground")))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color("neonPurpleBackground").opacity(message.isEmpty ? 0 : 0.55), radius: 18)
            .shadow(color: Color("neonPurpleBackground").opacity(message.isEmpty ? 0 : 0.85), radius: 5)
            .disabled(message.isEmpty || vm.isSending)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}
