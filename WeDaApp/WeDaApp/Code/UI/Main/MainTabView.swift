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
        TabView {
            SearchView()
                .tabItem {
                    Label(L10n.Tab.search, systemImage: "magnifyingglass")
                }

            FavoritesView()
                .tabItem {
                    Label(L10n.Tab.favorites, systemImage: "star.fill")
                }

            HistoryView()
                .tabItem {
                    Label(L10n.Tab.history, systemImage: "clock.fill")
                }

            NavigationStack {
                WeatherMapView()
            }
            .tabItem {
                Label(L10n.Tab.map, systemImage: "map.fill")
            }
        }
    }
}

#Preview {
    MainTabView()
}
