//
//  ImageCache.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import UIKit
import Foundation

/// OPTIMIZATION: Memory-efficient image caching using NSCache
///
/// NSCache automatically handles memory warnings by evicting objects when memory is low.
/// This is critical for mobile apps where memory is limited.
///
/// Benefits:
/// - Automatic memory management (respects system memory warnings)
/// - Thread-safe (can be accessed from multiple threads)
/// - No manual cleanup required
/// - Prevents redundant network calls for same images
final class ImageCache {
    // MARK: - Singleton

    static let shared = ImageCache()

    // MARK: - Properties

    /// OPTIMIZATION: NSCache is preferred over Dictionary for caching on iOS
    /// - Automatically evicts objects under memory pressure
    /// - Thread-safe without explicit locking
    /// - Cost-based eviction policies
    private let cache = NSCache<NSString, UIImage>()

    // MARK: - Initialization

    private init() {
        // OPTIMIZATION: Set cache limits based on device capabilities
        // Total cost limit: ~50MB (assuming average image is 100KB)
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB

        // Count limit: Maximum 500 images
        cache.countLimit = 500

        // OPTIMIZATION: Listen for memory warnings to proactively clear cache
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// Retrieve image from cache
    /// - Parameter url: Image URL as cache key
    /// - Returns: Cached UIImage if available, nil otherwise
    func get(forKey url: URL) -> UIImage? {
        return cache.object(forKey: url.absoluteString as NSString)
    }

    /// Store image in cache
    /// - Parameters:
    ///   - image: UIImage to cache
    ///   - url: Image URL as cache key
    ///   - cost: Optional cost for cache eviction policy (defaults to image byte size)
    func set(_ image: UIImage, forKey url: URL, cost: Int? = nil) {
        // OPTIMIZATION: Calculate image cost based on actual memory usage
        let imageCost = cost ?? Int(image.size.width * image.size.height * 4) // 4 bytes per pixel (RGBA)
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: imageCost)
    }

    /// Remove specific image from cache
    /// - Parameter url: Image URL
    func remove(forKey url: URL) {
        cache.removeObject(forKey: url.absoluteString as NSString)
    }

    /// Clear entire cache (called on memory warnings)
    @objc
    func clearCache() {
        cache.removeAllObjects()
        print("🧹 ImageCache: Cleared all cached images due to memory warning")
    }

    // MARK: - Statistics (for debugging/profiling)

    #if DEBUG
    /// Get current cache count (debug only)
    var debugCacheCount: Int {
        return 0 // NSCache doesn't expose count, but we can track manually if needed
    }
    #endif
}

// MARK: - Performance Notes

/*
 MOBILE OPTIMIZATION TECHNIQUES DEMONSTRATED:

 1. **NSCache over Dictionary**:
 - Automatically manages memory under pressure
 - Thread-safe without explicit locks
 - Better for iOS/mobile than custom caching

 2. **Memory Warning Handling**:
 - Listens to UIApplication.didReceiveMemoryWarningNotification
 - Proactively clears cache to prevent app termination
 - Critical for iOS where memory is limited

 3. **Cost-Based Eviction**:
 - Images with higher cost evicted first
 - Calculates cost based on pixel dimensions
 - Ensures cache doesn't grow unbounded

 4. **Lazy Loading**:
 - Images loaded on-demand
 - Cache miss triggers network request
 - Reduces initial memory footprint

 5. **Singleton Pattern**:
 - Single shared instance reduces overhead
 - Centralized cache management
 - Prevents duplicate caches

 PROFILING WITH INSTRUMENTS:
 - Use "Allocations" instrument to verify memory savings
 - Use "Network" instrument to confirm reduced requests
 - Monitor "Dirty Memory" to see actual memory usage
 - Check "Leaks" instrument to verify no retain cycles
 */
