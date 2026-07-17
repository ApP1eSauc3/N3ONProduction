// ProfileChrome.swift
// N3ON
//
// Shared chrome for the profile screen: section headers, row labels, and
// role pills. One definition — the profile decomposition files
// (Sections, ProfileAccountSection, ProfileAdminSection, ProfileHeaderView)
// all draw from here instead of re-inlining the same recipes.

import SwiftUI

/// Accent bar + headline used at the top of every profile section.
struct ProfileSectionHeader: View {
    let title: String
    var barColor: Color = Color("neonPurpleBackground")

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(barColor)
                .frame(width: 3, height: 16)
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
}

/// Dark-gray row chrome: icon, title, optional trailing chevron.
/// Use as the label of a Button or NavigationLink; the caller still applies
/// `.frame(minHeight: 44)` + `.contentShape(Rectangle())` (HIG tap target).
struct ProfileRowLabel: View {
    let icon: String
    let title: String
    var textOpacity: Double = 1.0
    var showsChevron = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .font(.subheadline)
        .foregroundStyle(.white.opacity(textOpacity))
        .padding(12)                // DESIGN §1.6 row inner padding — 12pt
        .background(Color.customDarkGray)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // DESIGN §1.6 row radius
    }
}

/// Capsule role/mode pill: icon + caption text on a tinted capsule.
struct RolePill: View {
    let icon: String
    let text: String
    let foreground: Color
    let fill: Color
    let stroke: Color

    /// Standard emphasis: tinted text on tint-12% fill with tint-35% stroke.
    init(icon: String, text: String, tint: Color) {
        self.init(icon: icon, text: text,
                  foreground: tint,
                  fill: tint.opacity(0.12),
                  stroke: tint.opacity(0.35))
    }

    init(icon: String, text: String, foreground: Color, fill: Color, stroke: Color) {
        self.icon = icon
        self.text = text
        self.foreground = foreground
        self.fill = fill
        self.stroke = stroke
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption.bold())
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(fill)
                .overlay(Capsule().stroke(stroke, lineWidth: 1))
        )
    }
}
