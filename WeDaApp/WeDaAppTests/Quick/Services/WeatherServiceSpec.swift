//
//  WeatherServiceSpec.swift
//  WeDaAppTests
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Quick
import Nimble
import NetworkingKit
import DollarGeneralPersist
@testable import WeDaApp

@MainActor
final class WeatherServiceSpec: QuickSpec {

    override class func spec() {
        describe("WeatherService") {
            var mockAPIClient: MockAPIClient!
            var weatherService: WeatherService!

            beforeEach {
                mockAPIClient = MockAPIClient()
                weatherService = WeatherService(apiClient: mockAPIClient)
            }

            afterEach {
                mockAPIClient = nil
                weatherService = nil
            }

            // MARK: - Current Weather

            describe("fetching current weather") {
                context("when the API call succeeds") {
                    it("should return weather data for the specified city") {
                        waitUntil(timeout: .seconds(10)) { done in
                            // Given
                            let mockWeather = WeatherServiceSpec.createMockWeatherData(cityName: "London")
                            mockAPIClient.result = mockWeather

                            // When
                            Task {
                                do {
                                    let result = try await weatherService.fetchCurrentWeather(city: "London")

                                    // Then
                                    await MainActor.run {
                                        expect(result.name).to(equal("London"))
                                        expect(result.main.temp).to(equal(15.0))
                                        expect(result.weather.first?.description).to(equal("clear sky"))
                                        done()
                                    }
                                } catch {
                                    await MainActor.run {
                                        fail("Expected success but got error: \(error)")
                                        done()
                                    }
                                }
                            }
                        }
                    }
                }

                context("when the city is invalid") {
                    it("should throw an invalidCity error") {
                        waitUntil(timeout: .seconds(10)) { done in
                            // Given
                            mockAPIClient.error = APIError.invalidCity

                            // When/Then
                            Task {
                                do {
                                    _ = try await weatherService.fetchCurrentWeather(city: "InvalidCity")
                                    await MainActor.run {
                                        fail("Expected invalidCity error to be thrown")
                                        done()
                                    }
                                } catch let error as APIError {
                                    await MainActor.run {
                                        expect(error).to(equal(APIError.invalidCity))
                                        done()
                                    }
                                } catch {
                                    await MainActor.run {
                                        fail("Expected APIError.invalidCity but got: \(error)")
                                        done()
                                    }
                                }
                            }
                        }
                    }
                }

                context("when there is no internet connection") {
                    it("should throw a noInternetConnection error") {
                        waitUntil(timeout: .seconds(10)) { done in
                            // Given
                            mockAPIClient.error = APIError.noInternetConnection

                            // When/Then
                            Task {
                                do {
                                    _ = try await weatherService.fetchCurrentWeather(city: "London")
                                    await MainActor.run {
                                        fail("Expected noInternetConnection error to be thrown")
                                        done()
                                    }
                                } catch let error as APIError {
                                    await MainActor.run {
                                        expect(error).to(equal(APIError.noInternetConnection))
                                        done()
                                    }
                                } catch {
                                    await MainActor.run {
                                        fail("Expected APIError.noInternetConnection but got: \(error)")
                                        done()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // MARK: - Forecast

            describe("fetching weather forecast") {
                context("when the API call succeeds") {
                    it("should return 5-day forecast data with 40 items") {
                        waitUntil(timeout: .seconds(10)) { done in
                            // Given
                            let mockForecast = WeatherServiceSpec.createMockForecastResponse(cityName: "Paris")
                            mockAPIClient.result = mockForecast

                            // When
                            Task {
                                do {
                                    let result = try await weatherService.fetchForecast(city: "Paris")

                                    // Then
                                    await MainActor.run {
                                        expect(result.city.name).to(equal("Paris"))
                                        expect(result.list.count).to(equal(40)) // 5 days * 8 (3-hour intervals)
                                        expect(result.list.first?.pop).to(beGreaterThan(0))
                                        done()
                                    }
                                } catch {
                                    await MainActor.run {
                                        fail("Expected success but got error: \(error)")
                                        done()
                                    }
                                }
                            }
                        }
                    }
                }

                context("when the city is invalid") {
                    it("should throw an invalidCity error") {
                        waitUntil(timeout: .seconds(10)) { done in
                            // Given
                            mockAPIClient.error = APIError.invalidCity

                            // When/Then
                            Task {
                                do {
                                    _ = try await weatherService.fetchForecast(city: "InvalidCity")
                                    await MainActor.run {
                                        fail("Expected invalidCity error to be thrown")
                                        done()
                                    }
                                } catch let error as APIError {
                                    await MainActor.run {
                                        expect(error).to(equal(APIError.invalidCity))
                                        done()
                                    }
                                } catch {
                                    await MainActor.run {
                                        fail("Expected APIError.invalidCity but got: \(error)")
                                        done()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // MARK: - Weather by Coordinates

            describe("fetching weather by coordinates") {
                context("when provided with valid coordinates") {
                    it("should return weather data for that location") {
                        waitUntil(timeout: .seconds(10)) { done in
                            // Given
                            let mockWeather = WeatherServiceSpec.createMockWeatherData(cityName: "Tokyo")
                            mockAPIClient.result = mockWeather

                            // When
                            Task {
                                do {
                                    let result = try await weatherService.fetchWeatherByCoordinates(lat: 35.6762, lon: 139.6503)

                                    // Then
                                    await MainActor.run {
                                        expect(result.name).to(equal("Tokyo"))
                                        expect(result.coord.lat).to(equal(35.6762))
                                        expect(result.coord.lon).to(equal(139.6503))
                                        done()
                                    }
                                } catch {
                                    await MainActor.run {
                                        fail("Expected success but got error: \(error)")
                                        done()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    static func createMockWeatherData(cityName: String) -> WeatherData {
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

    static func createMockForecastResponse(cityName: String) -> ForecastResponse {
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
