//
//  ChatView.swift
//  N3ON
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            messageList
            Divider().overlay(Color.white.opacity(0.08))
            inputBar
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(viewModel.participants.first?.username ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
        .task { await viewModel.markRead() }
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.messages) { message in
                        MessageRow(message: message)
                    }
                    // Invisible anchor so we can scroll to the bottom
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical, 12)
            }
            .background(Color.black)
            .onChangeCompat(of: viewModel.messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onAppear {
                proxy.scrollTo("bottom")
            }
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("", text: $viewModel.messageText, prompt:
                Text("Message…").foregroundColor(.white.opacity(0.3))
            )
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
            .submitLabel(.send)
            .onSubmit { viewModel.sendMessage() }

            Button(action: viewModel.sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color("neonPurpleBackground"))
                            .shadow(color: Color("neonPurpleBackground").opacity(0.55), radius: 8)
                    )
            }
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
    }
}
