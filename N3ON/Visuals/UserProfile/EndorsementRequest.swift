//
//  Endorsment request.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//
import SwiftUI
import Amplify

struct EndorsementRequestFormView: View {
    @State private var message = ""
    @State private var showAlert = false
    @State private var alertText = ""
    @State private var submitting = false
    @State private var currentUser: User? = nil

    let toUser: User

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let user = currentUser, user.endorsementLevel < 4 {
                Text("Only Level 4 DJs can be endorsed to be Level 5 DJs.")
                    .foregroundColor(.red)
            } else {
                Text("Why should \(toUser.username) be Level 5?")
                    .font(.headline)
                TextEditor(text: $message)
                    .frame(height: 150)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray))

                Button(action: submitRequest) {
                    if submitting {
                        ProgressView()
                    } else {
                        Text("Send Request")
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .navigationTitle("Request Endorsement")
        .onAppear(perform: loadCurrentUser)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Notice"), message: Text(alertText), dismissButton: .default(Text("OK")))
        }
    }

    func loadCurrentUser() {
        Task {
            do {
                let authUser = try await Amplify.Auth.getCurrentUser()
                if let user = try await Amplify.DataStore.query(User.self, byId: authUser.userId) {
                    await MainActor.run { self.currentUser = user }
                }
            } catch {
                print("Failed to fetch current user: \(error)")
            }
        }
    }

    func submitRequest() {
        guard let fromUser = currentUser else { return }
        guard fromUser.endorsementLevel >= 4 else {
            alertText = "You must be at least Level 4 to endorse another DJ."
            showAlert = true
            return
        }

        submitting = true

        Task {
            let request = EndorsementRequest(
                id: UUID().uuidString,
                fromUserID: fromUser.id,
                toUserID: toUser.id,
                message: message,
                status: "pending",
                timestamp: .now()
            )

            do {
                try await Amplify.DataStore.save(request)
                await MainActor.run {
                    alertText = "Request sent successfully."
                    showAlert = true
                    submitting = false
                    message = ""
                }
            } catch {
                await MainActor.run {
                    alertText = "Failed to send request."
                    showAlert = true
                    submitting = false
                }
            }
        }
    }
}

extension User {
    var endorsementLevel: Int {
        // Placeholder logic, replace with real metric later
        return Int.random(in: 1...5)
    }
}
