//
//  WeatherCache.swift
//  DollarGeneralPersist
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation

/// Weather data cache entry
/// Stores current weather and forecast data with timestamp
public struct WeatherCache: Codable, Identifiable {
    public let id: String
    public let cityName: String
    public let currentWeatherJSON: String
    public let forecastJSON: String?
    public let lastUpdated: Date

    public init(
        id: String = UUID().uuidString,
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

    /// Check if cache is still valid (default: 30 minutes TTL)
    public func isValid(ttlMinutes: Int = 30) -> Bool {
        let expirationDate = lastUpdated.addingTimeInterval(TimeInterval(ttlMinutes * 60))
        return Date() < expirationDate
    }

    /// Age of cache in minutes
    public var ageInMinutes: Int {
        Int(Date().timeIntervalSince(lastUpdated) / 60)
    }
}
