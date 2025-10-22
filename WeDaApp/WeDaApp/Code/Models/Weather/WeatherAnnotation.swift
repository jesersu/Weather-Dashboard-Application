//
//  WeatherAnnotation.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import MapKit

/// Custom map annotation for displaying weather information on map
///
/// **Purpose**: Show weather data for favorite cities on interactive map
///
/// **Properties**:
/// - coordinate: City location
/// - cityName: Name of the city
/// - temperature: Current temperature
/// - weatherDescription: Weather condition (e.g., "Cloudy", "Rain")
/// - weatherIcon: OpenWeatherMap icon code (e.g., "01d")
///
/// **Usage**:
/// ```swift
/// let annotation = WeatherAnnotation(
///     coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1257),
///     cityName: "London",
///     temperature: 15.0,
///     weatherDescription: "Partly cloudy",
///     weatherIcon: "02d"
/// )
/// mapView.addAnnotation(annotation)
/// ```
public final class WeatherAnnotation: NSObject, MKAnnotation {

    // MARK: - MKAnnotation Properties

    public let coordinate: CLLocationCoordinate2D
    public var title: String? { cityName }
    public var subtitle: String? { "\(Int(temperature))°C - \(weatherDescription)" }

    // MARK: - Weather Properties

    public let cityName: String
    public let temperature: Double
    public let weatherDescription: String
    public let weatherIcon: String

    // MARK: - Initialization

    public init(coordinate: CLLocationCoordinate2D,
                cityName: String,
                temperature: Double,
                weatherDescription: String,
                weatherIcon: String) {
        self.coordinate = coordinate
        self.cityName = cityName
        self.temperature = temperature
        self.weatherDescription = weatherDescription
        self.weatherIcon = weatherIcon
        super.init()
    }
}
