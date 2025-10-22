//
//  WeatherMapViewModelTests.swift
//  WeDaAppTests
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import XCTest
import MapKit
@testable import WeDaApp

@MainActor
final class WeatherMapViewModelTests: XCTestCase {

    var sut: WeatherMapViewModel!
    var mockWeatherService: MockWeatherService!
    var mockStorageService: MockLocalStorageService!

    override func setUp() async throws {
        try await super.setUp()
        mockWeatherService = MockWeatherService()
        mockStorageService = MockLocalStorageService()
        sut = WeatherMapViewModel(
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

    // MARK: - Initialization Tests

    func test_initialization_loadsDefaultRegion() {
        // Then
        XCTAssertNotNil(sut.region, "Should have default region")
        XCTAssertEqual(sut.region.span.latitudeDelta, 50.0, accuracy: 0.1, "Default zoom level should show world view")
    }

    func test_initialization_startsWithDefaultOverlay() {
        // Then
        XCTAssertEqual(sut.selectedOverlay, .temperature, "Should start with temperature overlay")
    }

    // MARK: - Favorites Loading Tests

    func test_loadFavorites_loadsAnnotations() async {
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
        await sut.loadFavorites()

        // Then
        XCTAssertEqual(sut.annotations.count, 2, "Should load annotations for all favorites")
    }

    func test_loadFavorites_fetchesWeatherForEach() async {
        // Given
        let favorite = FavoriteCity(cityName: "Tokyo", country: "JP", coordinates: Coordinates(lon: 139.6917, lat: 35.6895))
        mockStorageService.favorites = [favorite]

        let weatherData = WeatherData(
            id: 123,
            name: "Tokyo",
            coord: Coordinates(lon: 139.6917, lat: 35.6895),
            weather: [Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")],
            main: MainWeatherData(temp: 20.0, feelsLike: 19.0, tempMin: 18.0, tempMax: 22.0, pressure: 1013, humidity: 65),
            wind: Wind(speed: 2.5, deg: 90, gust: nil),
            clouds: Clouds(all: 0),
            dt: 1634567890,
            sys: Sys(country: "JP", sunrise: 1634545000, sunset: 1634585000),
            timezone: 0,
            visibility: 10000
        )
        mockWeatherService.weatherDataToReturn = weatherData

        // When
        await sut.loadFavorites()

        // Then
        XCTAssertEqual(mockWeatherService.fetchWeatherByCoordinatesCallCount, 1, "Should fetch weather for favorite")
    }

    func test_loadFavorites_setsLoadingState() async {
        // Given
        mockStorageService.favorites = [FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))]
        mockWeatherService.weatherDataToReturn = createMockWeatherData()
        mockWeatherService.delay = 0.1

        // When
        Task {
            await sut.loadFavorites()
        }

        // Then - Check loading immediately
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        XCTAssertTrue(sut.isLoading, "Should be loading")
    }

    // MARK: - Overlay Tests

    func test_changeOverlay_updatesSelectedOverlay() {
        // Given
        XCTAssertEqual(sut.selectedOverlay, .temperature)

        // When
        sut.changeOverlay(to: .precipitation)

        // Then
        XCTAssertEqual(sut.selectedOverlay, .precipitation, "Should change to precipitation overlay")
    }

    func test_overlayURL_generatesCorrectURL() {
        // Given
        let overlay = WeatherMapOverlay.temperature

        // When
        let url = sut.getTileURL(for: overlay, z: 5, x: 10, y: 15)

        // Then
        XCTAssertTrue(url.absoluteString.contains("temp_new"), "Temperature overlay should use temp_new layer")
        XCTAssertTrue(url.absoluteString.contains("/5/10/15.png"), "Should have correct tile coordinates")
    }

    // MARK: - Region Updates

    func test_centerOnLocation_updatesRegion() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1257)

        // When
        sut.centerOnLocation(coordinate)

        // Then
        XCTAssertEqual(sut.region.center.latitude, 51.5074, accuracy: 0.001, "Should center on London")
        XCTAssertEqual(sut.region.center.longitude, -0.1257, accuracy: 0.001, "Should center on London")
    }

    func test_centerOnAnnotation_zoomsToCity() {
        // Given
        let annotation = WeatherAnnotation(
            coordinate: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
            cityName: "Paris",
            temperature: 18.0,
            weatherDescription: "Cloudy",
            weatherIcon: "03d"
        )

        // When
        sut.centerOnAnnotation(annotation)

        // Then
        XCTAssertEqual(sut.region.center.latitude, 48.8566, accuracy: 0.001, "Should center on annotation")
        XCTAssertLessThan(sut.region.span.latitudeDelta, 1.0, "Should be zoomed in")
    }

    // MARK: - Error Handling

    func test_loadFavorites_handlesErrors() async {
        // Given
        mockStorageService.favorites = [FavoriteCity(cityName: "Invalid", country: "XX", coordinates: Coordinates(lon: 0, lat: 0))]
        mockWeatherService.shouldThrowError = true

        // When
        await sut.loadFavorites()

        // Then
        // Should not crash and should handle errors gracefully
        XCTAssertFalse(sut.isLoading, "Should stop loading after error")
    }

    // MARK: - Helper

    private func createMockWeatherData() -> WeatherData {
        return WeatherData(
            id: 123,
            name: "Test City",
            coord: Coordinates(lon: 0, lat: 0),
            weather: [Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")],
            main: MainWeatherData(temp: 15.0, feelsLike: 14.0, tempMin: 12.0, tempMax: 18.0, pressure: 1013, humidity: 72),
            wind: Wind(speed: 3.5, deg: 180, gust: nil),
            clouds: Clouds(all: 0),
            dt: 1634567890,
            sys: Sys(country: "GB", sunrise: 1634545000, sunset: 1634585000),
            timezone: 0,
            visibility: 10000
        )
    }
}
