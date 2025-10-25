//
//  MainTabView.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        CustomTabBarView { tabId in
            switch tabId {
            case TabBarItem.search.id:
                SearchView()

            case TabBarItem.favorites.id:
                FavoritesView()

            case TabBarItem.history.id:
                HistoryView()

            case TabBarItem.map.id:
                NavigationStack {
                    WeatherMapView()
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
