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

@MainActor
final class SearchViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var weatherData: WeatherData?
    @Published private(set) var isLoading = false
    @Published var error: APIError?
    @Published var searchText = ""

    // MARK: - Dependencies

    private let weatherService: WeatherServiceProtocol
    private let storageService: LocalStorageServiceProtocol

    // MARK: - Initialization

    init(weatherService: WeatherServiceProtocol = WeatherService(),
         storageService: LocalStorageServiceProtocol = LocalStorageService()) {
        self.weatherService = weatherService
        self.storageService = storageService
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
        weatherData = nil

        do {
            LogInfo("Searching weather for: \(trimmedCity)")
            let weather = try await weatherService.fetchCurrentWeather(city: trimmedCity)
            weatherData = weather

            // Add to search history
            let historyItem = SearchHistoryItem(
                cityName: weather.name,
                country: weather.sys.country
            )
            try? storageService.addToHistory(historyItem)
            LogInfo("Successfully fetched weather for \(weather.name)")

        } catch let apiError as APIError {
            error = apiError
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
    }

    /// Retry last search
    func retry() {
        Task {
            await search(city: searchText)
        }
    }
}
