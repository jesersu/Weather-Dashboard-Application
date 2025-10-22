//
//  MapTileOverlay.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import MapKit
import ArkanaKeys

/// OpenWeatherMap weather layer types
///
/// **Available Layers**:
/// - temperature: Temperature map (temp_new)
/// - precipitation: Precipitation intensity (precipitation_new)
/// - clouds: Cloud coverage (clouds_new)
///
/// **Tile Format**: https://tile.openweathermap.org/map/{layer}/{z}/{x}/{y}.png?appid={API_key}
public enum WeatherMapOverlay: String, CaseIterable {
    case temperature = "temp_new"
    case precipitation = "precipitation_new"
    case clouds = "clouds_new"

    public var displayName: String {
        switch self {
        case .temperature: return "Temperature"
        case .precipitation: return "Precipitation"
        case .clouds: return "Clouds"
        }
    }
}

/// Custom MKTileOverlay for OpenWeatherMap weather tiles
///
/// **Purpose**: Display weather data layers on map (temperature, precipitation, clouds)
///
/// **OpenWeatherMap Tiles API**:
/// - Base URL: https://tile.openweathermap.org/map
/// - Tile format: {layer}/{z}/{x}/{y}.png
/// - Requires API key
/// - Standard Web Mercator projection (EPSG:3857)
/// - Zoom levels: 0-18
///
/// **Performance**:
/// - Uses URLSession with caching
/// - Tiles cached in memory and disk
/// - Alpha blending for transparency
///
/// **Attribution**:
/// Must display "Weather data © OpenWeatherMap" on map
public final class OpenWeatherMapTileOverlay: MKTileOverlay {

    // MARK: - Properties

    private let layer: WeatherMapOverlay
    private let apiKey: String
    private let urlSession: URLSession

    // MARK: - Initialization

    public init(layer: WeatherMapOverlay) {
        self.layer = layer
        self.apiKey = ArkanaKeys.Global().openWeatherMapAPIKey

        // Configure URLSession with caching
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50 MB memory cache
            diskCapacity: 200 * 1024 * 1024,   // 200 MB disk cache
            diskPath: "weather_tiles"
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.urlSession = URLSession(configuration: config)

        // Call super with template URL
        super.init(urlTemplate: nil)

        // Set tile size and transparency
        self.canReplaceMapContent = false // Don't replace base map
        self.tileSize = CGSize(width: 256, height: 256)
    }

    // MARK: - Tile Loading

    public override func url(forTilePath path: MKTileOverlayPath) -> URL {
        // OpenWeatherMap tile URL format:
        // https://tile.openweathermap.org/map/{layer}/{z}/{x}/{y}.png?appid={API_key}
        let urlString = "https://tile.openweathermap.org/map/\(layer.rawValue)/\(path.z)/\(path.x)/\(path.y).png?appid=\(apiKey)"
        return URL(string: urlString)!
    }

    public override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let tileURL = url(forTilePath: path)

        let task = urlSession.dataTask(with: tileURL) { data, response, error in
            if let error = error {
                result(nil, error)
                return
            }

            guard let data = data else {
                result(nil, NSError(domain: "MapTileOverlay", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }

            // Return tile data
            result(data, nil)
        }

        task.resume()
    }
}
