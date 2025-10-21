//
//  FavoritesViewModel.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import DollarGeneralTemplateHelpers

@MainActor
final class FavoritesViewModel: ObservableObject {

    @Published var favorites: [FavoriteCity] = []
    @Published var isLoading = false

    private let storageService: LocalStorageServiceProtocol

    init(storageService: LocalStorageServiceProtocol = LocalStorageService()) {
        self.storageService = storageService
        loadFavorites()
    }

    func loadFavorites() {
        do {
            favorites = try storageService.getFavorites()
            LogInfo("Loaded \(favorites.count) favorites")
        } catch {
            LogError("Failed to load favorites: \(error)")
        }
    }

    func removeFavorite(id: String) {
        do {
            try storageService.removeFavorite(id: id)
            loadFavorites()
            LogInfo("Removed favorite")
        } catch {
            LogError("Failed to remove favorite: \(error)")
        }
    }
}
