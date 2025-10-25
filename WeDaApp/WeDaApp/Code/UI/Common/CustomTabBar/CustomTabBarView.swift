//
//  CustomTabBarView.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI

/// Main custom tab bar view with state management and smooth transitions
struct CustomTabBarView<Content: View>: View {
    @State private var selectedTab: String
    let tabs: [TabBarItem]
    let content: (String) -> Content

    init(
        selectedTab: String = TabBarItem.search.id,
        tabs: [TabBarItem] = TabBarItem.allTabs,
        @ViewBuilder content: @escaping (String) -> Content
    ) {
        self._selectedTab = State(initialValue: selectedTab)
        self.tabs = tabs
        self.content = content
    }

    var body: some View {
        // Tab content - state preserved across tab switches
        content(selectedTab)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Custom tab bar as safe area inset (pushes content up automatically)
                CustomTabBar(tabs: tabs, selectedTab: $selectedTab)
            }
            .animation(.easeInOut(duration: 0.25), value: selectedTab)
            .ignoresSafeArea(.keyboard) // Prevent tab bar from moving with keyboard
    }
}

// MARK: - Preview

#Preview {
    CustomTabBarView { tabId in
        ZStack {
            switch tabId {
            case TabBarItem.search.id:
                Color.purple.opacity(0.1)
                    .overlay(Text("Search Tab").font(.largeTitle))
            case TabBarItem.favorites.id:
                Color.blue.opacity(0.1)
                    .overlay(Text("Favorites Tab").font(.largeTitle))
            case TabBarItem.history.id:
                Color.green.opacity(0.1)
                    .overlay(Text("History Tab").font(.largeTitle))
            case TabBarItem.map.id:
                Color.orange.opacity(0.1)
                    .overlay(Text("Map Tab").font(.largeTitle))
            default:
                EmptyView()
            }
        }
        .ignoresSafeArea()
    }
}
