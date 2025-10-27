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
            SearchHistoryModel.self,
            WeatherCacheModel.self
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

    // MARK: - Weather Cache Tests

    func test_saveWeatherCache_success() throws {
        // Given
        let cache = WeatherCache(
            cityName: "London",
            currentWeatherJSON: "{\"temp\":20}",
            forecastJSON: "{\"list\":[]}",
            lastUpdated: Date()
        )

        // When
        try manager.saveWeatherCache(cache)

        // Then
        let retrieved = try manager.getWeatherCache(cityName: "London")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.cityName, "London")
        XCTAssertEqual(retrieved?.currentWeatherJSON, "{\"temp\":20}")
        XCTAssertEqual(retrieved?.forecastJSON, "{\"list\":[]}")
    }

    func test_getWeatherCache_nonExistent_returnsNil() throws {
        // When
        let result = try manager.getWeatherCache(cityName: "NonExistentCity")

        // Then
        XCTAssertNil(result)
    }

    func test_saveWeatherCache_updateExisting() throws {
        // Given - Save initial cache
        let oldCache = WeatherCache(
            cityName: "Paris",
            currentWeatherJSON: "{\"temp\":15}",
            forecastJSON: nil,
            lastUpdated: Date().addingTimeInterval(-1000)
        )
        try manager.saveWeatherCache(oldCache)

        // When - Update with new data
        let newCache = WeatherCache(
            cityName: "Paris",
            currentWeatherJSON: "{\"temp\":18}",
            forecastJSON: "{\"forecast\":true}",
            lastUpdated: Date()
        )
        try manager.saveWeatherCache(newCache)

        // Then - Should have only one cache entry with updated data
        let retrieved = try manager.getWeatherCache(cityName: "Paris")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.currentWeatherJSON, "{\"temp\":18}")
        XCTAssertEqual(retrieved?.forecastJSON, "{\"forecast\":true}")
    }

    func test_getWeatherCache_caseInsensitive() throws {
        // Given
        let cache = WeatherCache(
            cityName: "Tokyo",
            currentWeatherJSON: "{}",
            forecastJSON: nil
        )
        try manager.saveWeatherCache(cache)

        // When
        let resultLower = try manager.getWeatherCache(cityName: "tokyo")
        let resultUpper = try manager.getWeatherCache(cityName: "TOKYO")
        let resultMixed = try manager.getWeatherCache(cityName: "ToKyO")

        // Then - All should return the cache
        XCTAssertNotNil(resultLower)
        XCTAssertNotNil(resultUpper)
        XCTAssertNotNil(resultMixed)
    }

    func test_clearExpiredCaches_removesOnlyExpired() throws {
        // Given - Fresh cache (10 min old)
        let freshCache = WeatherCache(
            cityName: "Berlin",
            currentWeatherJSON: "{}",
            forecastJSON: nil,
            lastUpdated: Date().addingTimeInterval(-10 * 60)
        )
        try manager.saveWeatherCache(freshCache)

        // Given - Expired cache (40 min old)
        let expiredCache = WeatherCache(
            cityName: "Madrid",
            currentWeatherJSON: "{}",
            forecastJSON: nil,
            lastUpdated: Date().addingTimeInterval(-40 * 60)
        )
        try manager.saveWeatherCache(expiredCache)

        // When - Clear caches older than 30 minutes
        try manager.clearExpiredCaches(olderThanMinutes: 30)

        // Then
        let freshResult = try manager.getWeatherCache(cityName: "Berlin")
        let expiredResult = try manager.getWeatherCache(cityName: "Madrid")

        XCTAssertNotNil(freshResult, "Fresh cache should still exist")
        XCTAssertNil(expiredResult, "Expired cache should be removed")
    }

    func test_clearAllCaches_removesAllEntries() throws {
        // Given - Save multiple caches
        try manager.saveWeatherCache(WeatherCache(cityName: "City1", currentWeatherJSON: "{}", forecastJSON: nil))
        try manager.saveWeatherCache(WeatherCache(cityName: "City2", currentWeatherJSON: "{}", forecastJSON: nil))
        try manager.saveWeatherCache(WeatherCache(cityName: "City3", currentWeatherJSON: "{}", forecastJSON: nil))

        // When
        try manager.clearAllCaches()

        // Then
        XCTAssertNil(try manager.getWeatherCache(cityName: "City1"))
        XCTAssertNil(try manager.getWeatherCache(cityName: "City2"))
        XCTAssertNil(try manager.getWeatherCache(cityName: "City3"))
    }

    func test_saveWeatherCache_enforcesLimit() throws {
        // Given - Save 55 caches (exceeds limit of 50)
        for i in 1...55 {
            let cache = WeatherCache(
                cityName: "City\(i)",
                currentWeatherJSON: "{}",
                forecastJSON: nil,
                lastUpdated: Date().addingTimeInterval(TimeInterval(-i * 60)) // Older = higher number
            )
            try manager.saveWeatherCache(cache)
        }

        // When - Check total count
        // Note: This will be verified after implementation

        // Then - Should only keep 50 most recent
        // Most recent should exist (City1)
        XCTAssertNotNil(try manager.getWeatherCache(cityName: "City1"))

        // Oldest should be deleted (City55, City54, City53, City52, City51)
        XCTAssertNil(try manager.getWeatherCache(cityName: "City55"))
        XCTAssertNil(try manager.getWeatherCache(cityName: "City54"))
    }

    func test_weatherCachePersistedAcrossManagerInstances() throws {
        // Given
        let cache = WeatherCache(
            cityName: "Amsterdam",
            currentWeatherJSON: "{\"temp\":12}",
            forecastJSON: "{\"forecast\":true}"
        )
        try manager.saveWeatherCache(cache)

        // When - Create new manager instance with same container
        let newManager = SwiftDataManager(modelContainer: container)
        let retrieved = try newManager.getWeatherCache(cityName: "Amsterdam")

        // Then
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.cityName, "Amsterdam")
        XCTAssertEqual(retrieved?.currentWeatherJSON, "{\"temp\":12}")
    }

    func test_concurrentCacheOperations_threadSafe() async throws {
        // When - Perform concurrent cache operations
        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask { @MainActor in
                    let cache = WeatherCache(
                        cityName: "CacheCity\(i)",
                        currentWeatherJSON: "{\"temp\":\(i)}",
                        forecastJSON: nil
                    )
                    try? self.manager.saveWeatherCache(cache)
                }
            }
        }

        // Then - All caches should be saved
        for i in 1...10 {
            let result = try manager.getWeatherCache(cityName: "CacheCity\(i)")
            XCTAssertNotNil(result, "Cache for CacheCity\(i) should exist")
        }
    }

    func test_clearExpiredCaches_withZeroMinutes_removesAll() throws {
        // Given - Save caches with various ages
        try manager.saveWeatherCache(WeatherCache(cityName: "Recent", currentWeatherJSON: "{}", forecastJSON: nil))
        try manager.saveWeatherCache(WeatherCache(
            cityName: "Old",
            currentWeatherJSON: "{}",
            forecastJSON: nil,
            lastUpdated: Date().addingTimeInterval(-100)
        ))

        // When - Clear with 0 minutes (all are expired)
        try manager.clearExpiredCaches(olderThanMinutes: 0)

        // Then - All should be removed
        XCTAssertNil(try manager.getWeatherCache(cityName: "Recent"))
        XCTAssertNil(try manager.getWeatherCache(cityName: "Old"))
    }
}
