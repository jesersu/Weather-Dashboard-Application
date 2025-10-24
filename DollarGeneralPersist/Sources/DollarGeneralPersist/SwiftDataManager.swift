//
//  SwiftDataManager.swift
//  DollarGeneralPersist
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import SwiftData

/// Protocol for SwiftData operations (enables testing with mocks)
@MainActor
public protocol SwiftDataManagerProtocol {
    // Favorites
    func saveFavorite(_ favorite: FavoriteCity) throws
    func removeFavorite(id: String) throws
    func getFavorites() throws -> [FavoriteCity]
    func isFavorite(cityName: String) throws -> Bool

    // History
    func addToHistory(_ item: SearchHistoryItem) throws
    func getHistory() throws -> [SearchHistoryItem]
    func removeHistoryItem(id: String) throws
    func clearHistory() throws
}

/// SwiftData manager for persistent storage of favorites and history
/// Thread-safe operations using @MainActor
@MainActor
public final class SwiftDataManager: SwiftDataManagerProtocol {

    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let maxHistoryItems = 20

    /// Initialize with a ModelContainer
    /// - Parameter modelContainer: The SwiftData container (can be in-memory for testing)
    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)

        // Configure context for better performance
        modelContext.autosaveEnabled = true
    }

    // MARK: - Favorites

    /// Save a city to favorites
    /// - Parameter favorite: FavoriteCity to save
    /// - Throws: SwiftData errors
    public func saveFavorite(_ favorite: FavoriteCity) throws {
        // Check for duplicates (case-insensitive)
        // Fetch all and filter in Swift (SwiftData predicates don't support lowercased())
        let descriptor = FetchDescriptor<FavoriteCityModel>()
        let allFavorites = try modelContext.fetch(descriptor)

        let lowercasedName = favorite.cityName.lowercased()
        let exists = allFavorites.contains { $0.cityName.lowercased() == lowercasedName }

        guard !exists else {
            // Already exists, don't add duplicate
            return
        }

        // Convert and insert
        let model = FavoriteCityModel.from(favorite)
        modelContext.insert(model)
        try modelContext.save()
    }

    /// Remove a favorite city by ID
    /// - Parameter id: Favorite city ID (UUID string)
    /// - Throws: SwiftData errors
    public func removeFavorite(id: String) throws {
        guard let uuid = UUID(uuidString: id) else { return }

        let predicate = #Predicate<FavoriteCityModel> { model in
            model.id == uuid
        }

        let descriptor = FetchDescriptor<FavoriteCityModel>(predicate: predicate)
        let models = try modelContext.fetch(descriptor)

        for model in models {
            modelContext.delete(model)
        }

        try modelContext.save()
    }

    /// Get all favorite cities
    /// - Returns: Array of favorite cities, sorted by most recently added
    /// - Throws: SwiftData errors
    public func getFavorites() throws -> [FavoriteCity] {
        let descriptor = FetchDescriptor<FavoriteCityModel>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )

        let models = try modelContext.fetch(descriptor)
        return models.map { $0.toFavoriteCity() }
    }

    /// Check if a city is in favorites
    /// - Parameter cityName: City name to check (case-insensitive)
    /// - Returns: true if city is in favorites
    /// - Throws: SwiftData errors
    public func isFavorite(cityName: String) throws -> Bool {
        // Fetch all and filter in Swift (SwiftData predicates don't support lowercased())
        let descriptor = FetchDescriptor<FavoriteCityModel>()
        let allFavorites = try modelContext.fetch(descriptor)

        let lowercasedName = cityName.lowercased()
        return allFavorites.contains { $0.cityName.lowercased() == lowercasedName }
    }

    // MARK: - Search History

    /// Add a search to history
    /// - Parameter item: SearchHistoryItem to add
    /// - Throws: SwiftData errors
    public func addToHistory(_ item: SearchHistoryItem) throws {
        // Convert and insert at beginning (most recent first)
        let model = SearchHistoryModel.from(item)
        modelContext.insert(model)

        // Maintain max items - fetch all and delete oldest if needed
        let descriptor = FetchDescriptor<SearchHistoryModel>(
            sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
        )

        let allItems = try modelContext.fetch(descriptor)

        if allItems.count > maxHistoryItems {
            // Delete oldest items
            let itemsToDelete = allItems.dropFirst(maxHistoryItems)
            for oldItem in itemsToDelete {
                modelContext.delete(oldItem)
            }
        }

        try modelContext.save()
    }

    /// Get search history
    /// - Returns: Array of search history items, sorted by most recent
    /// - Throws: SwiftData errors
    public func getHistory() throws -> [SearchHistoryItem] {
        let descriptor = FetchDescriptor<SearchHistoryModel>(
            sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
        )

        let models = try modelContext.fetch(descriptor)
        return models.map { $0.toSearchHistoryItem() }
    }

    /// Remove a history item by ID
    /// - Parameter id: History item ID (UUID string)
    /// - Throws: SwiftData errors
    public func removeHistoryItem(id: String) throws {
        guard let uuid = UUID(uuidString: id) else { return }

        let predicate = #Predicate<SearchHistoryModel> { model in
            model.id == uuid
        }

        let descriptor = FetchDescriptor<SearchHistoryModel>(predicate: predicate)
        let models = try modelContext.fetch(descriptor)

        for model in models {
            modelContext.delete(model)
        }

        try modelContext.save()
    }

    /// Clear all search history
    /// - Throws: SwiftData errors
    public func clearHistory() throws {
        let descriptor = FetchDescriptor<SearchHistoryModel>()
        let models = try modelContext.fetch(descriptor)

        for model in models {
            modelContext.delete(model)
        }

        try modelContext.save()
    }
}

// MARK: - Model Container Factory

extension SwiftDataManager {
    /// Create a persistent ModelContainer for production use
    /// - Returns: ModelContainer configured for persistent storage
    /// - Throws: Configuration errors
    nonisolated public static func createPersistentContainer() throws -> ModelContainer {
        let schema = Schema([
            FavoriteCityModel.self,
            SearchHistoryModel.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    /// Create an in-memory ModelContainer for testing
    /// - Returns: ModelContainer configured for in-memory storage
    /// - Throws: Configuration errors
    nonisolated public static func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            FavoriteCityModel.self,
            SearchHistoryModel.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
