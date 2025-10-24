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
        VStack(spacing: AppSpacing.lg) {
            // City name and country
            VStack(spacing: AppSpacing.xs) {
                Text(weatherData.name)
                    .font(AppTypography.largeTitle)

                if let country = weatherData.sys.country {
                    Text(country)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Weather icon and description
            // OPTIMIZATION: Using CachedAsyncImage instead of AsyncImage
            // Benefits: Reduces network calls, improves scroll performance, saves bandwidth
            if let weather = weatherData.weather.first {
                VStack(spacing: AppSpacing.md) {
                    CachedAsyncImage(url: weather.iconURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 120, height: 120)

                    Text(weather.description.capitalized)
                        .font(AppTypography.headline)
                        .foregroundColor(.secondary)
                }
            }

            // Temperature
            Text("\(Int(weatherData.main.temp))°C")
                .font(AppTypography.weatherTemp)

            // Feels like
            Text("\(L10n.Weather.feelsLike) \(Int(weatherData.main.feelsLike))°C")
                .font(AppTypography.body)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical, AppSpacing.sm)

            // Weather details grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.lg) {
                WeatherDetailItem(
                    icon: "thermometer.low",
                    label: L10n.Weather.tempMin,
                    value: "\(Int(weatherData.main.tempMin))°C"
                )

                WeatherDetailItem(
                    icon: "thermometer.high",
                    label: L10n.Weather.tempMax,
                    value: "\(Int(weatherData.main.tempMax))°C"
                )

                WeatherDetailItem(
                    icon: "humidity",
                    label: L10n.Weather.humidity,
                    value: "\(weatherData.main.humidity)%"
                )

                WeatherDetailItem(
                    icon: "gauge",
                    label: L10n.Weather.pressure,
                    value: "\(weatherData.main.pressure) hPa"
                )

                WeatherDetailItem(
                    icon: "wind",
                    label: L10n.Weather.windSpeed,
                    value: "\(String(format: "%.1f", weatherData.wind.speed)) m/s"
                )

                if let visibility = weatherData.visibility {
                    WeatherDetailItem(
                        icon: "eye",
                        label: L10n.Weather.visibility,
                        value: "\(visibility / 1000) km"
                    )
                }
            }
        }
        .padding(AppSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xLarge)
                .fill(AppColors.cardBackground)
        )
        .shadow(
            color: AppShadow.medium.color,
            radius: AppShadow.medium.radius,
            x: AppShadow.medium.x,
            y: AppShadow.medium.y
        )
    }
}

/// Individual weather detail item
private struct WeatherDetailItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(AppTypography.title3)
                .foregroundColor(AppColors.primary)

            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(AppTypography.bodyMedium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
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
