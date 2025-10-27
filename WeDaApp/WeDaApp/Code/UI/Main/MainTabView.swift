//
//  MainTabView.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
    // MARK: - ViewModels
    // Create ViewModels once at parent level - they persist across tab switches
    // This prevents view recreation and unwanted side effects (e.g., location refetch)
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @StateObject private var historyViewModel = HistoryViewModel()
    @StateObject private var mapViewModel = WeatherMapViewModel()

    var body: some View {
        CustomTabBarView { tabId in
            switch tabId {
            case TabBarItem.search.id:
                SearchView(viewModel: searchViewModel)

            case TabBarItem.favorites.id:
                FavoritesView(viewModel: favoritesViewModel)

            case TabBarItem.history.id:
                HistoryView(viewModel: historyViewModel)

            case TabBarItem.map.id:
                NavigationStack {
                    WeatherMapView(viewModel: mapViewModel)
                }

            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    MainTabView()
}
