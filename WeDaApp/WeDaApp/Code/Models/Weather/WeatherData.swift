//
//  WeatherData.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation

/// Main weather data response from OpenWeatherMap API
public struct WeatherData: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let coord: Coordinates
    public let weather: [Weather]
    public let main: MainWeatherData
    public let wind: Wind
    public let clouds: Clouds
    public let dt: Int
    public let sys: Sys
    public let timezone: Int
    public let visibility: Int?

    public init(id: Int, name: String, coord: Coordinates, weather: [Weather], main: MainWeatherData, wind: Wind, clouds: Clouds, dt: Int, sys: Sys, timezone: Int, visibility: Int?) {
        self.id = id
        self.name = name
        self.coord = coord
        self.weather = weather
        self.main = main
        self.wind = wind
        self.clouds = clouds
        self.dt = dt
        self.sys = sys
        self.timezone = timezone
        self.visibility = visibility
    }
}

public struct Coordinates: Codable, Hashable {
    public let lon: Double
    public let lat: Double

    public init(lon: Double, lat: Double) {
        self.lon = lon
        self.lat = lat
    }
}

public struct Weather: Codable, Hashable {
    public let id: Int
    public let main: String
    public let description: String
    public let icon: String

    public init(id: Int, main: String, description: String, icon: String) {
        self.id = id
        self.main = main
        self.description = description
        self.icon = icon
    }

    public var iconURL: URL? {
        URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")
    }
}

public struct MainWeatherData: Codable, Hashable {
    public let temp: Double
    public let feelsLike: Double
    public let tempMin: Double
    public let tempMax: Double
    public let pressure: Int
    public let humidity: Int

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case humidity
    }

    public init(temp: Double, feelsLike: Double, tempMin: Double, tempMax: Double, pressure: Int, humidity: Int) {
        self.temp = temp
        self.feelsLike = feelsLike
        self.tempMin = tempMin
        self.tempMax = tempMax
        self.pressure = pressure
        self.humidity = humidity
    }
}

public struct Wind: Codable, Hashable {
    public let speed: Double
    public let deg: Int?
    public let gust: Double?

    public init(speed: Double, deg: Int?, gust: Double?) {
        self.speed = speed
        self.deg = deg
        self.gust = gust
    }
}

public struct Clouds: Codable, Hashable {
    public let all: Int

    public init(all: Int) {
        self.all = all
    }
}

public struct Sys: Codable, Hashable {
    public let country: String?
    public let sunrise: Int?
    public let sunset: Int?

    public init(country: String?, sunrise: Int?, sunset: Int?) {
        self.country = country
        self.sunrise = sunrise
        self.sunset = sunset
    }
}
