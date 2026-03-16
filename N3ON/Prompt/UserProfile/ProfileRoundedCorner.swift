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
    var radius: CGFloat
    var corners: UIRectCorner
    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }
    func path(in rect: CGRect) -> Path {
        let r = min(radius, min(rect.width, rect.height) / 2)
        let tl = corners.contains(.topLeft) ? r : 0
        let tr = corners.contains(.topRight) ? r : 0
        let bl = corners.contains(.bottomLeft) ? r : 0
        let br = corners.contains(.bottomRight) ? r : 0
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: tl, topTrailingRadius: tr,
            bottomLeadingRadius: bl, bottomTrailingRadius: br,
            style: .continuous
        )
        return Path(shape.path(in: rect))
    }
}

#if canImport(UIKit)
import UIKit

struct LegacyRoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }
    func path(in rect: CGRect) -> Path {
        let r = min(radius, min(rect.width, rect.height) / 2)
        let bezier = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: r, height: r)
        )
        return Path(bezier.cgPath)
    }
}
#endif
