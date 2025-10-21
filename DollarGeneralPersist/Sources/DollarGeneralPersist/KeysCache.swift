//
//  KeysCache.swift
//  DollarGeneralPersist
//
//  Created by Claude Code
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation

public struct KeysCache {
    // User preferences
    public static let selectedCity = "selectedCity"
    public static let favoriteCities = "favoriteCities"
    public static let searchHistory = "searchHistory"

    // Weather cache
    public static let cachedWeatherData = "cachedWeatherData"
    public static let cachedForecastData = "cachedForecastData"
    public static let lastWeatherUpdate = "lastWeatherUpdate"

    // Settings
    public static let temperatureUnit = "temperatureUnit"
    public static let isFirstLaunch = "isFirstLaunch"
}
