//
//  PackageSelectionStep.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

struct PackageSelectionStep: View {
    @Binding var selectedPackage: String
    @Binding var note: String
    let packages = ["Basic", "Medium", "premium"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose your package")
                .font(.headline)

            Picker("Package", selection: $selectedPackage) {
                ForEach(packages, id: \ .self) { pkg in
                    Text(pkg)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Text("Special Requests")
                .font(.headline)
            TextEditor(text: $note)
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
        }
    }
}import SwiftUI

struct SelectPackageView: View {
    @EnvironmentObject var daft: EventDraftViewModel
    
    var body: some View {
        
        VStack {
            Text("Select your Package")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            ForEach(EventDraftViewModel.Package.allCases) { option in
                Button(action: {
                                    draft.package = option
                                }) {
                                    HStack {
                                        Text(option.rawValue.capitalized)
                                            .font(.headline)
                                        Spacer()
                                        if draft.package == option {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(.black.opacity(0.6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                                               .stroke(draft.package == option ? Color.purple : Color.clear, lineWidth: 2)
                                                       )
                                                       .foregroundColor(.white)
                                                   }
                                               }

                                               VStack(alignment: .leading, spacing: 8) {
                                                   Text("Special Requests")
                                                       .foregroundColor(.gray)
                                                   TextField("Lighting style, sound preferences, etc.", text: $draft.specialRequest, axis: .vertical)
                                                       .padding()
                                                       .background(Color.black.opacity(0.6))
                                                       .cornerRadius(10)
                                                       .foregroundColor(.white)
                                               }

                                               Spacer()
                                           }
                                           .padding()
                                           .background(Color("neonPurpleBackground"))
                                       }
                                   }

#Preview {
    SelectPackageView()
}
