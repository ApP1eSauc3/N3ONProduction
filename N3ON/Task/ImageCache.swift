// ImageCache.swift
// N3ON
//
// In-memory image cache keyed by S3 key. Sits in front of StorageUploader so
// every avatar/poster/venue image is signed + downloaded at most once per
// process lifetime, instead of on every view appearance.

import Foundation
import UIKit
import Amplify

enum ImageCacheError: Error {
    case decodingFailed
}

final class ImageCache {
    static let shared = ImageCache()

    // NSCache is internally thread-safe — no additional locking needed.
    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    /// Returns the cached image for `key`, signing + downloading only on a cache miss.
    static func loadImage(forKey key: String, access: StorageAccessLevel) async throws -> UIImage {
        if let cached = shared.image(forKey: key) {
            return cached
        }
        let url = try await StorageUploader.signedURL(for: key, access: access)
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw ImageCacheError.decodingFailed
        }
        shared.insert(image, forKey: key)
        return image
    }
}
