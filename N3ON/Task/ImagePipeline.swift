//
//  ImagePipeline.swift
//  N3ON
//
//  Created by liam howe on 24/8/2025.
//

import Foundation
import UIKit

struct ImagePipeline {
    struct Config {
        let maxDimension: CGFloat
        let jpegQuality: CGFloat
        static let avatar = Config(maxDimension: 512, jpegQuality: 0.82)
        static let poster = Config(maxDimension: 1600, jpegQuality: 0.88)
        static let feed = Config(maxDimension: 1400, jpegQuality: 0.85)
    }
    static func makeJPEGData(from image: UIImage, config: Config) -> Data? {
        let fixed = fixOrientation(image)
        let scaled = downscale(fixed, maxDimension: config.maxDimension)
        return scaled.jpegData(compressionQuality: config.jpegQuality)
    }
    
    /// `maxDimension` is in PIXELS. Rendering at the screen scale (as this
    /// did) multiplied it by 3 on a 3x iPhone — a "512 px" avatar uploaded
    /// at 1536×1536, nine times the bytes. Now measured and drawn at scale 1.
    static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let pixelW = image.size.width * image.scale
        let pixelH = image.size.height * image.scale
        let maxSide = max(pixelW, pixelH)
        guard maxSide > maxDimension, maxDimension > 0 else { return image }
        let scale = maxDimension / maxSide
        let target = CGSize(width: (pixelW * scale).rounded(.down), height: (pixelH * scale).rounded(.down))
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1
        let r = UIGraphicsImageRenderer(size: target, format: fmt)
        return r.image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
    }
    
    static func fixOrientation(_ image: UIImage) -> UIImage {
            guard image.imageOrientation != .up else { return image }
            let fmt = UIGraphicsImageRendererFormat()
            fmt.scale = image.scale
            let r = UIGraphicsImageRenderer(size: image.size, format: fmt)
            return r.image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }
        }
}
