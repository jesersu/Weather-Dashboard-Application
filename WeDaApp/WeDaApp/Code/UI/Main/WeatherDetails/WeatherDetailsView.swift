//
//  WeatherDetailsView.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI
import DollarGeneralTemplateHelpers

struct WeatherDetailsView: View {
    @StateObject private var viewModel: WeatherDetailsViewModel

    init(city: String) {
        _viewModel = StateObject(wrappedValue: WeatherDetailsViewModel(city: city))
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                LoadingView(message: "Loading forecast...")
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    viewModel.retry()
                }
            } else if let currentWeather = viewModel.currentWeather {
                ScrollView {
                    VStack(spacing: 24) {
                        // Current Weather
                        WeatherCard(weatherData: currentWeather)
                            .padding()
                            .accessibilityIdentifier(UITestIDs.WeatherDetailsView.currentWeather.rawValue)

                        // 5-Day Forecast
                        if viewModel.forecast != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("5-Day Forecast")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)

                                ForEach(viewModel.groupedForecast, id: \.key) { day, items in
                                    ForecastDayView(day: day, items: items)
                                }
                            }
                            .accessibilityIdentifier(UITestIDs.WeatherDetailsView.forecast.rawValue)
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
        .navigationTitle(viewModel.city)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .customNavigationBar()
        .toolbar {
            // Custom back button
            ToolbarItem(placement: .navigationBarLeading) {
                CustomBackButton()
            }

            // Favorite button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleFavorite()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 36, height: 36)

                        Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(viewModel.isFavorite ? .yellow : .white)
                    }
                }
                .accessibilityIdentifier(UITestIDs.WeatherDetailsView.favoriteButton.rawValue)
                .accessibilityLabel(viewModel.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .task {
            if viewModel.currentWeather == nil {
                await viewModel.fetchWeatherData()
            }
        }
        .accessibilityIdentifier(UITestIDs.WeatherDetailsView.parent.rawValue)
    }
}

// MARK: - Forecast Day View

private struct ForecastDayView: View {
    let day: String
    let items: [ForecastItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(day)
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        ForecastItemCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Forecast Item Card

private struct ForecastItemCard: View {
    let item: ForecastItem

    var body: some View {
        VStack(spacing: 8) {
            Text(timeString)
                .font(.caption)
                .fontWeight(.medium)

            if let weather = item.weather.first {
                AsyncImage(url: weather.iconURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 40, height: 40)

                Text(weather.main)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text("\(Int(item.main.temp))°C")
                .font(.headline)

            if item.pop > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                    Text("\(Int(item.pop * 100))%")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
            }
        }
        .frame(width: 80)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: item.date)
    }
}

#Preview {
    NavigationStack {
        WeatherDetailsView(city: "London")
    }
}
