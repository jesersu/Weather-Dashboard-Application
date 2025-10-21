// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

public struct DollarGeneralPersist {
    /// Get data from cache
    ///
    /// - Parameter key: cache key
    /// - Returns: data in string format
    public static func getCacheData(key: String) -> String {
        let preferences = UserDefaults.standard
        if let value = preferences.string(forKey: key) {
            return value
        } else {
            return ""
        }
    }

    /// Save data to cache
    ///
    /// - Parameters:
    ///   - value: value to save
    ///   - key: cache key
    public static func saveCache(key: String, value: String) {
        let preferences = UserDefaults.standard
        preferences.set(value, forKey: key)
        didSaveCache(preferences: preferences)
    }

    /// Remove data from cache
    ///
    /// - Parameter key: cache key
    public static func removeCache(key: String) {
        let preferences = UserDefaults.standard
        preferences.removeObject(forKey: key)
        didSaveCache(preferences: preferences)
    }

    /// Verify if data was saved
    ///
    /// - Parameter preferences: UserDefaults instance
    private static func didSaveCache(preferences: UserDefaults) {
        let didSave = preferences.synchronize()
        if !didSave {
            print("ERROR: Could not save cache!")
        }
    }
}
