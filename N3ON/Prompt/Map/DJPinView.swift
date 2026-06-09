//
//  DJPinView.swift
//  N3ON
//
// SwiftUI pin for a DJ. Currently the map renders pins via DJPinAnnotation
// (UIKit MKAnnotationView inside CustomMapView). This view is available for
// future use if the map migrates to SwiftUI annotations.

import SwiftUI

struct DJPinView: View {
    let dj: DJ

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "music.note")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(8)
                .background(
                    Circle()
                        // DESIGN §1.1 — neon accent for followed DJs; muted surface otherwise
                        .fill(dj.isFollowedByCurrentUser
                              ? Color("neonPurpleBackground")
                              : Color.white.opacity(0.15))
                        .shadow(
                            color: dj.isFollowedByCurrentUser
                                ? Color("neonPurpleBackground").opacity(0.55)
                                : .clear,
                            radius: 8
                        )
                )

            Text(dj.name)
                .font(.caption2)
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.black.opacity(0.7))
                )
        }
    }
}
