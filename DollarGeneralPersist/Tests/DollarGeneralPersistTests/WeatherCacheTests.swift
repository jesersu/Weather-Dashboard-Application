//
//  WeatherCacheTests.swift
//  DollarGeneralPersistTests
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import XCTest
@testable import DollarGeneralPersist

final class WeatherCacheTests: XCTestCase {
    // MARK: - Initialization Tests

    func test_init_setsPropertiesCorrectly() {
        // Given
        let cityName = "London"
        let weatherJSON = "{\"temp\":20}"
        let forecastJSON = "{\"list\":[]}"
        let date = Date()

        // When
        let cache = WeatherCache(
            cityName: cityName,
            currentWeatherJSON: weatherJSON,
            forecastJSON: forecastJSON,
            lastUpdated: date
        )

        // Then
        XCTAssertFalse(cache.id.isEmpty)
        XCTAssertEqual(cache.cityName, cityName)
        XCTAssertEqual(cache.currentWeatherJSON, weatherJSON)
        XCTAssertEqual(cache.forecastJSON, forecastJSON)
        XCTAssertEqual(cache.lastUpdated, date)
    }

    func test_init_withDefaultValues() {
        // When
        let cache = WeatherCache(
            cityName: "Paris",
            currentWeatherJSON: "{}",
            forecastJSON: nil
        )

        // Then
        XCTAssertFalse(cache.id.isEmpty)
        XCTAssertNotNil(cache.lastUpdated)
        XCTAssertNil(cache.forecastJSON)
    }

    // MARK: - Cache Validity Tests

    func test_isValid_returnsTrueForFreshCache() {
        // Given - Cache created 10 minutes ago
        let tenMinutesAgo = Date().addingTimeInterval(-10 * 60)
        let cache = WeatherCache(
            cityName: "London",
            currentWeatherJSON: "{}",
            forecastJSON: nil,
            lastUpdated: tenMinutesAgo
        )

        // When/Then - Default TTL is 30 minutes
        XCTAssertTrue(cache.isValid())
    }

    func test_isValid_returnsFalseForExpiredCache() {
        // Given - Cache created 40 minutes ago
        let fortyMinutesAgo = Date().addingTimeInterval(-40 * 60)
        let cache = WeatherCache(
            cityName: "London",
            currentWeatherJSON: "{}",
            forecastJSON: nil,
            lastUpdated: fortyMinutesAgo
        )

        // When/Then - Default TTL is 30 minutes
        XCTAssertFalse(cache.isValid())
    }

    func test_isValid_withCustomTTL() {
        // Given - Cache created 50 minutes ago
        let fiftyMinutesAgo = Date().addingTimeInterval(-50 * 60)
        let cache = WeatherCache(
            cityName: "London",
            currentWeatherJSON: "{}",
            forecastJSON: nil,
            lastUpdated: fiftyMinutesAgo
        )

        // When/Then - Custom TTL of 60 minutes
        XCTAssertTrue(cache.isValid(ttlMinutes: 60))
        XCTAssertFalse(cache.isValid(ttlMinutes: 40))
    }

    func test_isValid_returnsTrueForBrandNewCache() {
        // Given - Cache created now
        let cache = WeatherCache(
            cityName: "London",
            currentWeatherJSON: "{}",
            forecastJSON: nil,
            lastUpdated: Date()
        )

        // When/Then
        XCTAssertTrue(cache.isValid())
    }

    // MARK: - Age Calculation Tests

    func test_ageInMinutes_calculatesCorrectly() {
        // Given - Cache created 15 minutes ago
        let fifteenMinutesAgo = Date().addingTimeInterval(-15 * 60)
        let cache = WeatherCache(
            cityName: "London",
            currentWeatherJSON: "{}",
            forecastJSON: nil,
            lastUpdated: fifteenMinutesAgo
        )

        // When
        let age = cache.ageInMinutes

        // Then - Allow 1 minute tolerance for test execution time
        XCTAssertGreaterThanOrEqual(age, 14)
        XCTAssertLessThanOrEqual(age, 16)
    }

    func test_ageInMinutes_returnsZeroForNewCache() {
        // Given - Cache created now
        let cache = WeatherCache(
            cityName: "London",
            currentWeatherJSON: "{}",
            forecastJSON: nil,
            lastUpdated: Date()
        )

        // When
        let age = cache.ageInMinutes

        // Then
        XCTAssertEqual(age, 0)
    }

    func test_ageInMinutes_handlesOldCache() {
        // Given - Cache created 120 minutes ago
        let twoHoursAgo = Date().addingTimeInterval(-120 * 60)
        let cache = WeatherCache(
            cityName: "London",
            currentWeatherJSON: "{}",
            forecastJSON: nil,
            lastUpdated: twoHoursAgo
        )

        // When
        let age = cache.ageInMinutes

        // Then
        XCTAssertGreaterThanOrEqual(age, 119)
        XCTAssertLessThanOrEqual(age, 121)
    }

    // MARK: - Codable Tests

    func test_codable_encodesAndDecodesCorrectly() throws {
        // Given
        let original = WeatherCache(
            id: "test-id",
            cityName: "Tokyo",
            currentWeatherJSON: "{\"temp\":25}",
            forecastJSON: "{\"list\":[]}",
            lastUpdated: Date()
        )

        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Then - Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WeatherCache.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.cityName, original.cityName)
        XCTAssertEqual(decoded.currentWeatherJSON, original.currentWeatherJSON)
        XCTAssertEqual(decoded.forecastJSON, original.forecastJSON)
        XCTAssertEqual(decoded.lastUpdated.timeIntervalSince1970,
                       original.lastUpdated.timeIntervalSince1970,
                       accuracy: 0.001)
    }

    func test_codable_handlesNilForecast() throws {
        // Given
        let original = WeatherCache(
            cityName: "Berlin",
            currentWeatherJSON: "{\"temp\":15}",
            forecastJSON: nil
        )

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WeatherCache.self, from: data)

        // Then
        XCTAssertNil(decoded.forecastJSON)
        XCTAssertEqual(decoded.cityName, original.cityName)
    }
}
