//
//  LocalStorageServiceTests.swift
//  WeDaAppTests
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//
// NOTE: These tests are disabled - using LocalStorageServiceSpec (Quick/Nimble) instead
// TODO: Update to new SwiftData-based API with @MainActor async tests

/*
import XCTest
import DollarGeneralPersist
@testable import WeDaApp

final class LocalStorageServiceTests: XCTestCase {

    var localStorageService: LocalStorageService!
    let testFavoritesKey = "test_favoriteCities"
    let testHistoryKey = "test_searchHistory"

    override func setUp() {
        super.setUp()
        localStorageService = LocalStorageService(
            favoritesKey: testFavoritesKey,
            historyKey: testHistoryKey
        )
        // Clear any existing test data
        DollarGeneralPersist.removeCache(key: testFavoritesKey)
        DollarGeneralPersist.removeCache(key: testHistoryKey)
    }

    override func tearDown() {
        DollarGeneralPersist.removeCache(key: testFavoritesKey)
        DollarGeneralPersist.removeCache(key: testHistoryKey)
        localStorageService = nil
        super.tearDown()
    }

    // MARK: - Favorites Tests

    func test_saveFavorite_success() throws {
        // Given
        let favorite = FavoriteCity(
            cityName: "London",
            country: "GB",
            coordinates: Coordinates(lon: -0.1257, lat: 51.5074)
        )

        // When
        try localStorageService.saveFavorite(favorite)

        // Then
        let favorites = try localStorageService.getFavorites()
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.cityName, "London")
        XCTAssertEqual(favorites.first?.country, "GB")
    }

    func test_saveFavorite_multiple() throws {
        // Given
        let london = FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))
        let paris = FavoriteCity(cityName: "Paris", country: "FR", coordinates: Coordinates(lon: 2.3522, lat: 48.8566))
        let tokyo = FavoriteCity(cityName: "Tokyo", country: "JP", coordinates: Coordinates(lon: 139.6503, lat: 35.6762))

        // When
        try localStorageService.saveFavorite(london)
        try localStorageService.saveFavorite(paris)
        try localStorageService.saveFavorite(tokyo)

        // Then
        let favorites = try localStorageService.getFavorites()
        XCTAssertEqual(favorites.count, 3)
        XCTAssertTrue(favorites.contains { $0.cityName == "London" })
        XCTAssertTrue(favorites.contains { $0.cityName == "Paris" })
        XCTAssertTrue(favorites.contains { $0.cityName == "Tokyo" })
    }

    func test_removeFavorite_success() throws {
        // Given
        let london = FavoriteCity(id: "london123", cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))
        let paris = FavoriteCity(cityName: "Paris", country: "FR", coordinates: Coordinates(lon: 2.3522, lat: 48.8566))
        try localStorageService.saveFavorite(london)
        try localStorageService.saveFavorite(paris)

        // When
        try localStorageService.removeFavorite(id: "london123")

        // Then
        let favorites = try localStorageService.getFavorites()
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.cityName, "Paris")
    }

    func test_getFavorites_empty() throws {
        // When
        let favorites = try localStorageService.getFavorites()

        // Then
        XCTAssertTrue(favorites.isEmpty)
    }

    func test_isFavorite_true() throws {
        // Given
        let london = FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))
        try localStorageService.saveFavorite(london)

        // When
        let isFavorite = try localStorageService.isFavorite(cityName: "London")

        // Then
        XCTAssertTrue(isFavorite)
    }

    func test_isFavorite_false() throws {
        // When
        let isFavorite = try localStorageService.isFavorite(cityName: "Paris")

        // Then
        XCTAssertFalse(isFavorite)
    }

    // MARK: - Search History Tests

    func test_addToHistory_success() throws {
        // Given
        let historyItem = SearchHistoryItem(cityName: "Berlin", country: "DE")

        // When
        try localStorageService.addToHistory(historyItem)

        // Then
        let history = try localStorageService.getHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.cityName, "Berlin")
        XCTAssertEqual(history.first?.country, "DE")
    }

    func test_addToHistory_multiple() throws {
        // Given
        let berlin = SearchHistoryItem(cityName: "Berlin", country: "DE")
        let madrid = SearchHistoryItem(cityName: "Madrid", country: "ES")
        let rome = SearchHistoryItem(cityName: "Rome", country: "IT")

        // When
        try localStorageService.addToHistory(berlin)
        try localStorageService.addToHistory(madrid)
        try localStorageService.addToHistory(rome)

        // Then
        let history = try localStorageService.getHistory()
        XCTAssertEqual(history.count, 3)
        // Most recent should be first
        XCTAssertEqual(history.first?.cityName, "Rome")
    }

    func test_addToHistory_limitTo20() throws {
        // Given - Add 25 items
        for i in 0..<25 {
            let item = SearchHistoryItem(cityName: "City\(i)", country: "XX")
            try localStorageService.addToHistory(item)
        }

        // When
        let history = try localStorageService.getHistory()

        // Then - Should only keep 20 most recent
        XCTAssertEqual(history.count, 20)
        XCTAssertEqual(history.first?.cityName, "City24")
        XCTAssertEqual(history.last?.cityName, "City5")
    }

    func test_clearHistory_success() throws {
        // Given
        let item1 = SearchHistoryItem(cityName: "City1", country: "XX")
        let item2 = SearchHistoryItem(cityName: "City2", country: "XX")
        try localStorageService.addToHistory(item1)
        try localStorageService.addToHistory(item2)

        // When
        try localStorageService.clearHistory()

        // Then
        let history = try localStorageService.getHistory()
        XCTAssertTrue(history.isEmpty)
    }

    func test_getHistory_empty() throws {
        // When
        let history = try localStorageService.getHistory()

        // Then
        XCTAssertTrue(history.isEmpty)
    }

    // MARK: - Duplicate Handling

    func test_saveFavorite_noDuplicates() throws {
        // Given
        let london1 = FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))
        let london2 = FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))

        // When
        try localStorageService.saveFavorite(london1)
        try localStorageService.saveFavorite(london2)

        // Then
        let favorites = try localStorageService.getFavorites()
        XCTAssertEqual(favorites.count, 1, "Should not add duplicate cities")
    }

    func test_addToHistory_allowDuplicates() throws {
        // Given - User can search same city multiple times
        let london1 = SearchHistoryItem(cityName: "London", country: "GB")
        let paris = SearchHistoryItem(cityName: "Paris", country: "FR")
        let london2 = SearchHistoryItem(cityName: "London", country: "GB")

        // When
        try localStorageService.addToHistory(london1)
        try localStorageService.addToHistory(paris)
        try localStorageService.addToHistory(london2)

        // Then
        let history = try localStorageService.getHistory()
        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history.first?.cityName, "London")
    }
}
*/
