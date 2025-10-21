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
            ZStack(alignment: .top) {
                if viewModel.isLoading {
                    LoadingView(message: "Searching weather...")
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        viewModel.retry()
                    }
                } else if let weather = viewModel.weatherData {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Offline indicator
                            if viewModel.isShowingCachedData {
                                HStack {
                                    Image(systemName: "wifi.slash")
                                    Text("Showing cached data (offline)")
                                        .font(.caption)
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            }

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

                // Autocomplete suggestions overlay
                if viewModel.showSuggestions && !viewModel.citySuggestions.isEmpty {
                    VStack {
                        Spacer()
                            .frame(height: 60) // Space for navigation bar and search field

                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(viewModel.citySuggestions) { suggestion in
                                    Button {
                                        viewModel.selectSuggestion(suggestion)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(suggestion.name)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)

                                                Text(suggestion.displayName)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                    }
                                    .accessibilityIdentifier("\(UITestIDs.SearchView.suggestionItem.rawValue)_\(suggestion.id)")

                                    Divider()
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 300)
                        .accessibilityIdentifier(UITestIDs.SearchView.suggestionsList.rawValue)

                        Spacer()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .navigationTitle("Search")
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Enter city name"
            )
            .onSubmit(of: .search) {
                viewModel.hideSuggestions()
                Task {
                    await viewModel.search(city: viewModel.searchText)
                }
            }
            .onChange(of: viewModel.searchText) { oldValue, newValue in
                viewModel.searchCities(query: newValue)
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
