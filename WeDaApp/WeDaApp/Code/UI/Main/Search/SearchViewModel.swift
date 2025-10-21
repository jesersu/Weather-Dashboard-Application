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

    // Autocomplete properties
    @Published private(set) var citySuggestions: [GeocodeResult] = []
    @Published private(set) var showSuggestions = false

    // MARK: - Dependencies

    private let weatherService: WeatherServiceProtocol
    private let storageService: LocalStorageServiceProtocol

    // MARK: - Private Properties

    private var searchTask: Task<Void, Never>?

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
        hideSuggestions()
    }

    /// Retry last search
    func retry() {
        Task {
            await search(city: searchText)
        }
    }

    /// Search for city suggestions with debouncing (300ms delay)
    func searchCities(query: String) {
        // Cancel previous search task
        searchTask?.cancel()

        // Validate minimum query length
        guard query.count >= 3 else {
            citySuggestions = []
            showSuggestions = false
            return
        }

        // Create new debounced search task
        searchTask = Task {
            // Wait 300ms before searching
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Check if task was cancelled during sleep
            guard !Task.isCancelled else { return }

            do {
                LogInfo("Searching cities for: \(query)")
                let results = try await weatherService.searchCities(query: query, limit: 5)
                citySuggestions = results
                showSuggestions = !results.isEmpty
                LogInfo("Found \(results.count) city suggestions")
            } catch {
                LogError("Failed to fetch city suggestions: \(error)")
                // Silently fail - don't interrupt user's typing experience
                citySuggestions = []
                showSuggestions = false
            }
        }
    }

    /// Handle selection of a city suggestion
    func selectSuggestion(_ result: GeocodeResult) {
        LogInfo("Selected city: \(result.displayName)")

        // Update search text and hide suggestions
        searchText = result.name
        hideSuggestions()

        // Auto-load weather for selected city
        Task {
            await search(city: result.name)
        }
    }

    /// Hide suggestions dropdown
    func hideSuggestions() {
        showSuggestions = false
        citySuggestions = []
        searchTask?.cancel()
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
