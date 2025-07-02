//
//  VenueComplianceForm.swift
//  N3ON
//
//  Created by liam howe on 2/7/2025.
//

import SwiftUI

struct VenueComplianceForm: View {
    @State private var selectedLicense: String = ""
    @State private var selectedContractor: String = ""
    @State private var showingSubmissionAlert = false
    @State private var submissionSuccess = false
    
    let licenses = ["Liquor License", "Noise Permit", "Event Liability", "Health Permit", "Fire Safety Certificate"]
    let contractors = ["Sound & Lighting Co.", "Venue Setup Ltd.", "Security Group", "Catering Partners", "Clean Team Services"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Venue Compliance")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        
                        Text("Complete all required documentation for your venue operations")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 8)
                    
                    // License Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("REQUIRED LICENSES")
                            .font(.caption)
                            .foregroundColor(Color("neonPurpleBackground"))
                            .tracking(1.5)
                        
                        Menu {
                            ForEach(licenses, id: \.self) { license in
                                Button(action: { selectedLicense = license }) {
                                    Text(license)
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedLicense.isEmpty ? "Select License Type" : selectedLicense)
                                    .foregroundColor(selectedLicense.isEmpty ? .gray : .white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color("neonPurpleBackground"))
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
                    
                    // Contractor Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PREFERRED CONTRACTORS")
                            .font(.caption)
                            .foregroundColor(Color("neonPurpleBackground"))
                            .tracking(1.5)
                        
                        Menu {
                            ForEach(contractors, id: \.self) { contractor in
                                Button(action: { selectedContractor = contractor }) {
                                    Text(contractor)
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedContractor.isEmpty ? "Select Service Provider" : selectedContractor)
                                    .foregroundColor(selectedContractor.isEmpty ? .gray : .white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color("neonPurpleBackground"))
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
                    
                    // Information Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DOCUMENT UPLOAD")
                            .font(.caption)
                            .foregroundColor(Color("neonPurpleBackground"))
                            .tracking(1.5)
                        
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(Color("neonPurpleBackground"))
                                .frame(width: 24)
                            
                            Text("Upload supporting documents after submission")
                                .foregroundColor(.white)
                                .font(.callout)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color("dullPurple"))
                        .cornerRadius(12)
                    }
                    .padding(.top)
                    
                    // Submit Button
                    Button(action: submitCompliance) {
                        HStack {
                            Text("Submit Compliance")
                                .font(.headline.bold())
                            
                            Image(systemName: "checkmark.shield.fill")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("neonPurpleBackground"))
                        .cornerRadius(15)
                        .shadow(color: Color("neonPurpleBackground").opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 24)
                    .disabled(selectedLicense.isEmpty || selectedContractor.isEmpty)
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
            .alert(isPresented: $showingSubmissionAlert) {
                Alert(
                    title: Text(submissionSuccess ? "Success!" : "Incomplete"),
                    message: Text(submissionSuccess ?
                                 "Your compliance form has been submitted successfully" :
                                 "Please select both a license and contractor"),
                    dismissButton: .default(Text("OK")) {
                        if submissionSuccess {
                            selectedLicense = ""
                            selectedContractor = ""
                        }
                    }
                )
            }
        }
    }
    
    private func submitCompliance() {
        guard !selectedLicense.isEmpty && !selectedContractor.isEmpty else {
            submissionSuccess = false
            showingSubmissionAlert = true
            return
        }
        
        // In a real app, you would:
        // 1. Validate selections
        // 2. Send data to backend
        // 3. Handle response
        
        submissionSuccess = true
        showingSubmissionAlert = true
        
        // Print for debugging
        print("Compliance Submitted:")
        print("License: \(selectedLicense)")
        print("Contractor: \(selectedContractor)")
    }
}

// MARK: - Preview
struct VenueComplianceForm_Previews: PreviewProvider {
    static var previews: some View {
        VenueComplianceForm()
            .preferredColorScheme(.dark)
    }
}

// MARK: - Color Extensions (Add to your asset catalog)
extension Color {
    static let dullPurple = Color("dullPurple")
    static let neonPurpleBackground = Color("neonPurpleBackground")
}
