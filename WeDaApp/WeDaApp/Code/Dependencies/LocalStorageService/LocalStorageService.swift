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
    func clearHistory() throws
}

/// Service for managing local data persistence (favorites and search history)
public class LocalStorageService: LocalStorageServiceProtocol {

    private let favoritesKey: String
    private let historyKey: String
    private let maxHistoryItems = 20

    public init(favoritesKey: String = KeysCache.favoriteCities,
                historyKey: String = KeysCache.searchHistory) {
        self.favoritesKey = favoritesKey
        self.historyKey = historyKey
    }

    // MARK: - Favorites

    /// Save a city to favorites
    /// - Parameter favorite: FavoriteCity to save
    /// - Throws: Encoding/Decoding errors
    public func saveFavorite(_ favorite: FavoriteCity) throws {
        var favorites = try getFavorites()

        // Prevent duplicates - check by city name (case-insensitive)
        if favorites.contains(where: { $0.cityName.lowercased() == favorite.cityName.lowercased() }) {
            return
        }

        favorites.append(favorite)

        let data = try JSONEncoder().encode(favorites)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw LocalStorageError.encodingFailed
        }

        DollarGeneralPersist.saveCache(key: favoritesKey, value: jsonString)
    }

    /// Remove a favorite city by ID
    /// - Parameter id: Favorite city ID
    /// - Throws: Encoding/Decoding errors
    public func removeFavorite(id: String) throws {
        var favorites = try getFavorites()
        favorites.removeAll { $0.id == id }

        let data = try JSONEncoder().encode(favorites)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw LocalStorageError.encodingFailed
        }

        DollarGeneralPersist.saveCache(key: favoritesKey, value: jsonString)
    }

    /// Get all favorite cities
    /// - Returns: Array of favorite cities, sorted by most recently added
    /// - Throws: Decoding errors
    public func getFavorites() throws -> [FavoriteCity] {
        let jsonString = DollarGeneralPersist.getCacheData(key: favoritesKey)

        guard !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8) else {
            return []
        }

        do {
            let favorites = try JSONDecoder().decode([FavoriteCity].self, from: data)
            return favorites.sorted { $0.addedAt > $1.addedAt }
        } catch {
            // If decoding fails, return empty array (corrupted data)
            return []
        }
    }

    /// Check if a city is in favorites
    /// - Parameter cityName: City name to check
    /// - Returns: true if city is in favorites
    /// - Throws: Decoding errors
    public func isFavorite(cityName: String) throws -> Bool {
        let favorites = try getFavorites()
        return favorites.contains { $0.cityName.lowercased() == cityName.lowercased() }
    }

    // MARK: - Search History

    /// Add a search to history
    /// - Parameter item: SearchHistoryItem to add
    /// - Throws: Encoding/Decoding errors
    public func addToHistory(_ item: SearchHistoryItem) throws {
        var history = try getHistory()

        // Add new item to beginning (most recent first)
        history.insert(item, at: 0)

        // Limit to max items
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }

        let data = try JSONEncoder().encode(history)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw LocalStorageError.encodingFailed
        }

        DollarGeneralPersist.saveCache(key: historyKey, value: jsonString)
    }

    /// Get search history
    /// - Returns: Array of search history items, sorted by most recent
    /// - Throws: Decoding errors
    public func getHistory() throws -> [SearchHistoryItem] {
        let jsonString = DollarGeneralPersist.getCacheData(key: historyKey)

        guard !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8) else {
            return []
        }

        do {
            let history = try JSONDecoder().decode([SearchHistoryItem].self, from: data)
            return history // Already sorted by most recent
        } catch {
            // If decoding fails, return empty array (corrupted data)
            return []
        }
    }

    /// Clear all search history
    /// - Throws: Encoding errors
    public func clearHistory() throws {
        DollarGeneralPersist.removeCache(key: historyKey)
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
