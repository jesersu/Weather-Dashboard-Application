//
//  SearchView.swift
//  WeDaApp
//
//  Created by Claude Code
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI
import DollarGeneralTemplateHelpers

struct SearchView: View {

    @StateObject private var viewModel = SearchViewModel()
    @State private var showWeatherDetails = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    LoadingView(message: "Searching weather...")
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        viewModel.retry()
                    }
                } else if let weather = viewModel.weatherData {
                    ScrollView {
                        VStack(spacing: 20) {
                            WeatherCard(weatherData: weather)
                                .padding()

                            NavigationLink {
                                WeatherDetailsView(city: weather.name)
                            } label: {
                                Label("View Detailed Forecast", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .accessibilityIdentifier(UITestIDs.SearchView.resultsScrollView.rawValue)
                } else {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "cloud.sun.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue.gradient)

                        Text("Search Weather")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Enter a city name to get current weather information")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Enter city name"
            )
            .onSubmit(of: .search) {
                Task {
                    await viewModel.search(city: viewModel.searchText)
                }
            }
            .toolbar {
                if viewModel.weatherData != nil {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    SearchView()
}
