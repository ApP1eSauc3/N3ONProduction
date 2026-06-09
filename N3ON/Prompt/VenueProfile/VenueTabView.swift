// VenueTabView.swift
// N3ON — Prompt layer
// Thin wrapper preserved for naming consistency.
// Full venue owner UI (profile, events, gallery, settings tabs) lives in VenueProfileView.

import SwiftUI

struct VenueTabView: View {
    var body: some View {
        VenueProfileView()
    }
}

#Preview {
    MainView()
}
