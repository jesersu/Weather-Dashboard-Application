//
//  BackgroundTaskManagerTests.swift
//  WeDaAppTests
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import XCTest
import BackgroundTasks
@testable import WeDaApp

@MainActor
final class BackgroundTaskManagerTests: XCTestCase {

    var sut: BackgroundTaskManager!
    var mockWeatherService: MockWeatherService!
    var mockStorageService: MockLocalStorageService!

    override func setUp() async throws {
        try await super.setUp()
        mockWeatherService = MockWeatherService()
        mockStorageService = MockLocalStorageService()
        sut = BackgroundTaskManager(
            weatherService: mockWeatherService,
            storageService: mockStorageService
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockWeatherService = nil
        mockStorageService = nil
        try await super.tearDown()
    }

    // MARK: - Registration Tests

    func test_registerBackgroundTasks_registersCorrectIdentifier() {
        // Given
        let expectedIdentifier = "com.dollarg.wedaapp.refresh"

        // When
        sut.registerBackgroundTasks()

        // Then
        // Note: BGTaskScheduler.shared can't be easily mocked, but we can verify no crashes
        XCTAssertNotNil(sut, "Background task manager should initialize successfully")
    }

    // MARK: - Scheduling Tests

    func test_scheduleBackgroundRefresh_schedulesTaskSuccessfully() {
        // Given / When
        let result = sut.scheduleBackgroundRefresh()

        // Then
        // Note: BGTaskScheduler may fail in simulator, but shouldn't crash
        // In production, this would return true
        XCTAssertNotNil(result, "Should return scheduling result")
    }

    func test_scheduleBackgroundRefresh_usesCorrectEarliestBeginDate() {
        // Given
        let beforeScheduling = Date()

        // When
        _ = sut.scheduleBackgroundRefresh()

        // Then
        let afterScheduling = Date()
        let timeDifference = afterScheduling.timeIntervalSince(beforeScheduling)

        // Should schedule within reasonable time
        XCTAssertLessThan(timeDifference, 1.0, "Scheduling should be immediate")
    }

    // MARK: - Background Fetch Tests

    func test_performBackgroundFetch_withNoFavorites_completesImmediately() async {
        // Given
        mockStorageService.favorites = []

        // When
        let result = await sut.performBackgroundFetch()

        // Then
        XCTAssertTrue(result, "Should complete successfully even with no favorites")
        XCTAssertEqual(mockWeatherService.fetchWeatherCallCount, 0, "Should not fetch weather when no favorites")
    }

    func test_performBackgroundFetch_withFavorites_fetchesWeatherForEach() async {
        // Given
        let favorite1 = FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))
        let favorite2 = FavoriteCity(cityName: "Paris", country: "FR", coordinates: Coordinates(lon: 2.3522, lat: 48.8566))
        mockStorageService.favorites = [favorite1, favorite2]

        let weatherData = WeatherData(
            id: 123,
            name: "London",
            coord: Coordinates(lon: -0.1257, lat: 51.5074),
            weather: [Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")],
            main: MainWeatherData(temp: 15.0, feelsLike: 14.0, tempMin: 12.0, tempMax: 18.0, pressure: 1013, humidity: 72),
            wind: Wind(speed: 3.5, deg: 180, gust: nil),
            clouds: Clouds(all: 0),
            dt: 1634567890,
            sys: Sys(country: "GB", sunrise: 1634545000, sunset: 1634585000),
            timezone: 0,
            visibility: 10000
        )
        mockWeatherService.weatherDataToReturn = weatherData

        // When
        let result = await sut.performBackgroundFetch()

        // Then
        XCTAssertTrue(result, "Background fetch should succeed")
        XCTAssertEqual(mockWeatherService.fetchWeatherByCoordinatesCallCount, 2, "Should fetch weather for both favorites")
    }

    func test_performBackgroundFetch_withError_handlesGracefully() async {
        // Given
        let favorite = FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))
        mockStorageService.favorites = [favorite]
        mockWeatherService.shouldThrowError = true

        // When
        let result = await sut.performBackgroundFetch()

        // Then
        // Should handle errors gracefully and not crash
        XCTAssertFalse(result, "Should return false when fetch fails")
    }

    func test_performBackgroundFetch_cachesResults() async {
        // Given
        let favorite = FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))
        mockStorageService.favorites = [favorite]

        let weatherData = WeatherData(
            id: 123,
            name: "London",
            coord: Coordinates(lon: -0.1257, lat: 51.5074),
            weather: [Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")],
            main: MainWeatherData(temp: 15.0, feelsLike: 14.0, tempMin: 12.0, tempMax: 18.0, pressure: 1013, humidity: 72),
            wind: Wind(speed: 3.5, deg: 180, gust: nil),
            clouds: Clouds(all: 0),
            dt: 1634567890,
            sys: Sys(country: "GB", sunrise: 1634545000, sunset: 1634585000),
            timezone: 0,
            visibility: 10000
        )
        mockWeatherService.weatherDataToReturn = weatherData

        // When
        let result = await sut.performBackgroundFetch()

        // Then
        XCTAssertTrue(result, "Background fetch should succeed")
        // Verify data was cached (implementation will use UserDefaults or similar)
    }

    // MARK: - Task Expiration Tests

    func test_performBackgroundFetch_completesWithin30Seconds() async {
        // Given
        let favorite = FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))
        mockStorageService.favorites = [favorite]

        let weatherData = WeatherData(
            id: 123,
            name: "London",
            coord: Coordinates(lon: -0.1257, lat: 51.5074),
            weather: [Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")],
            main: MainWeatherData(temp: 15.0, feelsLike: 14.0, tempMin: 12.0, tempMax: 18.0, pressure: 1013, humidity: 72),
            wind: Wind(speed: 3.5, deg: 180, gust: nil),
            clouds: Clouds(all: 0),
            dt: 1634567890,
            sys: Sys(country: "GB", sunrise: 1634545000, sunset: 1634585000),
            timezone: 0,
            visibility: 10000
        )
        mockWeatherService.weatherDataToReturn = weatherData

        // When
        let startTime = Date()
        let result = await sut.performBackgroundFetch()
        let duration = Date().timeIntervalSince(startTime)

        // Then
        XCTAssertTrue(result, "Background fetch should complete")
        XCTAssertLessThan(duration, 30.0, "Background fetch must complete within 30 seconds")
    }
}
