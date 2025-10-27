//
//  WeatherCacheModel.swift
//  DollarGeneralPersist
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import SwiftData

/// SwiftData model for weather cache persistence
@Model
public final class WeatherCacheModel {
    @Attribute(.unique)
    public var id: UUID
    public var cityName: String
    public var currentWeatherJSON: String
    public var forecastJSON: String?
    public var lastUpdated: Date

    public init(
        id: UUID = UUID(),
        cityName: String,
        currentWeatherJSON: String,
        forecastJSON: String?,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.cityName = cityName
        self.currentWeatherJSON = currentWeatherJSON
        self.forecastJSON = forecastJSON
        self.lastUpdated = lastUpdated
    }

    /// Convert to WeatherCache struct
    public func toWeatherCache() -> WeatherCache {
        return WeatherCache(
            id: id.uuidString,
            cityName: cityName,
            currentWeatherJSON: currentWeatherJSON,
            forecastJSON: forecastJSON,
            lastUpdated: lastUpdated
        )
    }

    /// Create from WeatherCache struct
    public static func from(_ cache: WeatherCache) -> WeatherCacheModel {
        return WeatherCacheModel(
            id: UUID(uuidString: cache.id) ?? UUID(),
            cityName: cache.cityName,
            currentWeatherJSON: cache.currentWeatherJSON,
            forecastJSON: cache.forecastJSON,
            lastUpdated: cache.lastUpdated
        )
    }
}
