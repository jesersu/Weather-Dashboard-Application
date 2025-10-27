//
//  WeatherFlowIntegrationTests.swift
//  WeDaAppTests
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import XCTest
import CoreLocation
import DollarGeneralPersist
@testable import WeDaApp

@MainActor
final class WeatherFlowIntegrationTests: XCTestCase {
    var mockWeatherService: MockWeatherService!
    var mockStorageService: MockLocalStorageService!
    var mockLocationManager: MockLocationManager!

    override func setUp() {
        super.setUp()
        mockWeatherService = MockWeatherService()
        mockStorageService = MockLocalStorageService()
        mockLocationManager = MockLocationManager()

        // Clear any cached weather data to ensure clean test state
        DollarGeneralPersist.removeCache(key: KeysCache.cachedWeatherData)
        DollarGeneralPersist.removeCache(key: KeysCache.lastWeatherUpdate)
    }

    override func tearDown() {
        mockWeatherService = nil
        mockStorageService = nil
        mockLocationManager = nil
        super.tearDown()
    }

    // MARK: - Search to Details Flow

    func test_searchThenViewDetails() async throws {
        // Given - User searches for a city
        let searchViewModel = SearchViewModel(
            weatherService: mockWeatherService,
            storageService: mockStorageService,
            locationManager: mockLocationManager
        )

        let mockWeather = createMockWeatherData(cityName: "London")
        mockWeatherService.weatherResult = mockWeather

        // When - Search for London
        await searchViewModel.search(city: "London")

        // Then - Weather data is available
        XCTAssertNotNil(searchViewModel.weatherData)
        XCTAssertEqual(searchViewModel.weatherData?.name, "London")

        // And - History is updated
        XCTAssertTrue(mockStorageService.addToHistoryCalled)

        // When - User navigates to details
        let detailsViewModel = WeatherDetailsViewModel(
            city: "London",
            weatherService: mockWeatherService,
            storageService: mockStorageService
        )

        mockWeatherService.forecastResult = createMockForecastResponse()
        await detailsViewModel.fetchWeatherData()

        // Then - Both current weather and forecast are loaded
        XCTAssertNotNil(detailsViewModel.currentWeather)
        XCTAssertNotNil(detailsViewModel.forecast)
    }

    // MARK: - Favorite Flow

    func test_addToFavoritesThenViewFavorites() async throws {
        // Given - User views weather details
        let mockWeather = createMockWeatherData(cityName: "Paris")
        mockWeatherService.weatherResult = mockWeather
        mockWeatherService.forecastResult = createMockForecastResponse()

        let detailsViewModel = WeatherDetailsViewModel(
            city: "Paris",
            weatherService: mockWeatherService,
            storageService: mockStorageService
        )

        await detailsViewModel.fetchWeatherData()

        // When - User adds to favorites
        detailsViewModel.toggleFavorite()

        // Then - City is added to favorites
        XCTAssertTrue(detailsViewModel.isFavorite)
        XCTAssertTrue(mockStorageService.saveFavoriteCalled)

        // When - User views favorites list
        let favoritesViewModel = FavoritesViewModel(storageService: mockStorageService)

        // Then - Paris appears in favorites
        XCTAssertEqual(favoritesViewModel.favorites.count, 1)
        XCTAssertEqual(favoritesViewModel.favorites.first?.cityName, "Paris")
    }

    // MARK: - History Flow

    func test_multipleSearchesCreateHistory() async {
        // Given - User performs multiple searches
        let searchViewModel = SearchViewModel(
            weatherService: mockWeatherService,
            storageService: mockStorageService,
            locationManager: mockLocationManager
        )

        let cities = ["London", "Paris", "Tokyo"]

        // When - Search for multiple cities
        for city in cities {
            mockWeatherService.weatherResult = createMockWeatherData(cityName: city)
            await searchViewModel.search(city: city)
        }

        // Then - All searches are in history
        let historyViewModel = HistoryViewModel(storageService: mockStorageService)
        XCTAssertEqual(historyViewModel.history.count, 3)

        // And - Most recent search is first
        XCTAssertEqual(historyViewModel.history.first?.cityName, "Tokyo")
        XCTAssertEqual(historyViewModel.history.last?.cityName, "London")
    }

    // MARK: - Storage Persistence

    func test_favoritePersistenceAcrossViewModels() throws {
        // Given - Favorites are saved
        let favorite1 = FavoriteCity(cityName: "Berlin", country: "DE", coordinates: Coordinates(lon: 13.4050, lat: 52.5200))
        let favorite2 = FavoriteCity(cityName: "Madrid", country: "ES", coordinates: Coordinates(lon: -3.7038, lat: 40.4168))

        try mockStorageService.saveFavorite(favorite1)
        try mockStorageService.saveFavorite(favorite2)

        // When - Creating new ViewModel instances
        let favoritesViewModel1 = FavoritesViewModel(storageService: mockStorageService)

        // Then - Data persists
        XCTAssertEqual(favoritesViewModel1.favorites.count, 2)

        // When - Removing a favorite
        if let firstFavoriteId = favoritesViewModel1.favorites.first?.id {
            favoritesViewModel1.removeFavorite(id: firstFavoriteId)
        }

        // And - Creating another ViewModel instance
        let favoritesViewModel2 = FavoritesViewModel(storageService: mockStorageService)

        // Then - Changes persist
        XCTAssertEqual(favoritesViewModel2.favorites.count, 1)
    }

    // MARK: - Error Recovery Flow

    func test_errorRecoveryFlow() async {
        // Given - Search fails initially
        mockWeatherService.shouldThrowError = true
        mockWeatherService.errorToThrow = .noInternetConnection

        let searchViewModel = SearchViewModel(
            weatherService: mockWeatherService,
            storageService: mockStorageService,
            locationManager: mockLocationManager
        )

        // When - First search fails
        await searchViewModel.search(city: "London")

        // Then - Error is displayed
        XCTAssertEqual(searchViewModel.error, .noInternetConnection)
        XCTAssertNil(searchViewModel.weatherData)

        // When - Network recovers and user retries
        mockWeatherService.shouldThrowError = false
        mockWeatherService.weatherResult = createMockWeatherData(cityName: "London")

        searchViewModel.retry()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then - Data loads successfully (but history wasn't added during error)
        XCTAssertFalse(mockStorageService.addToHistoryCalled)
    }

    // MARK: - Helper Methods

    private func createMockWeatherData(cityName: String) -> WeatherData {
        WeatherData(
            id: 123,
            name: cityName,
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

    private func createMockForecastResponse() -> ForecastResponse {
        let forecastItems = (0..<40).map { index in
            ForecastItem(
                dt: 1634567890 + (index * 10800),
                main: MainWeatherData(
                    temp: Double(15 + index % 10),
                    feelsLike: Double(14 + index % 10),
                    tempMin: Double(12 + index % 10),
                    tempMax: Double(18 + index % 10),
                    pressure: 1013,
                    humidity: 72
                ),
                weather: [
                    Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")
                ],
                clouds: Clouds(all: 0),
                wind: Wind(speed: 3.5, deg: 180, gust: nil),
                visibility: 10000,
                pop: 0.2,
                dtTxt: "2021-10-18 12:00:00"
            )
        }

        return ForecastResponse(
            list: forecastItems,
            city: City(
                id: 456,
                name: "London",
                coord: Coordinates(lon: -0.1257, lat: 51.5074),
                country: "GB",
                timezone: 7200,
                sunrise: 1634545000,
                sunset: 1634585000
            )
        )
    }
}
