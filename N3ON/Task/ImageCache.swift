// ImageCache.swift
// N3ON
//
// Two-tier image cache keyed by S3 key.
//
//   memory  — NSCache of decoded UIImages, cost-limited by pixel bytes, so a
//             scroll through poster-heavy screens can't grow unbounded.
//   disk    — raw downloaded bytes under Caches/ImageCache/, so a cold launch
//             reuses yesterday's downloads instead of re-signing + re-fetching
//             every avatar/poster. The OS may purge Caches under pressure —
//             that's the contract we want.
//
// Downloads go through Amplify.Storage.downloadData (not URLSession — banned
// for image downloads, and this skips the signed-URL round trip entirely).
// Concurrent requests for the same key are coalesced: one download, N waiters.
//
// Invalidation: poster/venue/feed keys embed a UUID per upload, so they are
// immutable and never need invalidating. Avatar and profile-audio keys are
// deterministic (avatars/{uid}.jpg) — upload paths MUST call
// `ImageCache.store(data:forKey:)` after overwriting one of those keys, or
// every open view keeps serving the old bytes for the process lifetime.

import Foundation
import UIKit
import ImageIO
import CryptoKit
import Amplify

enum ImageCacheError: Error {
    case decodingFailed
}

final class ImageCache {
    static let shared = ImageCache()

    // NSCache is internally thread-safe — no additional locking needed.
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        // ~64 MB of decoded pixels. A 512px avatar ≈ 1 MB, a 1600px poster
        // downsampled to 1200px ≈ 5.8 MB — room for a full screen of posters
        // plus every avatar in a session before eviction starts.
        cache.totalCostLimit = 64 * 1_024 * 1_024
    }

    /// Synchronous memory-tier lookup. Views use this to avoid a placeholder
    /// flash when the image is already decoded.
    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString, cost: image.pixelCost)
    }

    fileprivate func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    // MARK: — Loading

    /// Returns the image for `key`: memory → disk → Amplify download.
    /// Concurrent calls for the same key share one download.
    static func loadImage(forKey key: String, access: StorageAccessLevel) async throws -> UIImage {
        if let cached = shared.image(forKey: key) {
            return cached
        }
        return try await ImageLoader.shared.load(key: key, access: access)
    }

    /// Upload paths call this after overwriting a deterministic key
    /// (avatars/{uid}.jpg) so open views pick up the new bytes immediately
    /// instead of serving the stale cache entry until relaunch.
    @discardableResult
    static func store(data: Data, forKey key: String) async -> UIImage? {
        await ImageLoader.shared.store(data: data, key: key)
    }

    /// Drops both tiers for `key`. The next load re-downloads.
    static func invalidate(_ key: String) async {
        await ImageLoader.shared.invalidate(key: key)
    }
}

private extension UIImage {
    /// Approximate decoded size in bytes — NSCache cost.
    var pixelCost: Int {
        guard let cg = cgImage else { return 4 * Int(size.width * size.height) }
        return cg.width * cg.height * 4
    }
}

// MARK: — Loader actor (disk tier + request coalescing)

private actor ImageLoader {
    static let shared = ImageLoader()

    private var inFlight: [String: Task<UIImage, Error>] = [:]
    private var didTrimDisk = false

    /// Decode bound: largest display surface is a full-width poster,
    /// 390pt @3x ≈ 1170px. Uploads are already capped at 1600px by
    /// ImagePipeline; this trims the decode, not the stored bytes.
    private static let maxDecodePixelSize = 1200

    /// Disk tier budget. Trimmed oldest-first once per process.
    private static let maxDiskBytes = 128 * 1_024 * 1_024

    func load(key: String, access: StorageAccessLevel) async throws -> UIImage {
        if let existing = inFlight[key] {
            return try await existing.value
        }

        trimDiskIfNeeded()

        let task = Task<UIImage, Error> {
            // Disk hit — decode without touching the network.
            let fileURL = Self.fileURL(for: key)
            if let data = try? Data(contentsOf: fileURL),
               let image = Self.decodeDownsampled(data) {
                ImageCache.shared.insert(image, forKey: key)
                return image
            }

            let data = try await Amplify.Storage.downloadData(
                key: key,
                options: .init(accessLevel: access)
            ).value

            guard let image = Self.decodeDownsampled(data) else {
                throw ImageCacheError.decodingFailed
            }
            try? data.write(to: fileURL, options: .atomic)
            ImageCache.shared.insert(image, forKey: key)
            return image
        }

        inFlight[key] = task
        defer { inFlight[key] = nil }
        return try await task.value
    }

    func store(data: Data, key: String) -> UIImage? {
        inFlight[key]?.cancel()
        inFlight[key] = nil
        try? data.write(to: Self.fileURL(for: key), options: .atomic)
        guard let image = Self.decodeDownsampled(data) else {
            ImageCache.shared.remove(forKey: key)
            return nil
        }
        ImageCache.shared.insert(image, forKey: key)
        return image
    }

    func invalidate(key: String) {
        inFlight[key]?.cancel()
        inFlight[key] = nil
        ImageCache.shared.remove(forKey: key)
        try? FileManager.default.removeItem(at: Self.fileURL(for: key))
    }

    // MARK: — Decoding

    /// ImageIO thumbnail decode: produces a bitmap no larger than
    /// `maxDecodePixelSize` on its long edge without ever materialising the
    /// full-resolution image — the decoded poster costs ~5.8 MB instead of
    /// ~10 MB, and the work happens here, not at first render.
    private static func decodeDownsampled(_ data: Data) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDecodePixelSize
        ] as CFDictionary
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return nil
        }
        return UIImage(cgImage: cg)
    }

    // MARK: — Disk tier

    private static let directory: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("ImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static func fileURL(for key: String) -> URL {
        // Keys contain "/" — hash to a flat, filesystem-safe name.
        let digest = SHA256.hash(data: Data(key.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(name)
    }

    /// Once per process: evict oldest files until the disk tier is under
    /// budget. Runs off the actor so it never delays a load.
    private func trimDiskIfNeeded() {
        guard !didTrimDisk else { return }
        didTrimDisk = true
        Task.detached(priority: .utility) {
            let fm = FileManager.default
            let keys: [URLResourceKey] = [.contentModificationDateKey, .totalFileAllocatedSizeKey]
            guard let urls = try? fm.contentsOfDirectory(
                at: Self.directory, includingPropertiesForKeys: keys
            ) else { return }

            var entries: [(url: URL, date: Date, size: Int)] = urls.compactMap { url in
                guard let values = try? url.resourceValues(forKeys: Set(keys)) else { return nil }
                return (url, values.contentModificationDate ?? .distantPast,
                        values.totalFileAllocatedSize ?? 0)
            }
            var total = entries.reduce(0) { $0 + $1.size }
            guard total > Self.maxDiskBytes else { return }

            entries.sort { $0.date < $1.date }   // oldest first
            for entry in entries where total > Self.maxDiskBytes {
                try? fm.removeItem(at: entry.url)
                total -= entry.size
            }
        }
    }
}
