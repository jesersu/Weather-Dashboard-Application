//
//  WeatherService.swift
//  WeDaApp
//
//  Created by Claude Code
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import NetworkingKit

/// Protocol for weather service operations
public protocol WeatherServiceProtocol {
    func fetchCurrentWeather(city: String) async throws -> WeatherData
    func fetchForecast(city: String) async throws -> ForecastResponse
    func fetchWeatherByCoordinates(lat: Double, lon: Double) async throws -> WeatherData
}

/// Service for fetching weather data from OpenWeatherMap API
public struct WeatherService: WeatherServiceProtocol {

    private let apiClient: APIClient

    public init(apiClient: APIClient = OpenWeatherMapAPIClient()) {
        self.apiClient = apiClient
    }

    /// Fetch current weather for a city
    /// - Parameter city: City name
    /// - Returns: Current weather data
    /// - Throws: APIError if request fails
    public func fetchCurrentWeather(city: String) async throws -> WeatherData {
        let endpoint = OpenWeatherMapEndpoint.currentWeather(city: city)
        let request = endpoint.build()
        return try await apiClient.request(request)
    }

    /// Fetch 5-day weather forecast for a city
    /// - Parameter city: City name
    /// - Returns: Forecast response with 40 items (3-hour intervals)
    /// - Throws: APIError if request fails
    public func fetchForecast(city: String) async throws -> ForecastResponse {
        let endpoint = OpenWeatherMapEndpoint.forecast(city: city)
        let request = endpoint.buildForecast()
        return try await apiClient.request(request)
    }

    /// Fetch current weather by geographic coordinates
    /// - Parameters:
    ///   - lat: Latitude
    ///   - lon: Longitude
    /// - Returns: Current weather data
    /// - Throws: APIError if request fails
    public func fetchWeatherByCoordinates(lat: Double, lon: Double) async throws -> WeatherData {
        let endpoint = OpenWeatherMapEndpoint.currentWeatherByCoordinates(lat: lat, lon: lon)
        let request = endpoint.build()
        return try await apiClient.request(request)
    }
}
