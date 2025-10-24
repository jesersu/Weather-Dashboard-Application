//
//  SwiftDataModelsTests.swift
//  DollarGeneralPersistTests
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import XCTest
import SwiftData
@testable import DollarGeneralPersist

/// TDD Tests for SwiftData models
/// These tests define the expected behavior before implementation
@MainActor
final class SwiftDataModelsTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

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

        context = ModelContext(container)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    // MARK: - FavoriteCityModel Tests

    func test_favoriteCityModel_initialization() {
        // Given
        let id = UUID()
        let cityName = "London"
        let country = "GB"
        let latitude = 51.5074
        let longitude = -0.1257
        let addedAt = Date()

        // When
        let favorite = FavoriteCityModel(
            id: id,
            cityName: cityName,
            country: country,
            latitude: latitude,
            longitude: longitude,
            addedAt: addedAt
        )

        // Then
        XCTAssertEqual(favorite.id, id)
        XCTAssertEqual(favorite.cityName, cityName)
        XCTAssertEqual(favorite.country, country)
        XCTAssertEqual(favorite.latitude, latitude)
        XCTAssertEqual(favorite.longitude, longitude)
        XCTAssertEqual(favorite.addedAt, addedAt)
    }

    func test_favoriteCityModel_canBeSavedToContext() throws {
        // Given
        let favorite = FavoriteCityModel(
            cityName: "Paris",
            country: "FR",
            latitude: 48.8566,
            longitude: 2.3522
        )

        // When
        context.insert(favorite)
        try context.save()

        // Then
        let descriptor = FetchDescriptor<FavoriteCityModel>()
        let favorites = try context.fetch(descriptor)
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.cityName, "Paris")
    }

    func test_favoriteCityModel_canBeDeleted() throws {
        // Given
        let favorite = FavoriteCityModel(
            cityName: "Tokyo",
            country: "JP",
            latitude: 35.6762,
            longitude: 139.6503
        )
        context.insert(favorite)
        try context.save()

        // When
        context.delete(favorite)
        try context.save()

        // Then
        let descriptor = FetchDescriptor<FavoriteCityModel>()
        let favorites = try context.fetch(descriptor)
        XCTAssertEqual(favorites.count, 0)
    }

    func test_favoriteCityModel_displayName() {
        // Given / When
        let favoriteWithCountry = FavoriteCityModel(
            cityName: "Berlin",
            country: "DE",
            latitude: 52.5200,
            longitude: 13.4050
        )

        let favoriteWithoutCountry = FavoriteCityModel(
            cityName: "Sydney",
            country: nil,
            latitude: -33.8688,
            longitude: 151.2093
        )

        // Then
        XCTAssertEqual(favoriteWithCountry.displayName, "Berlin, DE")
        XCTAssertEqual(favoriteWithoutCountry.displayName, "Sydney")
    }

    func test_favoriteCityModel_conversionToStruct() {
        // Given
        let model = FavoriteCityModel(
            cityName: "Madrid",
            country: "ES",
            latitude: 40.4168,
            longitude: -3.7038
        )

        // When
        let favoriteCity = model.toFavoriteCity()

        // Then
        XCTAssertEqual(favoriteCity.id, model.id.uuidString)
        XCTAssertEqual(favoriteCity.cityName, "Madrid")
        XCTAssertEqual(favoriteCity.country, "ES")
        XCTAssertEqual(favoriteCity.coordinates.lat, 40.4168)
        XCTAssertEqual(favoriteCity.coordinates.lon, -3.7038)
    }

    func test_favoriteCityModel_conversionFromStruct() {
        // Given
        let coordinates = Coordinates(lon: -74.0060, lat: 40.7128)
        let favoriteCity = FavoriteCity(
            cityName: "New York",
            country: "US",
            coordinates: coordinates
        )

        // When
        let model = FavoriteCityModel.from(favoriteCity)

        // Then
        XCTAssertEqual(model.id.uuidString, favoriteCity.id)
        XCTAssertEqual(model.cityName, "New York")
        XCTAssertEqual(model.country, "US")
        XCTAssertEqual(model.latitude, 40.7128)
        XCTAssertEqual(model.longitude, -74.0060)
    }

    // MARK: - SearchHistoryModel Tests

    func test_searchHistoryModel_initialization() {
        // Given
        let id = UUID()
        let cityName = "Rome"
        let country = "IT"
        let searchedAt = Date()

        // When
        let history = SearchHistoryModel(
            id: id,
            cityName: cityName,
            country: country,
            searchedAt: searchedAt
        )

        // Then
        XCTAssertEqual(history.id, id)
        XCTAssertEqual(history.cityName, cityName)
        XCTAssertEqual(history.country, country)
        XCTAssertEqual(history.searchedAt, searchedAt)
    }

    func test_searchHistoryModel_canBeSavedToContext() throws {
        // Given
        let history = SearchHistoryModel(
            cityName: "Barcelona",
            country: "ES"
        )

        // When
        context.insert(history)
        try context.save()

        // Then
        let descriptor = FetchDescriptor<SearchHistoryModel>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.cityName, "Barcelona")
    }

    func test_searchHistoryModel_canBeDeleted() throws {
        // Given
        let history = SearchHistoryModel(
            cityName: "Amsterdam",
            country: "NL"
        )
        context.insert(history)
        try context.save()

        // When
        context.delete(history)
        try context.save()

        // Then
        let descriptor = FetchDescriptor<SearchHistoryModel>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 0)
    }

    func test_searchHistoryModel_displayName() {
        // Given / When
        let historyWithCountry = SearchHistoryModel(
            cityName: "Vienna",
            country: "AT"
        )

        let historyWithoutCountry = SearchHistoryModel(
            cityName: "Dubai",
            country: nil
        )

        // Then
        XCTAssertEqual(historyWithCountry.displayName, "Vienna, AT")
        XCTAssertEqual(historyWithoutCountry.displayName, "Dubai")
    }

    func test_searchHistoryModel_conversionToStruct() {
        // Given
        let model = SearchHistoryModel(
            cityName: "Prague",
            country: "CZ"
        )

        // When
        let historyItem = model.toSearchHistoryItem()

        // Then
        XCTAssertEqual(historyItem.id, model.id.uuidString)
        XCTAssertEqual(historyItem.cityName, "Prague")
        XCTAssertEqual(historyItem.country, "CZ")
    }

    func test_searchHistoryModel_conversionFromStruct() {
        // Given
        let historyItem = SearchHistoryItem(
            cityName: "Budapest",
            country: "HU"
        )

        // When
        let model = SearchHistoryModel.from(historyItem)

        // Then
        XCTAssertEqual(model.id.uuidString, historyItem.id)
        XCTAssertEqual(model.cityName, "Budapest")
        XCTAssertEqual(model.country, "HU")
    }

    // MARK: - Multiple Items Tests

    func test_multipleFavorites_canBeSavedAndFetched() throws {
        // Given
        let london = FavoriteCityModel(cityName: "London", country: "GB", latitude: 51.5074, longitude: -0.1257)
        let paris = FavoriteCityModel(cityName: "Paris", country: "FR", latitude: 48.8566, longitude: 2.3522)
        let berlin = FavoriteCityModel(cityName: "Berlin", country: "DE", latitude: 52.5200, longitude: 13.4050)

        // When
        context.insert(london)
        context.insert(paris)
        context.insert(berlin)
        try context.save()

        // Then
        let descriptor = FetchDescriptor<FavoriteCityModel>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        let favorites = try context.fetch(descriptor)
        XCTAssertEqual(favorites.count, 3)
    }

    func test_multipleHistoryItems_canBeSavedAndFetchedSorted() throws {
        // Given
        let rome = SearchHistoryModel(cityName: "Rome", country: "IT")
        Thread.sleep(forTimeInterval: 0.01) // Ensure different timestamps
        let madrid = SearchHistoryModel(cityName: "Madrid", country: "ES")
        Thread.sleep(forTimeInterval: 0.01)
        let lisbon = SearchHistoryModel(cityName: "Lisbon", country: "PT")

        // When
        context.insert(rome)
        context.insert(madrid)
        context.insert(lisbon)
        try context.save()

        // Then
        let descriptor = FetchDescriptor<SearchHistoryModel>(
            sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
        )
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items.first?.cityName, "Lisbon") // Most recent first
        XCTAssertEqual(items.last?.cityName, "Rome") // Oldest last
    }
}
