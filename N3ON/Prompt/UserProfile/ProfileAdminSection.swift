// ProfileAdminSection.swift
// N3ON
//
// Admin curation console entry — shown only when RoleAwareProfileViewModel.isAdmin
// is true (an orthogonal capability, not an AppRole). Extracted from
// UserProfileView so it's its own render-identity rather than a computed
// property re-evaluated as part of the parent body.

import SwiftUI

struct ProfileAdminSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color("neonPurpleBackground"))
                    .frame(width: 3, height: 16)
                Text("Admin")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            NavigationLink {
                AdminCurationView()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                    Text("Curation Console")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(12)                // DESIGN §1.6 row inner padding — 12pt
                .background(Color.customDarkGray)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .frame(minHeight: 44)           // HIG minimum tap target
            .contentShape(Rectangle())
        }
    }
}
