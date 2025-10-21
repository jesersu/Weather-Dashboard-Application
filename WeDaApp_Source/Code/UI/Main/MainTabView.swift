//
//  MainTabView.swift
//  WeDaApp
//
//  Created by Claude Code
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            SearchPlaceholderView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            FavoritesPlaceholderView()
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }

            HistoryPlaceholderView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
    }
}

// MARK: - Placeholder Views (to be replaced with actual implementations)

struct SearchPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)

                Text("Search Weather")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Search functionality will be implemented here")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Search")
        }
    }
}

struct FavoritesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.yellow.gradient)

                Text("Favorite Cities")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Your favorite cities will appear here")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Favorites")
        }
    }
}

struct HistoryPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.purple.gradient)

                Text("Search History")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Your recent searches will appear here")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("History")
        }
    }
}

#Preview {
    MainTabView()
}
