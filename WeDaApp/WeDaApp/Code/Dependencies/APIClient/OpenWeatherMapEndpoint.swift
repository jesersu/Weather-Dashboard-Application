//
//  OpenWeatherMapEndpoint.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import NetworkingKit
import ArkanaKeys

public enum OpenWeatherMapEndpoint {
    case currentWeather(city: String)
    case forecast(city: String)
    case currentWeatherByCoordinates(lat: Double, lon: Double)
    case geocoding(query: String, limit: Int)
}

extension OpenWeatherMapEndpoint: Endpoint {
    public typealias Response = WeatherData

    public var baseURL: URL {
        guard let url = URL(string: ArkanaKeys.Global().openWeatherMapBaseUrl) else {
            fatalError("Invalid base URL configuration")
        }
        return url
    }

    public var path: String {
        switch self {
        case .currentWeather, .currentWeatherByCoordinates:
            return "/data/2.5/weather"
        case .forecast:
            return "/data/2.5/forecast"
        case .geocoding:
            return "/geo/1.0/direct"
        }
    }

    public var query: [String: String] {
        var params: [String: String] = [
            "appid": ArkanaKeys.Global().openWeatherMapAPIKey
        ]

        switch self {
        case let .currentWeather(city), let .forecast(city):
            params["units"] = "metric"
            params["q"] = city
        case let .currentWeatherByCoordinates(lat, lon):
            params["units"] = "metric"
            params["lat"] = String(lat)
            params["lon"] = String(lon)
        case let .geocoding(query, limit):
            params["q"] = query
            params["limit"] = String(limit)
        }

        return params
    }

    public var method: APIRequest<Response>.Method {
        .get
    }

    public var headers: [String: String]? {
        [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
}

// Forecast endpoint needs its own response type
public extension OpenWeatherMapEndpoint {
    func buildForecast() -> APIRequest<ForecastResponse> {
        .init(
            path: path,
            query: query,
            method: .get,
            headers: headers
        )
    }

    // Geocoding endpoint returns an array of GeocodeResult
    public func buildGeocode() -> APIRequest<[GeocodeResult]> {
        .init(
            path: path,
            query: query,
            method: .get,
            headers: headers
        )
    }
}
