// QRCodeGenerator.swift
// N3ON — Tools layer
// Generates a QR code UIImage from a string using CoreImage — no dependencies.
// The QR encodes the user's ID and is permanent to their account.

import UIKit
import CoreImage.CIFilterBuiltins

enum QRCodeGenerator {
    /// Output side length is clamped to this range (pt). The upper bound stops a
    /// caller asking CoreImage for a gigapixel bitmap; 1,024 is far beyond any
    /// on-screen QR (they render at 200–300).
    static let sizeRange: ClosedRange<CGFloat> = 32...1_024

    /// CIContext is expensive to create (Apple: "create one and reuse it") —
    /// one shared context instead of one per QR.
    private static let context = CIContext()

    /// Returns a high-contrast white-on-black QR code image.
    /// Returns nil only if CoreImage filters are unavailable (extremely unlikely on iOS).
    static func make(from string: String, size requested: CGFloat = 300) -> UIImage? {
        let size = min(max(requested.isFinite ? requested : 300, sizeRange.lowerBound), sizeRange.upperBound)
        let filter = CIFilter.qrCodeGenerator()
        guard let data = string.data(using: .ascii) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // highest error correction

        guard let outputImage = filter.outputImage else { return nil }

        // Scale up from the tiny native output to the requested size
        let scaleX = size / outputImage.extent.width
        let scaleY = size / outputImage.extent.height
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Invert so code is white-on-black for dark-mode screens
        guard let invertFilter = CIFilter(name: "CIColorInvert") else {
            // Fall back to black-on-white if invert not available
            guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
            return UIImage(cgImage: cgImage)
        }
        invertFilter.setValue(scaled, forKey: kCIInputImageKey)
        guard let inverted = invertFilter.outputImage,
              let cgImage = context.createCGImage(inverted, from: inverted.extent)
        else { return nil }

        return UIImage(cgImage: cgImage)
    }
}
