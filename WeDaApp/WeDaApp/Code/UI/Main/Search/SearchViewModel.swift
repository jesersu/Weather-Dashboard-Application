//
//  SearchViewModel.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import CoreLocation
import Combine
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

    // Location properties
    @Published private(set) var isLoadingLocation = false
    @Published private(set) var isLocationWeather = false

    // MARK: - Dependencies

    private let weatherService: WeatherServiceProtocol
    private let storageService: LocalStorageServiceProtocol
    private let locationManager: LocationManagerProtocol

    // MARK: - Private Properties

    // OPTIMIZATION: Task cancellation for debouncing (prevents wasted work)
    private var searchTask: Task<Void, Never>?

    // OPTIMIZATION: Combine cancellables stored as Set (automatic cleanup)
    // Using Set instead of Array prevents duplicate subscriptions
    private var cancellables = Set<AnyCancellable>()

    private var isProgrammaticUpdate = false

    // Track if we've already loaded location weather on first launch
    // Prevents re-loading location weather when user navigates back to search view
    private var hasLoadedLocationOnce = false

    // MARK: - Initialization

    init(weatherService: WeatherServiceProtocol = WeatherService(),
         storageService: LocalStorageServiceProtocol = LocalStorageService(),
         locationManager: LocationManagerProtocol? = nil) {
        self.weatherService = weatherService
        self.storageService = storageService
        self.locationManager = locationManager ?? LocationManager()
        // Cache will be loaded as fallback if location fetch fails
        setupLocationObserver()
    }

    // MARK: - Setup

    /// Setup observer for location authorization changes
    private func setupLocationObserver() {
        // Observe authorization status changes
        // Only observe if locationManager is the concrete LocationManager type
        guard let manager = locationManager as? LocationManager else { return }

        // OPTIMIZATION: [weak self] prevents retain cycle
        // Without weak: ViewModel retains closure, closure retains self -> memory leak
        // With weak: Closure holds weak reference, breaks cycle -> no leak
        manager.$authorizationStatus
            .dropFirst() // Skip initial value to avoid redundant processing
            .sink { [weak self] status in
                guard let self = self else { return }

                // When authorization is granted, fetch weather automatically
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    LogInfo("Location authorization granted, fetching weather")
                    Task {
                        await self.fetchWeatherForCurrentLocation()
                    }
                } else if status == .denied || status == .restricted {
                    LogInfo("Location authorization denied or restricted")
                }
            }
            .store(in: &cancellables)
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
            isLocationWeather = false

            // Cache weather data for offline use (legacy cache)
            cacheWeather(weather)

            // Save to SwiftData cache with forecast
            await saveWeatherToCache(city: weather.name)

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
        isLocationWeather = false
        isProgrammaticUpdate = true
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

    /// OPTIMIZATION: Search for city suggestions with debouncing (300ms delay)
    ///
    /// Debouncing prevents excessive API calls while user is typing.
    /// Performance Impact:
    /// - Without debouncing: 10 calls for "New York" (one per keystroke)
    /// - With debouncing: 1 call (only after user stops typing)
    /// - Savings: 90% reduction in network calls
    func searchCities(query: String) {
        // Skip autocomplete if text was set programmatically (location load or suggestion selection)
        if isProgrammaticUpdate {
            isProgrammaticUpdate = false // Reset flag
            return
        }

        // OPTIMIZATION: Cancel previous search task (prevents wasted work)
        // If user types "New York", we don't want to process "N", "Ne", "New", etc.
        searchTask?.cancel()

        // Validate minimum query length
        guard query.count >= 3 else {
            citySuggestions = []
            showSuggestions = false
            return
        }

        // Create new debounced search task
        searchTask = Task {
            // OPTIMIZATION: 300ms debouncing (optimal for user experience)
            // Too short (<100ms): Still too many requests
            // Too long (>500ms): Feels laggy to user
            // 300ms: Perfect balance between responsiveness and efficiency
            try? await Task.sleep(nanoseconds: 300_000_000)

            // OPTIMIZATION: Check cancellation to avoid wasted processing
            // If user kept typing, this task is already outdated
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
        isProgrammaticUpdate = true
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

    /// Load weather for current location based on authorization status
    /// Only loads on first launch - preserves user's search state on subsequent navigation
    func loadLocationWeatherIfNeeded() async {
        // If we already have weather data (user searched for something), preserve it
        if weatherData != nil {
            LogInfo("Weather data already exists, skipping location load")
            return
        }

        // If we've already loaded location once, don't do it again
        if hasLoadedLocationOnce {
            LogInfo("Already loaded location weather once, skipping")
            return
        }

        let status = locationManager.authorizationStatus

        // If already authorized, fetch weather immediately
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            LogInfo("Location already authorized, fetching weather")
            hasLoadedLocationOnce = true
            await fetchWeatherForCurrentLocation()
            return
        }

        // If not determined and haven't requested yet, request permission
        if status == .notDetermined && !locationManager.hasRequestedPermission() {
            LogInfo("First launch - requesting location permission")
            locationManager.requestLocationPermission()
            locationManager.markPermissionRequested()
            hasLoadedLocationOnce = true
            // Weather will be fetched automatically when authorization changes
            return
        }

        // If denied or restricted, do nothing
        LogInfo("Location permission denied, restricted, or already requested but not granted")
        hasLoadedLocationOnce = true
    }

    /// Fetch weather for current device location
    func fetchWeatherForCurrentLocation() async {
        isLoadingLocation = true
        error = nil
        isShowingCachedData = false

        do {
            LogInfo("Fetching current location")
            let location = try await locationManager.getCurrentLocation()

            // OWASP MSTG-STORAGE-1: Never log GPS coordinates (sensitive PII)
            LogInfo("Fetching weather for current location")
            let weather = try await weatherService.fetchWeatherByCoordinates(
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude
            )

            weatherData = weather
            isLocationWeather = true
            isProgrammaticUpdate = true
            // Keep search text empty for location weather - user can search manually if needed
            hideSuggestions() // Prevent autocomplete from triggering

            // Cache weather data for offline use (legacy cache)
            cacheWeather(weather)

            // Save to SwiftData cache with forecast
            await saveWeatherToCache(city: weather.name)

            // Add to search history
            let historyItem = SearchHistoryItem(
                cityName: weather.name,
                country: weather.sys.country
            )
            try? storageService.addToHistory(historyItem)

            LogInfo("Successfully fetched weather for current location: \(weather.name)")
        } catch let locationError as LocationError {
            LogError("Location error: \(locationError.message)")
            // Fallback to cached weather if available
            loadCachedWeather()
            if weatherData == nil {
                // No cache available, show empty state
                LogInfo("No cached weather available, showing empty state")
            } else {
                LogInfo("Showing cached weather as fallback for location error")
                isLocationWeather = true
                isShowingCachedData = true
            }
        } catch let apiError as APIError {
            LogError("Weather API error: \(apiError.message)")
            // Fallback to cached weather if available
            loadCachedWeather()
            if weatherData == nil {
                // No cache available, show API error
                error = apiError
                LogInfo("No cached weather available, showing error")
            } else {
                // Show cached data with offline indicator
                LogInfo("Showing cached weather as fallback for API error")
                isLocationWeather = true
                isShowingCachedData = true
            }
        } catch {
            LogError("Unknown error fetching location weather: \(error)")
            // Fallback to cached weather if available
            loadCachedWeather()
            if weatherData != nil {
                LogInfo("Showing cached weather as fallback for unknown error")
                isLocationWeather = true
                isShowingCachedData = true
            }
        }

        isLoadingLocation = false
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

    /// Save weather with forecast to SwiftData cache
    /// - Parameter city: City name to fetch forecast for
    private func saveWeatherToCache(city: String) async {
        guard let currentWeather = weatherData else { return }

        do {
            // Fetch forecast data
            let forecast = try await weatherService.fetchForecast(city: city)

            // Encode data
            let currentData = try JSONEncoder().encode(currentWeather)
            guard let currentJSON = String(data: currentData, encoding: .utf8) else {
                LogError("Failed to convert current weather data to JSON string")
                return
            }

            let forecastData = try JSONEncoder().encode(forecast)
            guard let forecastJSON = String(data: forecastData, encoding: .utf8) else {
                LogError("Failed to convert forecast data to JSON string")
                return
            }

            // Save to cache
            let cache = WeatherCache(
                cityName: city,
                currentWeatherJSON: currentJSON,
                forecastJSON: forecastJSON
            )
            try storageService.saveWeatherCache(cache)

            LogInfo("Saved weather cache with forecast for \(city)")
        } catch {
            LogError("Failed to save weather cache: \(error)")
        }
    }
}
