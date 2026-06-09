// QRCodeGenerator.swift
// N3ON — Tools layer
// Generates a QR code UIImage from a string using CoreImage — no dependencies.
// The QR encodes the user's ID and is permanent to their account.

import UIKit
import CoreImage.CIFilterBuiltins

enum QRCodeGenerator {
    /// Returns a high-contrast white-on-black QR code image.
    /// Returns nil only if CoreImage filters are unavailable (extremely unlikely on iOS).
    static func make(from string: String, size: CGFloat = 300) -> UIImage? {
        let context = CIContext()
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
