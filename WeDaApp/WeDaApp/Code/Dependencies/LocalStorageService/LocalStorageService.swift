//
//  LocalStorageService.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import DollarGeneralPersist

/// Protocol for local storage operations
public protocol LocalStorageServiceProtocol {
    func saveFavorite(_ favorite: FavoriteCity) throws
    func removeFavorite(id: String) throws
    func getFavorites() throws -> [FavoriteCity]
    func isFavorite(cityName: String) throws -> Bool

    func addToHistory(_ item: SearchHistoryItem) throws
    func getHistory() throws -> [SearchHistoryItem]
    func removeHistoryItem(id: String) throws
    func clearHistory() throws
}

/// Service for managing local data persistence using SwiftData
/// Delegates to SwiftDataManager for all storage operations
public class LocalStorageService: LocalStorageServiceProtocol {

    private let swiftDataManager: SwiftDataManagerProtocol

    /// Shared instance using persistent storage (lazy initialized on first access)
    public static let shared: LocalStorageService = {
        do {
            let container = try SwiftDataManager.createPersistentContainer()
            return MainActor.assumeIsolated {
                let manager = SwiftDataManager(modelContainer: container)
                return LocalStorageService(swiftDataManager: manager)
            }
        } catch {
            fatalError("Failed to create LocalStorageService: \(error)")
        }
    }()

    /// Initialize with SwiftDataManager (injected for testability)
    /// - Parameter swiftDataManager: The SwiftData manager to use
    public init(swiftDataManager: SwiftDataManagerProtocol) {
        self.swiftDataManager = swiftDataManager
    }

    /// Convenience initializer that uses the shared instance's SwiftDataManager
    public convenience init() {
        self.init(swiftDataManager: LocalStorageService.shared.swiftDataManager)
    }

    // MARK: - Favorites

    /// Save a city to favorites
    /// - Parameter favorite: FavoriteCity to save
    /// - Throws: SwiftData errors
    @MainActor
    public func saveFavorite(_ favorite: FavoriteCity) throws {
        try swiftDataManager.saveFavorite(favorite)
    }

    /// Remove a favorite city by ID
    /// - Parameter id: Favorite city ID
    /// - Throws: SwiftData errors
    @MainActor
    public func removeFavorite(id: String) throws {
        try swiftDataManager.removeFavorite(id: id)
    }

    /// Get all favorite cities
    /// - Returns: Array of favorite cities, sorted by most recently added
    /// - Throws: SwiftData errors
    @MainActor
    public func getFavorites() throws -> [FavoriteCity] {
        return try swiftDataManager.getFavorites()
    }

    /// Check if a city is in favorites
    /// - Parameter cityName: City name to check
    /// - Returns: true if city is in favorites
    /// - Throws: SwiftData errors
    @MainActor
    public func isFavorite(cityName: String) throws -> Bool {
        return try swiftDataManager.isFavorite(cityName: cityName)
    }

    // MARK: - Search History

    /// Add a search to history
    /// - Parameter item: SearchHistoryItem to add
    /// - Throws: SwiftData errors
    @MainActor
    public func addToHistory(_ item: SearchHistoryItem) throws {
        try swiftDataManager.addToHistory(item)
    }

    /// Get search history
    /// - Returns: Array of search history items, sorted by most recent
    /// - Throws: SwiftData errors
    @MainActor
    public func getHistory() throws -> [SearchHistoryItem] {
        return try swiftDataManager.getHistory()
    }

    /// Remove a history item by ID
    /// - Parameter id: History item ID
    /// - Throws: SwiftData errors
    @MainActor
    public func removeHistoryItem(id: String) throws {
        try swiftDataManager.removeHistoryItem(id: id)
    }

    /// Clear all search history
    /// - Throws: SwiftData errors
    @MainActor
    public func clearHistory() throws {
        try swiftDataManager.clearHistory()
    }
}

// MARK: - Errors

enum LocalStorageError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data for storage"
        case .decodingFailed:
            return "Failed to decode data from storage"
        }
    }
}
