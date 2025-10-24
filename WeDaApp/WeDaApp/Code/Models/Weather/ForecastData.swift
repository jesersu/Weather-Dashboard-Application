//
//  ForecastData.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import DollarGeneralPersist

/// 5-day weather forecast response from OpenWeatherMap API
public struct ForecastResponse: Codable {
    public let list: [ForecastItem]
    public let city: City

    public init(list: [ForecastItem], city: City) {
        self.list = list
        self.city = city
    }
}

public struct ForecastItem: Codable, Identifiable, Hashable {
    public let dt: Int
    public let main: MainWeatherData
    public let weather: [Weather]
    public let clouds: Clouds
    public let wind: Wind
    public let visibility: Int
    public let pop: Double // Probability of precipitation
    public let dtTxt: String

    enum CodingKeys: String, CodingKey {
        case dt, main, weather, clouds, wind, visibility, pop
        case dtTxt = "dt_txt"
    }

    public var id: Int { dt }

    public init(dt: Int, main: MainWeatherData, weather: [Weather], clouds: Clouds, wind: Wind, visibility: Int, pop: Double, dtTxt: String) {
        self.dt = dt
        self.main = main
        self.weather = weather
        self.clouds = clouds
        self.wind = wind
        self.visibility = visibility
        self.pop = pop
        self.dtTxt = dtTxt
    }

    public var date: Date {
        Date(timeIntervalSince1970: TimeInterval(dt))
    }
}

public struct City: Codable, Hashable {
    public let id: Int
    public let name: String
    public let coord: Coordinates
    public let country: String
    public let timezone: Int
    public let sunrise: Int
    public let sunset: Int

    public init(id: Int, name: String, coord: Coordinates, country: String, timezone: Int, sunrise: Int, sunset: Int) {
        self.id = id
        self.name = name
        self.coord = coord
        self.country = country
        self.timezone = timezone
        self.sunrise = sunrise
        self.sunset = sunset
    }
}
