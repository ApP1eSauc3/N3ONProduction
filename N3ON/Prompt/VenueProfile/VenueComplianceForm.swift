// VenueComplianceForm.swift
// N3ON
//

import SwiftUI
import Amplify


struct VenueComplianceRecord {
    let venueID: String
    let licenseType: String
    let contractorName: String
    let submittedAt: Date
}

struct VenueComplianceForm: View {
    let venueID: String

    @State private var selectedLicense: String = ""
    @State private var selectedContractor: String = ""
    @State private var showingSubmissionAlert = false
    @State private var submissionSuccess = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showDocumentPicker = false

    // TODO: These should be fetched from DataStore/API to allow admin management
    let licenses = [
        "Liquor License",
        "Noise Permit",
        "Event Liability",
        "Health Permit",
        "Fire Safety Certificate"
    ]
    let contractors = [
        "Sound & Lighting Co.",
        "Venue Setup Ltd.",
        "Security Group",
        "Catering Partners",
        "Clean Team Services"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Venue Compliance")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("Complete all required documentation for your venue operations")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("REQUIRED LICENSES")
                            .font(.caption)
                            .foregroundColor(Color("neonPurpleBackground"))
                            .tracking(1.5)

                        Menu {
                            ForEach(licenses, id: \.self) { license in
                                Button(license) { selectedLicense = license }
                            }
                        } label: {
                            menuLabel(
                                text: selectedLicense.isEmpty ? "Select License Type" : selectedLicense,
                                isEmpty: selectedLicense.isEmpty
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("PREFERRED CONTRACTORS")
                            .font(.caption)
                            .foregroundColor(Color("neonPurpleBackground"))
                            .tracking(1.5)

                        Menu {
                            ForEach(contractors, id: \.self) { contractor in
                                Button(contractor) { selectedContractor = contractor }
                            }
                        } label: {
                            menuLabel(
                                text: selectedContractor.isEmpty ? "Select Service Provider" : selectedContractor,
                                isEmpty: selectedContractor.isEmpty
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("DOCUMENT UPLOAD")
                            .font(.caption)
                            .foregroundColor(Color("neonPurpleBackground"))
                            .tracking(1.5)

                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(Color("neonPurpleBackground"))
                                .frame(width: 24)
                            Text("Documents can be uploaded after form submission")
                                .foregroundColor(.white)
                                .font(.callout)
                            Spacer()
                        }
                        .padding()
                        .background(Color("dullPurple"))
                        .cornerRadius(12)
                    }
                    .padding(.top)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                            .padding(.horizontal)
                    }

                    Button(action: { Task { await submitCompliance() } }) {
                        HStack {
                            if isSubmitting {
                                ProgressView().progressViewStyle(.circular).tint(.white)
                            } else {
                                Text("Submit Compliance").font(.headline.bold())
                                Image(systemName: "checkmark.shield.fill")
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("neonPurpleBackground"))
                        .cornerRadius(15)
                        .shadow(color: Color("neonPurpleBackground").opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 24)
                    .disabled(selectedLicense.isEmpty || selectedContractor.isEmpty || isSubmitting)
                    .opacity((selectedLicense.isEmpty || selectedContractor.isEmpty) ? 0.6 : 1)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color("dullPurple").opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                submissionSuccess ? "Submitted" : "Submission Failed",
                isPresented: $showingSubmissionAlert
            ) {
                Button("OK", role: .cancel) {
                    if submissionSuccess {
                        selectedLicense = ""
                        selectedContractor = ""
                    }
                }
            } message: {
                Text(submissionSuccess
                     ? "Your compliance form has been saved successfully."
                     : (errorMessage ?? "An unknown error occurred.")
                )
            }
        }
    }

   
    @MainActor
    private func submitCompliance() async {
        guard !selectedLicense.isEmpty && !selectedContractor.isEmpty else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            // IMPORTANT: VenueComplianceSubmission Swift model is generated by
            // `amplify codegen models` after schema.graphql is updated.
            // Run `amplify codegen models` before building or this will not compile.
            let submission = VenueComplianceSubmission(
                id: UUID().uuidString,
                venueID: venueID,
                licenseType: selectedLicense,
                contractorName: selectedContractor,
                submittedAt: Temporal.DateTime.now(),
                status: "pending_review"
            )
            try await Amplify.DataStore.save(submission)

            submissionSuccess = true
            showingSubmissionAlert = true

        } catch {
            submissionSuccess = false
            errorMessage = "Failed to submit: \(error.localizedDescription)"
            showingSubmissionAlert = true
        }
    }

    @ViewBuilder
    private func menuLabel(text: String, isEmpty: Bool) -> some View {
        HStack {
            Text(text).foregroundColor(isEmpty ? .gray : .white)
            Spacer()
            Image(systemName: "chevron.down").foregroundColor(Color("neonPurpleBackground"))
        }
        .padding()
        .background(Color("dullPurple"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("neonPurpleBackground").opacity(0.3), lineWidth: 1)
        )
    }
}
