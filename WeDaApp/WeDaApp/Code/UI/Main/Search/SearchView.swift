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

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Main content
                contentView

                // Autocomplete overlay
                if viewModel.showSuggestions && !viewModel.citySuggestions.isEmpty {
                    CitySuggestionsOverlay(
                        suggestions: viewModel.citySuggestions,
                        onSelect: { viewModel.selectSuggestion($0) }
                    )
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
                if viewModel.weatherData != nil && !viewModel.isLocationWeather {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .task {
                await viewModel.loadLocationWeatherIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
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
            SearchResultsView(
                weather: weather,
                isShowingCachedData: viewModel.isShowingCachedData
            )
        } else {
            SearchEmptyStateView()
        }
    }
}

// MARK: - Search Results View

private struct SearchResultsView: View {
    let weather: WeatherData
    let isShowingCachedData: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Offline indicator
                if isShowingCachedData {
                    CachedDataBanner()
                }

                WeatherCard(weatherData: weather)
                    .padding(.horizontal, AppSpacing.md)

                NavigationLink {
                    WeatherDetailsView(city: weather.name)
                } label: {
                    Label(L10n.Search.viewDetails, systemImage: "chart.line.uptrend.xyaxis")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(AppSpacing.md)
                        .background(AppGradients.primary)
                        .cornerRadius(AppRadius.medium)
                        .shadow(
                            color: AppShadow.small.color,
                            radius: AppShadow.small.radius,
                            x: AppShadow.small.x,
                            y: AppShadow.small.y
                        )
                }
                .padding(.horizontal, AppSpacing.md)
            }
            .padding(.top, 8)
        }
        .accessibilityIdentifier(UITestIDs.SearchView.resultsScrollView.rawValue)
    }
}

// MARK: - Empty State View

private struct SearchEmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: AppSpacing.xl) {
                ZStack {
                    Circle()
                        .fill(AppGradients.primary)
                        .frame(width: 140, height: 140)
                        .opacity(0.15)

                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(AppGradients.primary)
                }

                VStack(spacing: AppSpacing.md) {
                    Text(L10n.Search.emptyTitle)
                        .font(AppTypography.largeTitle)

                    Text(L10n.Search.emptySubtitle)
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }
            }

            Spacer()
        }
    }
}

// MARK: - City Suggestions Overlay

private struct CitySuggestionsOverlay: View {
    let suggestions: [GeocodeResult]
    let onSelect: (GeocodeResult) -> Void

    var body: some View {
        VStack {
            Spacer()
                .frame(height: 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions) { suggestion in
                        CitySuggestionRow(suggestion: suggestion) {
                            onSelect(suggestion)
                        }

                        if suggestion.id != suggestions.last?.id {
                            Divider()
                        }
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

// MARK: - City Suggestion Row

private struct CitySuggestionRow: View {
    let suggestion: GeocodeResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
    }
}

// MARK: - Preview

#Preview {
    SearchView()
}
