// VenueSummaryStep.swift
// N3ON — Prompt layer
// Design-compliant venue summary card — shown after venue selection in event creation.

import SwiftUI

struct VenueSummaryStep: View {
    let venue: Venue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SELECTED VENUE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("neonPurpleBackground"))
                .tracking(1.5)

            VStack(alignment: .leading, spacing: 16) {
                // Name + venue type icon
                HStack(spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color("neonPurpleBackground"))
                        .frame(width: 32, height: 32)
                        .background(Color("neonPurpleBackground").opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(venue.name)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color("neonPurpleBackground"))
                                .frame(width: 5, height: 5)
                            Text(venue.approvalStatus.capitalized)
                                .font(.caption)
                                .foregroundStyle(Color("neonPurpleBackground").opacity(0.8))
                        }
                    }
                }

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)

                detailRow(icon: "mappin.circle", label: venue.address)
                detailRow(icon: "person.2", label: "\(venue.maxCapacity) guests max capacity")

                if !venue.description.isEmpty {
                    detailRow(icon: "text.alignleft", label: venue.description)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func detailRow(icon: String, label: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color("neonPurpleBackground").opacity(0.7))
                .frame(width: 16)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
