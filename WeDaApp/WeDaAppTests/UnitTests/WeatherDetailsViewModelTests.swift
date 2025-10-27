//
//  WeatherDetailsViewModelTests.swift
//  WeDaAppTests
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import XCTest
import NetworkingKit
import DollarGeneralPersist
@testable import WeDaApp

@MainActor
final class WeatherDetailsViewModelTests: XCTestCase {
    var mockWeatherService: MockWeatherService!
    var mockStorageService: MockLocalStorageService!
    var viewModel: WeatherDetailsViewModel!

    override func setUp() {
        super.setUp()
        mockWeatherService = MockWeatherService()
        mockStorageService = MockLocalStorageService()
    }

    override func tearDown() {
        mockWeatherService = nil
        mockStorageService = nil
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Fetch Tests

    func test_fetchWeatherData_success() async {
        // Given
        let mockWeather = createMockWeatherData()
        let mockForecast = createMockForecastResponse()
        mockWeatherService.weatherResult = mockWeather
        mockWeatherService.forecastResult = mockForecast

        viewModel = WeatherDetailsViewModel(
            city: "London",
            weatherService: mockWeatherService,
            storageService: mockStorageService
        )

        // When
        await viewModel.fetchWeatherData()

        // Then
        XCTAssertNil(viewModel.error)
        XCTAssertNotNil(viewModel.currentWeather)
        XCTAssertNotNil(viewModel.forecast)
        XCTAssertEqual(viewModel.currentWeather?.name, "London")
        XCTAssertEqual(viewModel.forecast?.list.count, 40)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_fetchWeatherData_setsLoadingState() async {
        // Given
        mockWeatherService.delay = 0.1
        viewModel = WeatherDetailsViewModel(
            city: "London",
            weatherService: mockWeatherService,
            storageService: mockStorageService
        )

        // When
        Task {
            await viewModel.fetchWeatherData()
        }

        // Then
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        XCTAssertTrue(viewModel.isLoading)
    }

    func test_fetchWeatherData_error() async {
        // Given
        mockWeatherService.shouldThrowError = true
        mockWeatherService.errorToThrow = .invalidCity

        viewModel = WeatherDetailsViewModel(
            city: "Invalid",
            weatherService: mockWeatherService,
            storageService: mockStorageService
        )

        // When
        await viewModel.fetchWeatherData()

        // Then
        XCTAssertEqual(viewModel.error, .invalidCity)
        XCTAssertNil(viewModel.currentWeather)
        XCTAssertNil(viewModel.forecast)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Favorite Tests

    func test_toggleFavorite_addToFavorites() async {
        // Given
        let mockWeather = createMockWeatherData()
        mockWeatherService.weatherResult = mockWeather
        mockWeatherService.forecastResult = createMockForecastResponse()

        viewModel = WeatherDetailsViewModel(
            city: "London",
            weatherService: mockWeatherService,
            storageService: mockStorageService
        )
        await viewModel.fetchWeatherData()

        // When
        viewModel.toggleFavorite()

        // Then
        XCTAssertTrue(mockStorageService.saveFavoriteCalled)
        XCTAssertTrue(viewModel.isFavorite)
    }

    func test_toggleFavorite_removeFromFavorites() async throws {
        // Given
        let mockWeather = createMockWeatherData()
        mockWeatherService.weatherResult = mockWeather
        mockWeatherService.forecastResult = createMockForecastResponse()

        let favorite = FavoriteCity(
            id: "london123",
            cityName: "London",
            country: "GB",
            coordinates: Coordinates(lon: -0.1257, lat: 51.5074)
        )
        try mockStorageService.saveFavorite(favorite)

        viewModel = WeatherDetailsViewModel(
            city: "London",
            weatherService: mockWeatherService,
            storageService: mockStorageService
        )
        await viewModel.fetchWeatherData()
        viewModel.checkIfFavorite()

        // Verify it's a favorite before toggling
        XCTAssertTrue(viewModel.isFavorite)

        // When
        viewModel.toggleFavorite()

        // Then
        XCTAssertFalse(viewModel.isFavorite)
    }

    func test_checkIfFavorite_true() throws {
        // Given
        let favorite = FavoriteCity(
            cityName: "London",
            country: "GB",
            coordinates: Coordinates(lon: -0.1257, lat: 51.5074)
        )
        try mockStorageService.saveFavorite(favorite)

        viewModel = WeatherDetailsViewModel(
            city: "London",
            weatherService: mockWeatherService,
            storageService: mockStorageService
        )

        // When
        viewModel.checkIfFavorite()

        // Then
        XCTAssertTrue(viewModel.isFavorite)
    }

    func test_checkIfFavorite_false() {
        // Given
        viewModel = WeatherDetailsViewModel(
            city: "Paris",
            weatherService: mockWeatherService,
            storageService: mockStorageService
        )

        // When
        viewModel.checkIfFavorite()

        // Then
        XCTAssertFalse(viewModel.isFavorite)
    }

    // MARK: - Grouped Forecast Tests

    func test_groupedForecast_groupsByDay() async {
        // Given
        let mockWeather = createMockWeatherData()
        let mockForecast = createMockForecastResponse()
        mockWeatherService.weatherResult = mockWeather
        mockWeatherService.forecastResult = mockForecast

        viewModel = WeatherDetailsViewModel(
            city: "London",
            weatherService: mockWeatherService,
            storageService: mockStorageService
        )

        // When
        await viewModel.fetchWeatherData()
        let grouped = viewModel.groupedForecast

        // Then
        XCTAssertFalse(grouped.isEmpty)
        XCTAssertEqual(grouped.count, 5) // 5 days
        XCTAssertEqual(grouped.first?.value.count, 8) // 8 items per day (3-hour intervals)
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

    private func createMockForecastResponse() -> ForecastResponse {
        // Use a fixed start date at midnight to ensure consistent grouping across time zones
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1, hour: 0, minute: 0, second: 0))!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let forecastItems = (0..<40).map { index in
            let date = calendar.date(byAdding: .hour, value: index * 3, to: startDate)!
            let timestamp = Int(date.timeIntervalSince1970)

            return ForecastItem(
                dt: timestamp,
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
                dtTxt: dateFormatter.string(from: date)
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
