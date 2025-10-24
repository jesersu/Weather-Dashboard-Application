//
//  SwiftDataManagerTests.swift
//  DollarGeneralPersistTests
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import XCTest
import SwiftData
@testable import DollarGeneralPersist

/// TDD Tests for SwiftDataManager
/// These tests define the expected behavior before implementation
@MainActor
final class SwiftDataManagerTests: XCTestCase {

    var manager: SwiftDataManager!
    var container: ModelContainer!

    override func setUp() async throws {
        // Create in-memory container for testing
        let schema = Schema([
            FavoriteCityModel.self,
            SearchHistoryModel.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        manager = SwiftDataManager(modelContainer: container)
    }

    override func tearDown() async throws {
        manager = nil
        container = nil
    }

    // MARK: - Favorites Tests

    func test_saveFavorite_success() throws {
        // Given
        let coordinates = Coordinates(lon: -0.1257, lat: 51.5074)
        let favorite = FavoriteCity(
            cityName: "London",
            country: "GB",
            coordinates: coordinates
        )

        // When
        try manager.saveFavorite(favorite)

        // Then
        let favorites = try manager.getFavorites()
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.cityName, "London")
        XCTAssertEqual(favorites.first?.country, "GB")
    }

    func test_saveFavorite_preventsDuplicates() throws {
        // Given
        let coordinates = Coordinates(lon: 2.3522, lat: 48.8566)
        let paris1 = FavoriteCity(cityName: "Paris", country: "FR", coordinates: coordinates)
        let paris2 = FavoriteCity(cityName: "paris", country: "FR", coordinates: coordinates) // lowercase

        // When
        try manager.saveFavorite(paris1)
        try manager.saveFavorite(paris2) // Should not add duplicate

        // Then
        let favorites = try manager.getFavorites()
        XCTAssertEqual(favorites.count, 1, "Should not save duplicate cities (case-insensitive)")
    }

    func test_removeFavorite_success() throws {
        // Given
        let coordinates = Coordinates(lon: 13.4050, lat: 52.5200)
        let berlin = FavoriteCity(cityName: "Berlin", country: "DE", coordinates: coordinates)
        try manager.saveFavorite(berlin)

        // When
        try manager.removeFavorite(id: berlin.id)

        // Then
        let favorites = try manager.getFavorites()
        XCTAssertEqual(favorites.count, 0)
    }

    func test_getFavorites_returnsSortedByMostRecent() throws {
        // Given
        let london = FavoriteCity(
            cityName: "London",
            country: "GB",
            coordinates: Coordinates(lon: -0.1257, lat: 51.5074)
        )
        let paris = FavoriteCity(
            cityName: "Paris",
            country: "FR",
            coordinates: Coordinates(lon: 2.3522, lat: 48.8566)
        )

        // When
        try manager.saveFavorite(london)
        Thread.sleep(forTimeInterval: 0.01) // Ensure different timestamps
        try manager.saveFavorite(paris)

        // Then
        let favorites = try manager.getFavorites()
        XCTAssertEqual(favorites.count, 2)
        XCTAssertEqual(favorites.first?.cityName, "Paris") // Most recent first
        XCTAssertEqual(favorites.last?.cityName, "London")
    }

    func test_isFavorite_returnsTrue() throws {
        // Given
        let coordinates = Coordinates(lon: -3.7038, lat: 40.4168)
        let madrid = FavoriteCity(cityName: "Madrid", country: "ES", coordinates: coordinates)
        try manager.saveFavorite(madrid)

        // When
        let isFavorite = try manager.isFavorite(cityName: "Madrid")

        // Then
        XCTAssertTrue(isFavorite)
    }

    func test_isFavorite_returnsFalse() throws {
        // Given / When
        let isFavorite = try manager.isFavorite(cityName: "NonExistentCity")

        // Then
        XCTAssertFalse(isFavorite)
    }

    func test_isFavorite_caseInsensitive() throws {
        // Given
        let coordinates = Coordinates(lon: -3.7038, lat: 40.4168)
        let madrid = FavoriteCity(cityName: "Madrid", country: "ES", coordinates: coordinates)
        try manager.saveFavorite(madrid)

        // When / Then
        XCTAssertTrue(try manager.isFavorite(cityName: "madrid"))
        XCTAssertTrue(try manager.isFavorite(cityName: "MADRID"))
        XCTAssertTrue(try manager.isFavorite(cityName: "Madrid"))
    }

    // MARK: - History Tests

    func test_addToHistory_success() throws {
        // Given
        let history = SearchHistoryItem(
            cityName: "Tokyo",
            country: "JP"
        )

        // When
        try manager.addToHistory(history)

        // Then
        let items = try manager.getHistory()
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.cityName, "Tokyo")
    }

