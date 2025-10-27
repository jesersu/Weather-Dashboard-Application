//
//  WeatherMapViewModel.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import MapKit
import DollarGeneralTemplateHelpers
import ArkanaKeys

@MainActor
final class WeatherMapViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var region: MKCoordinateRegion
    @Published var annotations: [WeatherAnnotation] = []
    @Published var selectedOverlay: WeatherMapOverlay = .temperature
    @Published private(set) var isLoading = false

    // MARK: - Dependencies

    private let weatherService: WeatherServiceProtocol
    private let storageService: LocalStorageServiceProtocol
    private let apiKey: String

    // MARK: - Initialization

    init(weatherService: WeatherServiceProtocol = WeatherService(),
         storageService: LocalStorageServiceProtocol = LocalStorageService()) {
        self.weatherService = weatherService
        self.storageService = storageService
        self.apiKey = ArkanaKeys.Global().openWeatherMapAPIKey

        // Default region: world view
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 50.0, longitudeDelta: 50.0)
        )
    }

    // MARK: - Public Methods

    /// Load favorite cities and display them as annotations on the map
    func loadFavorites() async {
        isLoading = true

        do {
            LogInfo("🗺️ Loading favorites for map display")

            // Get all favorite cities
            let favorites = try storageService.getFavorites()

            guard !favorites.isEmpty else {
                LogInfo("ℹ️ No favorites to display on map")
                isLoading = false
                return
            }

            // Fetch weather for each favorite and create annotations
            var newAnnotations: [WeatherAnnotation] = []

            for favorite in favorites {
                do {
                    let weather = try await weatherService.fetchWeatherByCoordinates(
                        lat: favorite.coordinates.lat,
                        lon: favorite.coordinates.lon
                    )

                    let annotation = WeatherAnnotation(
                        coordinate: CLLocationCoordinate2D(
                            latitude: favorite.coordinates.lat,
                            longitude: favorite.coordinates.lon
                        ),
                        cityName: weather.name,
                        temperature: weather.main.temp,
                        weatherDescription: weather.weather.first?.description ?? "Unknown",
                        weatherIcon: weather.weather.first?.icon ?? "01d"
                    )

                    newAnnotations.append(annotation)
                    LogInfo("📍 Added annotation for \(weather.name)")
                } catch {
                    LogError("❌ Failed to fetch weather for \(favorite.cityName): \(error.localizedDescription)")
                }
            }

            // Update annotations on main thread
            annotations = newAnnotations

            // Center map on first favorite if available
            if let first = newAnnotations.first {
                centerOnAnnotation(first)
            }

            LogInfo("✅ Loaded \(newAnnotations.count) annotations")
        } catch {
            LogError("❌ Failed to load favorites: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Change the weather overlay layer
    ///
    /// - Parameter overlay: The new overlay to display
    func changeOverlay(to overlay: WeatherMapOverlay) {
        LogInfo("🌡️ Changing map overlay to: \(overlay.displayName)")
        selectedOverlay = overlay
    }

    /// Get tile URL for specific overlay and coordinates
    ///
    /// **Parameters**:
    /// - overlay: Weather overlay type
    /// - z: Zoom level
    /// - x: X coordinate
    /// - y: Y coordinate
    ///
    /// **Returns**: URL for OpenWeatherMap tile
    func getTileURL(for overlay: WeatherMapOverlay, z: Int, x: Int, y: Int) -> URL {
        let urlString = "https://tile.openweathermap.org/map/\(overlay.rawValue)/\(z)/\(x)/\(y).png?appid=\(apiKey)"
        guard let url = URL(string: urlString) else {
            fatalError("Invalid tile URL: \(urlString)")
        }
        return url
    }

    /// Center map on specific location
    ///
    /// - Parameter coordinate: Location to center on
    func centerOnLocation(_ coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 10.0, longitudeDelta: 10.0)
        )
        LogInfo("🎯 Centered map on location: \(coordinate.latitude), \(coordinate.longitude)")
    }

    /// Center map on annotation with zoom
    ///
    /// - Parameter annotation: Annotation to center on
    func centerOnAnnotation(_ annotation: WeatherAnnotation) {
        region = MKCoordinateRegion(
            center: annotation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        LogInfo("🎯 Centered map on \(annotation.cityName)")
    }
}
