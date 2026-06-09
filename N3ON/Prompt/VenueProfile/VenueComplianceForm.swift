// VenueComplianceForm.swift
// N3ON — Prompt layer
// Compliance document submission for venue owners.
// Accessed via NavigationLink from VenueSettingsForm — already inside UserProfileView's NavigationStack.

import SwiftUI

struct VenueComplianceForm: View {
    let venueID: String

    @State private var selectedLicense: String = ""
    @State private var selectedContractor: String = ""
    @State private var showingSubmissionAlert = false
    @State private var submissionSuccess = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Compliance")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Complete all required documentation for your venue operations.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 8)

                // License picker
                pickerSection(
                    label: "REQUIRED LICENSES",
                    items: licenses,
                    selection: $selectedLicense,
                    placeholder: "Select License Type"
                )

                // Contractor picker
                pickerSection(
                    label: "PREFERRED CONTRACTORS",
                    items: contractors,
                    selection: $selectedContractor,
                    placeholder: "Select Service Provider"
                )

                // Document upload placeholder
                VStack(alignment: .leading, spacing: 12) {
                    Text("DOCUMENT UPLOAD")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("neonPurpleBackground"))
                        .tracking(1.5)

                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(Color("neonPurpleBackground"))
                            .frame(width: 24)
                        Text("Documents can be uploaded after form submission.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                }

                submitButton
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Compliance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
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

    // MARK: — Picker section

    private func pickerSection(
        label: String,
        items: [String],
        selection: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("neonPurpleBackground"))
                .tracking(1.5)

            Menu {
                ForEach(items, id: \.self) { item in
                    Button(item) { selection.wrappedValue = item }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue.isEmpty ? placeholder : selection.wrappedValue)
                        .font(.subheadline)
                        .foregroundStyle(selection.wrappedValue.isEmpty ? .white.opacity(0.3) : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color("neonPurpleBackground"))
                }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color("neonPurpleBackground").opacity(0.25), lineWidth: 1)
                )
            }
        }
    }

    // MARK: — Submit button

    private var canSubmit: Bool {
        !selectedLicense.isEmpty && !selectedContractor.isEmpty
    }

    private var submitButton: some View {
        Button(action: { Task { await submitCompliance() } }) {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "checkmark.shield.fill")
                    Text("Submit Compliance")
                        .font(.headline)
                }
            }
            .foregroundStyle(canSubmit ? .white : .white.opacity(0.3))
            .frame(maxWidth: .infinity, minHeight: 50)
        }
        .background(canSubmit
                    ? AnyShapeStyle(Color("neonPurpleBackground"))
                    : AnyShapeStyle(Color.white.opacity(0.08)))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color("neonPurpleBackground").opacity(canSubmit ? 0.55 : 0), radius: 18)
        .shadow(color: Color("neonPurpleBackground").opacity(canSubmit ? 0.85 : 0), radius: 5)
        .disabled(!canSubmit || isSubmitting)
    }

    // MARK: — Submission

    @MainActor
    private func submitCompliance() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await VenueService.saveCompliance(
                venueID: venueID,
                licenseType: selectedLicense,
                contractorName: selectedContractor
            )
            submissionSuccess = true
            showingSubmissionAlert = true
        } catch {
            submissionSuccess = false
            errorMessage = "Failed to submit: \(error.localizedDescription)"
            showingSubmissionAlert = true
        }
    }
}
