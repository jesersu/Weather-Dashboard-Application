//
//  String+Localization.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation

// MARK: - String Localization Extension

public extension String {
    /// Returns a localized string for the given key
    /// Usage: "search.title".localized
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    /// Returns a localized string with format arguments
    /// Usage: "greeting".localized(with: userName)
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Localization Keys

/// Strongly-typed localization keys to prevent typos and enable autocomplete
/// Usage: L10n.search.title instead of "search.title".localized
public enum L10n {
    // MARK: - Common
    public enum Common {
        public static let ok = "common.ok".localized
        public static let cancel = "common.cancel".localized
        public static let retry = "common.retry".localized
        public static let close = "common.close".localized
        public static let done = "common.done".localized
        public static let loading = "common.loading".localized
        public static let error = "common.error".localized
        public static let search = "common.search".localized
    }

    // MARK: - Tab Bar
    public enum Tab {
        public static let search = "tab.search".localized
        public static let favorites = "tab.favorites".localized
        public static let history = "tab.history".localized
        public static let map = "tab.map".localized
    }

    // MARK: - Search View
    public enum Search {
        public static let title = "search.title".localized
        public static let placeholder = "search.placeholder".localized
        public static let gettingLocation = "search.getting_location".localized
        public static let searchingWeather = "search.searching_weather".localized
        public static let cachedData = "search.cached_data".localized
        public static let emptyTitle = "search.empty_title".localized
        public static let emptySubtitle = "search.empty_subtitle".localized
        public static let viewDetails = "search.view_details".localized
    }

    // MARK: - Weather Details View
    public enum WeatherDetails {
        public static let title = "weather_details.title".localized
        public static let currentWeather = "weather_details.current_weather".localized
        public static let fiveDayForecast = "weather_details.five_day_forecast".localized
        public static let loading = "weather_details.loading".localized
        public static let hourlyForecast = "weather_details.hourly_forecast".localized
    }

    // MARK: - Favorites View
    public enum Favorites {
        public static let title = "favorites.title".localized
        public static let emptyTitle = "favorites.empty_title".localized
        public static let emptySubtitle = "favorites.empty_subtitle".localized
        public static let addedAt = "favorites.added_at".localized
        public static let remove = "favorites.remove".localized
        public static let addSuccess = "favorites.add_success".localized
        public static let removeSuccess = "favorites.remove_success".localized
        public static let alreadyExists = "favorites.already_exists".localized
    }

    // MARK: - History View
    public enum History {
        public static let title = "history.title".localized
        public static let emptyTitle = "history.empty_title".localized
        public static let emptySubtitle = "history.empty_subtitle".localized
        public static let searchedAt = "history.searched_at".localized
        public static let clearAll = "history.clear_all".localized
        public static let clearConfirm = "history.clear_confirm".localized
    }

    // MARK: - Map View
    public enum Map {
        public static let title = "map.title".localized
        public static let loading = "map.loading".localized
        public static let noFavorites = "map.no_favorites".localized
        public static let addFavorites = "map.add_favorites".localized

        public enum Overlay {
            public static let temperature = "map.overlay.temperature".localized
            public static let precipitation = "map.overlay.precipitation".localized
            public static let clouds = "map.overlay.clouds".localized
        }
    }

    // MARK: - Weather Card
    public enum Weather {
        public static let feelsLike = "weather.feels_like".localized
        public static let humidity = "weather.humidity".localized
        public static let windSpeed = "weather.wind_speed".localized
        public static let pressure = "weather.pressure".localized
        public static let visibility = "weather.visibility".localized
        public static let sunrise = "weather.sunrise".localized
        public static let sunset = "weather.sunset".localized
        public static let clouds = "weather.clouds".localized
        public static let tempMin = "weather.temp_min".localized
        public static let tempMax = "weather.temp_max".localized
    }

    // MARK: - Error Messages
    public enum Error {
        public static let noInternet = "error.no_internet".localized
        public static let noInternetDesc = "error.no_internet_desc".localized
        public static let invalidCity = "error.invalid_city".localized
        public static let invalidCityDesc = "error.invalid_city_desc".localized
        public static let serverError = "error.server_error".localized
        public static let serverErrorDesc = "error.server_error_desc".localized
        public static let unknown = "error.unknown".localized
        public static let unknownDesc = "error.unknown_desc".localized
        public static let locationDenied = "error.location_denied".localized
        public static let locationDeniedDesc = "error.location_denied_desc".localized
        public static let locationUnavailable = "error.location_unavailable".localized
        public static let locationUnavailableDesc = "error.location_unavailable_desc".localized
    }

    // MARK: - Loading Messages
    public enum Loading {
        public static let weather = "loading.weather".localized
        public static let forecast = "loading.forecast".localized
        public static let location = "loading.location".localized
        public static let map = "loading.map".localized
    }

    // MARK: - Units
    public enum Unit {
        public static let celsius = "unit.celsius".localized
        public static let fahrenheit = "unit.fahrenheit".localized
        public static let km = "unit.km".localized
        public static let meters = "unit.meters".localized
        public static let kmh = "unit.kmh".localized
        public static let mph = "unit.mph".localized
        public static let hpa = "unit.hpa".localized
        public static let percent = "unit.percent".localized
    }

    // MARK: - Time
    public enum Time {
        public static let today = "time.today".localized
        public static let tomorrow = "time.tomorrow".localized
        public static let yesterday = "time.yesterday".localized
        public static let now = "time.now".localized
    }

    // MARK: - Notifications
    public enum Notification {
        public static let dailySummary = "notification.daily_summary".localized
        public static let weatherAlert = "notification.weather_alert".localized
        public static let tempDrop = "notification.temp_drop".localized
        public static let severeWeather = "notification.severe_weather".localized
    }

    // MARK: - Background Tasks
    public enum Background {
        public static let fetchingWeather = "background.fetching_weather".localized
        public static let updateComplete = "background.update_complete".localized
        public static let updateFailed = "background.update_failed".localized
    }
}
