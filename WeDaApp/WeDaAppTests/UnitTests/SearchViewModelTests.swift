//
//  SearchViewModelTests.swift
//  WeDaAppTests
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import XCTest
import CoreLocation
import NetworkingKit
import DollarGeneralPersist
@testable import WeDaApp

@MainActor
final class SearchViewModelTests: XCTestCase {

    var mockWeatherService: MockWeatherService!
    var mockStorageService: MockLocalStorageService!
    var mockLocationManager: MockLocationManager!
    var viewModel: SearchViewModel!

    override func setUp() {
        super.setUp()

        // Clear any cached weather data to ensure clean test state
        DollarGeneralPersist.removeCache(key: KeysCache.cachedWeatherData)
        DollarGeneralPersist.removeCache(key: KeysCache.lastWeatherUpdate)

        mockWeatherService = MockWeatherService()
        mockStorageService = MockLocalStorageService()
        mockLocationManager = MockLocationManager()
        viewModel = SearchViewModel(
            weatherService: mockWeatherService,
            storageService: mockStorageService,
            locationManager: mockLocationManager
        )
    }

    override func tearDown() {
        mockWeatherService = nil
        mockStorageService = nil
        mockLocationManager = nil
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Search Tests

    func test_search_success() async {
        // Given
        let mockWeather = createMockWeatherData()
        mockWeatherService.weatherResult = mockWeather

        // When
        await viewModel.search(city: "London")

        // Then
        XCTAssertNil(viewModel.error)
        XCTAssertNotNil(viewModel.weatherData)
        XCTAssertEqual(viewModel.weatherData?.name, "London")
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_search_setsLoadingState() async {
        // Given
        mockWeatherService.delay = 0.1

        // When
        Task {
            await viewModel.search(city: "London")
        }

        // Then - Check loading state immediately
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        XCTAssertTrue(viewModel.isLoading)
    }

    func test_search_invalidCity() async {
        // Given
        mockWeatherService.shouldThrowError = true
        mockWeatherService.errorToThrow = .invalidCity

        // When
        await viewModel.search(city: "InvalidCity")

        // Then
        XCTAssertEqual(viewModel.error, .invalidCity)
        XCTAssertNil(viewModel.weatherData)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_search_noInternet() async {
        // Given
        mockWeatherService.shouldThrowError = true
        mockWeatherService.errorToThrow = .noInternetConnection

        // When
        await viewModel.search(city: "London")

        // Then
        XCTAssertEqual(viewModel.error, .noInternetConnection)
        XCTAssertNil(viewModel.weatherData)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_search_emptyCity() async {
        // When
        await viewModel.search(city: "")

        // Then
        XCTAssertNil(viewModel.weatherData)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_search_whitespaceCity() async {
        // When
        await viewModel.search(city: "   ")

        // Then
        XCTAssertNil(viewModel.weatherData)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_search_addsToHistory() async {
        // Given
        let mockWeather = createMockWeatherData()
        mockWeatherService.weatherResult = mockWeather

        // When
        await viewModel.search(city: "London")

        // Then
        XCTAssertTrue(mockStorageService.addToHistoryCalled)
        XCTAssertEqual(mockStorageService.lastAddedHistoryItem?.cityName, "London")
    }

    func test_search_doesNotAddToHistoryOnError() async {
        // Given
        mockWeatherService.shouldThrowError = true
        mockWeatherService.errorToThrow = .invalidCity

        // When
        await viewModel.search(city: "InvalidCity")

        // Then
        XCTAssertFalse(mockStorageService.addToHistoryCalled)
    }

    // MARK: - Clear Tests

    func test_clearSearch() async {
        // Given
        let mockWeather = createMockWeatherData()
        mockWeatherService.weatherResult = mockWeather
        await viewModel.search(city: "London")

        // Verify we have data before clearing
        XCTAssertNotNil(viewModel.weatherData)

        // When
        viewModel.clearSearch()

        // Then
        XCTAssertNil(viewModel.weatherData)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.searchText, "")
    }

    // MARK: - Location Load State Persistence Tests

    func test_loadLocationWeatherIfNeeded_onlyLoadsOnce() async {
        // Given
        mockLocationManager.authorizationStatus = .authorizedWhenInUse
        mockLocationManager.currentLocation = CLLocation(latitude: 51.5074, longitude: -0.1257)
        mockWeatherService.weatherResult = createMockWeatherData()

        // When - Call multiple times (simulating navigation back to search view)
        await viewModel.loadLocationWeatherIfNeeded()
        let firstCallCount = mockWeatherService.fetchWeatherByCoordinatesCallCount

        await viewModel.loadLocationWeatherIfNeeded()
        let secondCallCount = mockWeatherService.fetchWeatherByCoordinatesCallCount

        await viewModel.loadLocationWeatherIfNeeded()
        let thirdCallCount = mockWeatherService.fetchWeatherByCoordinatesCallCount

        // Then - Should only fetch once
        XCTAssertEqual(firstCallCount, 1, "Should fetch location weather on first call")
        XCTAssertEqual(secondCallCount, 1, "Should NOT fetch again on second call")
        XCTAssertEqual(thirdCallCount, 1, "Should NOT fetch again on third call")
    }

    func test_loadLocationWeatherIfNeeded_preservesExistingWeatherData() async {
        // Given - User has searched for a city
        mockWeatherService.weatherResult = createMockWeatherData()
        await viewModel.search(city: "London")

        XCTAssertEqual(viewModel.weatherData?.name, "London")

        // Configure location to return different city
        mockLocationManager.authorizationStatus = .authorizedWhenInUse
        mockLocationManager.currentLocation = CLLocation(latitude: 40.7128, longitude: -74.0060)
        mockWeatherService.weatherDataToReturn = WeatherData(
            id: 456,
            name: "New York",
            coord: Coordinates(lon: -74.0060, lat: 40.7128),
            weather: [Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")],
            main: MainWeatherData(temp: 20.0, feelsLike: 19.0, tempMin: 18.0, tempMax: 22.0, pressure: 1015, humidity: 65),
            wind: Wind(speed: 4.0, deg: 200, gust: nil),
            clouds: Clouds(all: 0),
            dt: 1634567890,
            sys: Sys(country: "US", sunrise: 1634545000, sunset: 1634585000),
            timezone: 0,
            visibility: 10000
        )

        // When - Navigate back to search view (triggers loadLocationWeatherIfNeeded)
        await viewModel.loadLocationWeatherIfNeeded()

        // Then - Should preserve London, not load New York
        XCTAssertEqual(viewModel.weatherData?.name, "London", "Should preserve existing search result")
        XCTAssertNotEqual(viewModel.weatherData?.name, "New York", "Should NOT override with location weather")
        XCTAssertEqual(mockWeatherService.fetchWeatherByCoordinatesCallCount, 0, "Should not call location API")
    }

    func test_loadLocationWeatherIfNeeded_clearedStateAllowsNewSearch() async {
        // Given - Load location weather once
        mockLocationManager.authorizationStatus = .authorizedWhenInUse
        mockLocationManager.currentLocation = CLLocation(latitude: 51.5074, longitude: -0.1257)
        mockWeatherService.weatherResult = createMockWeatherData()

        await viewModel.loadLocationWeatherIfNeeded()
        XCTAssertEqual(mockWeatherService.fetchWeatherByCoordinatesCallCount, 1)
        XCTAssertNotNil(viewModel.weatherData)

        // When - User clears search
        viewModel.clearSearch()
        XCTAssertNil(viewModel.weatherData)

        // Then - User can manually search for a new city
        await viewModel.search(city: "Paris")
        XCTAssertEqual(mockWeatherService.fetchWeatherCallCount, 1, "Should allow manual search after clear")
        XCTAssertNotNil(viewModel.weatherData)
    }

    // MARK: - Helper Methods

    private func createMockWeatherData() -> WeatherData {
        WeatherData(
            id: 123,
            name: "London",
            coord: Coordinates(lon: -0.1257, lat: 51.5074),
            weather: [
                Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")
            ],
            main: MainWeatherData(
                temp: 15.0,
                feelsLike: 14.0,
                tempMin: 12.0,
                tempMax: 18.0,
                pressure: 1013,
                humidity: 72
            ),
            wind: Wind(speed: 3.5, deg: 180, gust: nil),
            clouds: Clouds(all: 0),
            dt: 1634567890,
            sys: Sys(country: "GB", sunrise: 1634545000, sunset: 1634585000),
            timezone: 0,
            visibility: 10000
        )
    }
}

// MARK: - Mock Services

class MockWeatherService: WeatherServiceProtocol {

    var weatherResult: WeatherData?
    var forecastResult: ForecastResponse?
    var citiesResult: [GeocodeResult] = []
    var shouldThrowError = false
    var errorToThrow: APIError = .unknownError
    var delay: TimeInterval = 0

    // Call tracking for background fetch tests
    var fetchWeatherCallCount = 0
    var fetchWeatherByCoordinatesCallCount = 0
    var weatherDataToReturn: WeatherData?

    func fetchCurrentWeather(city: String) async throws -> WeatherData {
        fetchWeatherCallCount += 1

        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        guard let result = weatherDataToReturn ?? weatherResult else {
            throw APIError.unknownError
        }

        return result
    }

    func fetchForecast(city: String) async throws -> ForecastResponse {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let result = forecastResult else {
            throw APIError.unknownError
        }

        return result
    }

    func fetchWeatherByCoordinates(lat: Double, lon: Double) async throws -> WeatherData {
        fetchWeatherByCoordinatesCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        guard let result = weatherDataToReturn ?? weatherResult else {
            throw APIError.unknownError
        }

        return result
    }

    func searchCities(query: String, limit: Int) async throws -> [GeocodeResult] {
        if shouldThrowError {
            throw errorToThrow
        }

        return citiesResult
    }
}

class MockLocalStorageService: LocalStorageServiceProtocol {
    var favorites: [FavoriteCity] = []
    var history: [SearchHistoryItem] = []
    var saveFavoriteCalled = false
    var addToHistoryCalled = false
    var lastAddedHistoryItem: SearchHistoryItem?

    func saveFavorite(_ favorite: FavoriteCity) throws {
        saveFavoriteCalled = true
        favorites.append(favorite)
    }

    func removeFavorite(id: String) throws {
        favorites.removeAll { $0.id == id }
    }

    func getFavorites() throws -> [FavoriteCity] {
        return favorites
    }

    func isFavorite(cityName: String) throws -> Bool {
        return favorites.contains { $0.cityName.lowercased() == cityName.lowercased() }
    }

    func addToHistory(_ item: SearchHistoryItem) throws {
        addToHistoryCalled = true
        lastAddedHistoryItem = item
        history.insert(item, at: 0)
    }

    func getHistory() throws -> [SearchHistoryItem] {
        return history
    }

    func removeHistoryItem(id: String) throws {
        history.removeAll { $0.id == id }
    }

    func clearHistory() throws {
        history.removeAll()
    }

    // MARK: - Weather Cache

    func saveWeatherCache(_ cache: WeatherCache) throws {
        // Mock implementation - no-op for tests
    }

    func getWeatherCache(cityName: String) throws -> WeatherCache? {
        // Mock implementation - return nil
        return nil
    }

    func clearExpiredCaches(olderThanMinutes: Int) throws {
        // Mock implementation - no-op for tests
    }

    func clearAllCaches() throws {
        // Mock implementation - no-op for tests
    }
}

class MockLocationManager: LocationManagerProtocol {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var locationError: LocationError?
    var shouldThrowError = false
    var errorToThrow: LocationError = .unavailable

    private var permissionRequested = false

    func requestLocationPermission() {
        // Mock implementation - doesn't actually request permission
    }

    func getCurrentLocation() async throws -> CLLocation {
        if shouldThrowError {
            throw errorToThrow
        }

        guard let location = currentLocation else {
            throw LocationError.unavailable
        }

        return location
    }

    func hasRequestedPermission() -> Bool {
        return permissionRequested
    }

    func markPermissionRequested() {
        permissionRequested = true
    }
}
