//
//  SearchViewModel.swift
//  WeDaApp
//
//  Created by Claude Code
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import NetworkingKit
import DollarGeneralTemplateHelpers
import DollarGeneralPersist

@MainActor
final class SearchViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var weatherData: WeatherData?
    @Published private(set) var isLoading = false
    @Published var error: APIError?
    @Published var searchText = ""
    @Published var isShowingCachedData = false

    // MARK: - Dependencies

    private let weatherService: WeatherServiceProtocol
    private let storageService: LocalStorageServiceProtocol

    // MARK: - Initialization

    init(weatherService: WeatherServiceProtocol = WeatherService(),
         storageService: LocalStorageServiceProtocol = LocalStorageService()) {
        self.weatherService = weatherService
        self.storageService = storageService
        loadCachedWeather()
    }

    // MARK: - Public Methods

    /// Search for weather by city name
    func search(city: String) async {
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate input
        guard !trimmedCity.isEmpty else {
            LogDebug("Search city is empty")
            return
        }

        isLoading = true
        error = nil
        isShowingCachedData = false

        do {
            LogInfo("Searching weather for: \(trimmedCity)")
            let weather = try await weatherService.fetchCurrentWeather(city: trimmedCity)
            weatherData = weather

            // Cache weather data for offline use
            cacheWeather(weather)

            // Add to search history
            let historyItem = SearchHistoryItem(
                cityName: weather.name,
                country: weather.sys.country
            )
            try? storageService.addToHistory(historyItem)
            LogInfo("Successfully fetched weather for \(weather.name)")

        } catch let apiError as APIError {
            // If offline and we have cached data, show it
            if apiError == .noInternetConnection {
                loadCachedWeather()
                if weatherData != nil {
                    isShowingCachedData = true
                    LogInfo("Loaded cached weather data (offline mode)")
                } else {
                    error = apiError
                }
            } else {
                error = apiError
            }
            LogError("Failed to fetch weather: \(apiError.message)")
        } catch {
            self.error = .unknownError
            LogError("Unknown error: \(error)")
        }

        isLoading = false
    }

    /// Clear search results
    func clearSearch() {
        weatherData = nil
        error = nil
        searchText = ""
        isShowingCachedData = false
    }

    /// Retry last search
    func retry() {
        Task {
            await search(city: searchText)
        }
    }

    // MARK: - Private Methods

    /// Cache weather data locally
    private func cacheWeather(_ weather: WeatherData) {
        do {
            let data = try JSONEncoder().encode(weather)
            if let jsonString = String(data: data, encoding: .utf8) {
                DollarGeneralPersist.saveCache(key: KeysCache.cachedWeatherData, value: jsonString)
                DollarGeneralPersist.saveCache(key: KeysCache.lastWeatherUpdate, value: ISO8601DateFormatter().string(from: Date()))
                LogInfo("Cached weather data for offline use")
            }
        } catch {
            LogError("Failed to cache weather: \(error)")
        }
    }

    /// Load cached weather data
    private func loadCachedWeather() {
        let cachedData = DollarGeneralPersist.getCacheData(key: KeysCache.cachedWeatherData)
        guard !cachedData.isEmpty,
              let data = cachedData.data(using: .utf8) else {
            return
        }

        do {
            let weather = try JSONDecoder().decode(WeatherData.self, from: data)
            weatherData = weather
            LogInfo("Loaded cached weather data")
        } catch {
            LogError("Failed to decode cached weather: \(error)")
        }
    }
}
