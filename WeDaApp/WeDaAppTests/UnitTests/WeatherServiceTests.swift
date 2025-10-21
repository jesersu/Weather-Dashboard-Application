//
//  WeatherServiceTests.swift
//  WeDaAppTests
//
//  Created by Claude Code
//  Copyright © 2025 Dollar General. All rights reserved.
//

import XCTest
import NetworkingKit
@testable import WeDaApp

@MainActor
final class WeatherServiceTests: XCTestCase {

    var mockAPIClient: MockAPIClient!
    var weatherService: WeatherService!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        weatherService = WeatherService(apiClient: mockAPIClient)
    }

    override func tearDown() {
        mockAPIClient = nil
        weatherService = nil
        super.tearDown()
    }

    // MARK: - Current Weather Tests

    func test_fetchCurrentWeather_success() async throws {
        // Given
        let mockWeather = createMockWeatherData(cityName: "London")
        mockAPIClient.result = mockWeather

        // When
        let result = try await weatherService.fetchCurrentWeather(city: "London")

        // Then
        XCTAssertEqual(result.name, "London")
        XCTAssertEqual(result.main.temp, 15.0)
        XCTAssertEqual(result.weather.first?.description, "clear sky")
    }

    func test_fetchCurrentWeather_invalidCity() async {
        // Given
        mockAPIClient.error = APIError.invalidCity

        // When/Then
        do {
            _ = try await weatherService.fetchCurrentWeather(city: "InvalidCity")
            XCTFail("Should throw invalidCity error")
        } catch let error as APIError {
            XCTAssertEqual(error, .invalidCity)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func test_fetchCurrentWeather_noInternet() async {
        // Given
        mockAPIClient.error = APIError.noInternetConnection

        // When/Then
        do {
            _ = try await weatherService.fetchCurrentWeather(city: "London")
            XCTFail("Should throw noInternetConnection error")
        } catch let error as APIError {
            XCTAssertEqual(error, .noInternetConnection)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Forecast Tests

    func test_fetchForecast_success() async throws {
        // Given
        let mockForecast = createMockForecastResponse(cityName: "Paris")
        mockAPIClient.result = mockForecast

        // When
        let result = try await weatherService.fetchForecast(city: "Paris")

        // Then
        XCTAssertEqual(result.city.name, "Paris")
        XCTAssertEqual(result.list.count, 40) // 5 days * 8 (3-hour intervals)
        XCTAssertGreaterThan(result.list.first?.pop ?? 0, 0)
    }

    func test_fetchForecast_invalidCity() async {
        // Given
        mockAPIClient.error = APIError.invalidCity

        // When/Then
        do {
            _ = try await weatherService.fetchForecast(city: "InvalidCity")
            XCTFail("Should throw invalidCity error")
        } catch let error as APIError {
            XCTAssertEqual(error, .invalidCity)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Coordinates Tests

    func test_fetchWeatherByCoordinates_success() async throws {
        // Given
        let mockWeather = createMockWeatherData(cityName: "Tokyo")
        mockAPIClient.result = mockWeather

        // When
        let result = try await weatherService.fetchWeatherByCoordinates(lat: 35.6762, lon: 139.6503)

        // Then
        XCTAssertEqual(result.name, "Tokyo")
        XCTAssertEqual(result.coord.lat, 35.6762)
        XCTAssertEqual(result.coord.lon, 139.6503)
    }

    // MARK: - Helper Methods

    private func createMockWeatherData(cityName: String) -> WeatherData {
        WeatherData(
            id: 123,
            name: cityName,
            coord: Coordinates(lon: cityName == "Tokyo" ? 139.6503 : -0.1257, lat: cityName == "Tokyo" ? 35.6762 : 51.5074),
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

    private func createMockForecastResponse(cityName: String) -> ForecastResponse {
        let forecastItems = (0..<40).map { index in
            ForecastItem(
                dt: 1634567890 + (index * 10800), // 3-hour intervals
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
                name: cityName,
                coord: Coordinates(lon: 2.3522, lat: 48.8566),
                country: "FR",
                timezone: 7200,
                sunrise: 1634545000,
                sunset: 1634585000
            )
        )
    }
}