    func test_addToHistory_maintainsMaxItems() throws {
        // Given - Add 25 items (max is 20)
        for i in 1...25 {
            let item = SearchHistoryItem(
                cityName: "City\(i)",
                country: "US"
            )
            try manager.addToHistory(item)
        }

        // When
        let items = try manager.getHistory()

        // Then
        XCTAssertEqual(items.count, 20, "Should maintain maximum of 20 items")
        XCTAssertEqual(items.first?.cityName, "City25", "Most recent should be first")
        XCTAssertEqual(items.last?.cityName, "City6", "Oldest items should be removed")
    }

    func test_getHistory_returnsSortedByMostRecent() throws {
        // Given - Create items with explicit timestamps
        let baseDate = Date()
        let rome = SearchHistoryItem(
            cityName: "Rome",
            country: "IT",
            searchedAt: baseDate.addingTimeInterval(-2) // 2 seconds ago
        )
        let athens = SearchHistoryItem(
            cityName: "Athens",
            country: "GR",
            searchedAt: baseDate.addingTimeInterval(-1) // 1 second ago
        )
        let oslo = SearchHistoryItem(
            cityName: "Oslo",
            country: "NO",
            searchedAt: baseDate // Now (most recent)
        )

        // When
        try manager.addToHistory(rome)
        try manager.addToHistory(athens)
        try manager.addToHistory(oslo)

        // Then
        let items = try manager.getHistory()
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].cityName, "Oslo") // Most recent
        XCTAssertEqual(items[1].cityName, "Athens")
        XCTAssertEqual(items[2].cityName, "Rome") // Oldest
    }

    func test_removeHistoryItem_success() throws {
        // Given
        let dublin = SearchHistoryItem(cityName: "Dublin", country: "IE")
        try manager.addToHistory(dublin)

        // When
        try manager.removeHistoryItem(id: dublin.id)

        // Then
        let items = try manager.getHistory()
        XCTAssertEqual(items.count, 0)
    }

    func test_clearHistory_success() throws {
        // Given
        try manager.addToHistory(SearchHistoryItem(cityName: "City1", country: "US"))
        try manager.addToHistory(SearchHistoryItem(cityName: "City2", country: "US"))
        try manager.addToHistory(SearchHistoryItem(cityName: "City3", country: "US"))

        // When
        try manager.clearHistory()

        // Then
        let items = try manager.getHistory()
        XCTAssertEqual(items.count, 0)
    }

    // MARK: - Error Handling Tests

    func test_removeFavorite_nonExistentID_doesNotThrow() throws {
        // Given
        let nonExistentID = UUID().uuidString

        // When / Then
        XCTAssertNoThrow(try manager.removeFavorite(id: nonExistentID))
    }

    func test_removeHistoryItem_nonExistentID_doesNotThrow() throws {
        // Given
        let nonExistentID = UUID().uuidString

        // When / Then
        XCTAssertNoThrow(try manager.removeHistoryItem(id: nonExistentID))
    }

    // MARK: - Thread Safety Tests

    func test_concurrentFavoriteOperations_threadSafe() async throws {
        // Given
        let coordinates = Coordinates(lon: 0, lat: 0)

        // When - Perform concurrent operations
        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask { @MainActor in
                    let favorite = FavoriteCity(
                        cityName: "City\(i)",
                        country: "US",
                        coordinates: coordinates
                    )
                    try? self.manager.saveFavorite(favorite)
                }
            }
        }

        // Then
        let favorites = try manager.getFavorites()
        XCTAssertEqual(favorites.count, 10, "All favorites should be saved without data race")
    }

    func test_concurrentHistoryOperations_threadSafe() async throws {
        // When - Perform concurrent operations
        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask { @MainActor in
                    let item = SearchHistoryItem(
                        cityName: "City\(i)",
                        country: "US"
                    )
                    try? self.manager.addToHistory(item)
                }
            }
        }

        // Then
        let items = try manager.getHistory()
        XCTAssertEqual(items.count, 10, "All history items should be saved without data race")
    }

    // MARK: - Data Persistence Tests

    func test_favoritesPersistedAcrossManagerInstances() throws {
        // Given
        let coordinates = Coordinates(lon: -74.0060, lat: 40.7128)
        let newYork = FavoriteCity(cityName: "New York", country: "US", coordinates: coordinates)
        try manager.saveFavorite(newYork)

        // When - Create new manager instance with same container
        let newManager = SwiftDataManager(modelContainer: container)
        let favorites = try newManager.getFavorites()

        // Then
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.cityName, "New York")
    }

    func test_historyPersistedAcrossManagerInstances() throws {
        // Given
        let seattle = SearchHistoryItem(cityName: "Seattle", country: "US")
        try manager.addToHistory(seattle)

        // When - Create new manager instance with same container
        let newManager = SwiftDataManager(modelContainer: container)
        let items = try newManager.getHistory()

        // Then
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.cityName, "Seattle")
    }
}
