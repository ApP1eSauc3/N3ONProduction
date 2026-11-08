//
//  ProfileRoundedCorner.swift
//  N3ON
//
//  Created by liam howe on 11/5/2025.
//

import SwiftUI

// Public API
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        Group {
            if #available(iOS 17.0, *) {
                clipShape(UnevenCornerClip(radius: radius, corners: corners))
            } else {
                #if canImport(UIKit)
                clipShape(LegacyRoundedCorner(radius: radius, corners: corners))
                #else
                // macOS fallback: round all corners equally (no per-corner support pre-17)
                clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                #endif
            }
        }
    }
}

@available(iOS 17.0, *)
struct UnevenCornerClip: Shape {
    /// Clamp to [0, half the shorter side]; non-finite → 0.
    static func safeRadius(_ radius: CGFloat, in rect: CGRect) -> CGFloat {
        guard radius.isFinite, rect.width.isFinite, rect.height.isFinite else { return 0 }
        return max(0, min(radius, min(rect.width, rect.height) / 2))
    }

    var radius: CGFloat
    var corners: UIRectCorner
    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }
    func path(in rect: CGRect) -> Path {
        // A negative or non-finite radius (bad animation input) never reaches
        // the path; the radius is also capped at half the shorter side.
        let r = Self.safeRadius(radius, in: rect)
        let tl = corners.contains(.topLeft) ? r : 0
        let tr = corners.contains(.topRight) ? r : 0
        let bl = corners.contains(.bottomLeft) ? r : 0
        let br = corners.contains(.bottomRight) ? r : 0
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: tl, bottomLeadingRadius: bl,
            bottomTrailingRadius: br, topTrailingRadius: tr,
            style: .continuous
        )
        return shape.path(in: rect)
    }
}

#if canImport(UIKit)
import UIKit

struct LegacyRoundedCorner: Shape {
    /// Clamp to [0, half the shorter side]; non-finite → 0.
    static func safeRadius(_ radius: CGFloat, in rect: CGRect) -> CGFloat {
        guard radius.isFinite, rect.width.isFinite, rect.height.isFinite else { return 0 }
        return max(0, min(radius, min(rect.width, rect.height) / 2))
    }

    var radius: CGFloat
    var corners: UIRectCorner
    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }
    func path(in rect: CGRect) -> Path {
        // A negative or non-finite radius (bad animation input) never reaches
        // the path; the radius is also capped at half the shorter side.
        let r = Self.safeRadius(radius, in: rect)
        let bezier = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: r, height: r)
        )
        return Path(bezier.cgPath)
    }
}
#endif
