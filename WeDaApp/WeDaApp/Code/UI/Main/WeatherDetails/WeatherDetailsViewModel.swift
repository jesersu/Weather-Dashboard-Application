//
//  WeatherDetailsViewModel.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import NetworkingKit
import DollarGeneralTemplateHelpers

@MainActor
final class WeatherDetailsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var currentWeather: WeatherData?
    @Published private(set) var forecast: ForecastResponse?
    @Published private(set) var isLoading = false
    @Published var error: APIError?
    @Published var isFavorite = false

    // MARK: - Properties

    let city: String
    private let weatherService: WeatherServiceProtocol
    private let storageService: LocalStorageServiceProtocol

    // MARK: - Initialization

    init(city: String,
         weatherService: WeatherServiceProtocol = WeatherService(),
         storageService: LocalStorageServiceProtocol = LocalStorageService()) {
        self.city = city
        self.weatherService = weatherService
        self.storageService = storageService
        checkIfFavorite()
    }

    // MARK: - Public Methods

    /// Fetch current weather and 5-day forecast
    func fetchWeatherData() async {
        isLoading = true
        error = nil

        do {
            LogInfo("Fetching weather details for: \(city)")

            async let weatherTask = weatherService.fetchCurrentWeather(city: city)
            async let forecastTask = weatherService.fetchForecast(city: city)

            let (weather, forecastData) = try await (weatherTask, forecastTask)

            currentWeather = weather
            forecast = forecastData

            LogInfo("Successfully fetched weather details for \(city)")

        } catch let apiError as APIError {
            error = apiError
            LogError("Failed to fetch weather details: \(apiError.message)")
        } catch {
            self.error = .unknownError
            LogError("Unknown error: \(error)")
        }

        isLoading = false
    }

    /// Toggle favorite status
    func toggleFavorite() {
        guard let weather = currentWeather else { return }

        do {
            if isFavorite {
                // Remove from favorites
                let favorites = try storageService.getFavorites()
                if let favoriteToRemove = favorites.first(where: { $0.cityName.lowercased() == city.lowercased() }) {
                    try storageService.removeFavorite(id: favoriteToRemove.id)
                    isFavorite = false
                    LogInfo("Removed \(city) from favorites")
                }
            } else {
                // Add to favorites
                let favorite = FavoriteCity(
                    cityName: weather.name,
                    country: weather.sys.country,
                    coordinates: weather.coord
                )
                try storageService.saveFavorite(favorite)
                isFavorite = true
                LogInfo("Added \(city) to favorites")
            }
        } catch {
            LogError("Failed to toggle favorite: \(error)")
        }
    }

    /// Check if city is in favorites
    func checkIfFavorite() {
        do {
            isFavorite = try storageService.isFavorite(cityName: city)
        } catch {
            LogError("Failed to check favorite status: \(error)")
        }
    }

    /// Group forecast items by day
    var groupedForecast: [(key: String, value: [ForecastItem])] {
        guard let forecast = forecast else { return [] }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"

        let grouped = Dictionary(grouping: forecast.list) { item in
            dateFormatter.string(from: item.date)
        }

        return grouped.sorted { first, second in
            guard let firstDate = forecast.list.first(where: { dateFormatter.string(from: $0.date) == first.key })?.date,
                  let secondDate = forecast.list.first(where: { dateFormatter.string(from: $0.date) == second.key })?.date else {
                return false
            }
            return firstDate < secondDate
        }
    }

    /// Retry fetching data
    func retry() {
        Task {
            await fetchWeatherData()
        }
    }
}
