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
        static feed = Config(maxDimension: 1400, jpegQuality: 0.85)
    }
    static func makeJPEGData(from image: UIImage, config: Config) -> Data? {
        let fixed = fixOrientation(image)
        let scaled = downscale(fixed, maxDimension: config.maxDimension)
        return scaled.jpegData(compressionQuality: config.jpegQuality)
    }
    
    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
       let maxSide = max(image.size.width, image.size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = UIScreen.main.scale
        let r = UIGraphicsImageRenderer(size: target, format: fmt)
        return r.image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
    }
    
    private static func fixOrientation(_ image: UIImage) -> UIImage {
            guard image.imageOrientation != .up else { return image }
            let fmt = UIGraphicsImageRendererFormat()
            fmt.scale = image.scale
            let r = UIGraphicsImageRenderer(size: image.size, format: fmt)
            return r.image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }
        }
}
