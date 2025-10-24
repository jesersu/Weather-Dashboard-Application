//
//  WeatherCard.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI

/// Reusable weather information display card
public struct WeatherCard: View {
    let weatherData: WeatherData

    public init(weatherData: WeatherData) {
        self.weatherData = weatherData
    }

    public var body: some View {
        VStack(spacing: 16) {
            // City name and country
            VStack(spacing: 4) {
                Text(weatherData.name)
                    .font(.title)
                    .fontWeight(.bold)

                if let country = weatherData.sys.country {
                    Text(country)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Weather icon and description
            // OPTIMIZATION: Using CachedAsyncImage instead of AsyncImage
            // Benefits: Reduces network calls, improves scroll performance, saves bandwidth
            if let weather = weatherData.weather.first {
                VStack(spacing: 8) {
                    CachedAsyncImage(url: weather.iconURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 100, height: 100)

                    Text(weather.description.capitalized)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }

            // Temperature
            Text("\(Int(weatherData.main.temp))°C")
                .font(.system(size: 64, weight: .thin))

            // Feels like
            Text("Feels like \(Int(weatherData.main.feelsLike))°C")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical, 8)

            // Weather details grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                WeatherDetailItem(
                    icon: "thermometer.low",
                    label: "Min",
                    value: "\(Int(weatherData.main.tempMin))°C"
                )

                WeatherDetailItem(
                    icon: "thermometer.high",
                    label: "Max",
                    value: "\(Int(weatherData.main.tempMax))°C"
                )

                WeatherDetailItem(
                    icon: "humidity",
                    label: "Humidity",
                    value: "\(weatherData.main.humidity)%"
                )

                WeatherDetailItem(
                    icon: "gauge",
                    label: "Pressure",
                    value: "\(weatherData.main.pressure) hPa"
                )

                WeatherDetailItem(
                    icon: "wind",
                    label: "Wind",
                    value: "\(String(format: "%.1f", weatherData.wind.speed)) m/s"
                )

                if let visibility = weatherData.visibility {
                    WeatherDetailItem(
                        icon: "eye",
                        label: "Visibility",
                        value: "\(visibility / 1000) km"
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

/// Individual weather detail item
private struct WeatherDetailItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ScrollView {
        WeatherCard(weatherData: WeatherData(
            id: 123,
            name: "London",
            coord: Coordinates(lon: -0.1257, lat: 51.5074),
            weather: [
                Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")
            ],
            main: MainWeatherData(
                temp: 15.5,
                feelsLike: 14.2,
                tempMin: 12.0,
                tempMax: 18.0,
                pressure: 1013,
                humidity: 72
            ),
            wind: Wind(speed: 3.5, deg: 180, gust: nil),
            clouds: Clouds(all: 0),
            dt: 1634567890,
            sys: Sys(country: "GB", sunrise: 1634545000, sunset: 1634585000),
            timezone: 0,
            visibility: 10000
        ))
        .padding()
    }
}
