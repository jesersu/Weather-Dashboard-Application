//
//  TabBarItem.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation

/// Model representing a tab bar item
struct TabBarItem: Identifiable, Equatable {
    let id: String
    let icon: String
    let title: String
    let badgeCount: Int?

    init(id: String, icon: String, title: String, badgeCount: Int? = nil) {
        self.id = id
        self.icon = icon
        self.title = title
        self.badgeCount = badgeCount
    }

    // Tab definitions for the app
    static let search = TabBarItem(id: "search", icon: "magnifyingglass", title: "Search")
    static let favorites = TabBarItem(id: "favorites", icon: "star.fill", title: "Favorites")
    static let history = TabBarItem(id: "history", icon: "clock.fill", title: "History")
    static let map = TabBarItem(id: "map", icon: "map.fill", title: "Map")

    static let allTabs: [TabBarItem] = [.search, .favorites, .history, .map]
}
