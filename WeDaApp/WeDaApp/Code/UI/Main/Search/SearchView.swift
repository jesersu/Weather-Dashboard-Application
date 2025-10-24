//
//  SearchView.swift
//  WeDaApp
//
//  Created by Jesus Chapi
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
                VStack(spacing: 0) {
                    if viewModel.isLoadingLocation {
                        LoadingView(message: L10n.Search.gettingLocation)
                            .accessibilityIdentifier(UITestIDs.SearchView.locationLoadingView.rawValue)
                    } else if viewModel.isLoading {
                        LoadingView(message: L10n.Search.searchingWeather)
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
                                        Text(L10n.Search.cachedData)
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
                                    Label(L10n.Search.viewDetails, systemImage: "chart.line.uptrend.xyaxis")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top, 8)
                        }
                        .accessibilityIdentifier(UITestIDs.SearchView.resultsScrollView.rawValue)
                    } else {
                        // Empty state
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "cloud.sun.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.blue.gradient)

                            Text(L10n.Search.emptyTitle)
                                .font(.title)
                                .fontWeight(.bold)

                            Text(L10n.Search.emptySubtitle)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Spacer()
                    }
                }

                // Autocomplete suggestions overlay
                if viewModel.showSuggestions && !viewModel.citySuggestions.isEmpty {
                    VStack {
                        Spacer()
                            .frame(height: 8)

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
            .navigationTitle(L10n.Search.title)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: L10n.Search.placeholder
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
            .task {
                await viewModel.loadLocationWeatherIfNeeded()
            }
        }
    }
}

#Preview {
    SearchView()
}
