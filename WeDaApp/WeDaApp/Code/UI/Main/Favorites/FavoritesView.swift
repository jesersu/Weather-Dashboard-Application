//
//  FavoritesView.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI
import DollarGeneralPersist
import DollarGeneralTemplateHelpers

struct FavoritesView: View {

    @ObservedObject var viewModel: FavoritesViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favorites.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.yellow.gradient)

                        Text("No Favorites")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Add cities to your favorites from the weather details screen")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.favorites) { favorite in
                                NavigationLink {
                                    WeatherDetailsView(city: favorite.cityName)
                                } label: {
                                    FavoriteItemView(favorite: favorite)
                                }
                                .accessibilityIdentifier(UITestIDs.FavoritesView.favoriteItem.rawValue)
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }
                    .accessibilityIdentifier(UITestIDs.FavoritesView.scrollView.rawValue)
                }
            }
            .navigationTitle("Favorites")
            .onAppear {
                viewModel.loadFavorites()
            }
        }
    }
}

private struct FavoriteItemView: View {
    let favorite: FavoriteCity

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Gradient Star Badge
            ZStack {
                Circle()
                    .fill(AppGradients.primary)
                    .frame(width: 40, height: 40)

                Image(systemName: "star.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: AppShadow.small.color,
                    radius: AppShadow.small.radius,
                    x: AppShadow.small.x,
                    y: AppShadow.small.y)

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(favorite.cityName)
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)

                if let country = favorite.country {
                    Text(country)
                        .font(AppTypography.subheadline)
                        .foregroundColor(.secondary)
                }

                // Metadata Row
                HStack(spacing: AppSpacing.xs) {
                    Text(coordinatesString)
                        .font(AppTypography.caption2)
                        .foregroundStyle(.tertiary)

                    Text("•")
                        .font(AppTypography.caption2)
                        .foregroundStyle(.tertiary)

                    Text(addedAtString)
                        .font(AppTypography.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .strokeBorder(AppGradients.primary.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: AppShadow.medium.color,
                radius: AppShadow.medium.radius,
                x: AppShadow.medium.x,
                y: AppShadow.medium.y)
    }

    // MARK: - Computed Properties

    private var coordinatesString: String {
        let latDirection = favorite.coordinates.lat >= 0 ? "N" : "S"
        let lonDirection = favorite.coordinates.lon >= 0 ? "E" : "W"
        let lat = abs(favorite.coordinates.lat)
        let lon = abs(favorite.coordinates.lon)
        return String(format: "%.2f°%@, %.2f°%@", lat, latDirection, lon, lonDirection)
    }

    private var addedAtString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Added " + formatter.localizedString(for: favorite.addedAt, relativeTo: Date())
    }
}

#Preview {
    FavoritesView(viewModel: FavoritesViewModel())
}
