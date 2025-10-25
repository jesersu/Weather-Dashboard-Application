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

    @StateObject private var viewModel = FavoritesViewModel()

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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(favorite.cityName)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let country = favorite.country {
                    Text(country)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    FavoritesView()
}
