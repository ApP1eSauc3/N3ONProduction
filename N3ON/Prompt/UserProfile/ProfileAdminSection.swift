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
            ProfileSectionHeader(title: "Admin")

            NavigationLink {
                AdminCurationView()
            } label: {
                ProfileRowLabel(icon: "crown.fill", title: "Curation Console", showsChevron: true)
            }
            .frame(minHeight: 44)           // HIG minimum tap target
            .contentShape(Rectangle())
        }
    }
}
