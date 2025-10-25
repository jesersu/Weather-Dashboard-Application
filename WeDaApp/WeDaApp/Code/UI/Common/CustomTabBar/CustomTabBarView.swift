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
        ZStack(alignment: .bottom) {
            // Tab content with slide transition
            content(selectedTab)
                .id(selectedTab) // Force view recreation for smooth transition
                .transition(.asymmetric(
                    insertion: .move(edge: selectedTabEdge).combined(with: .opacity),
                    removal: .move(edge: selectedTabEdge.opposite).combined(with: .opacity)
                ))

            // Custom tab bar
            CustomTabBar(tabs: tabs, selectedTab: $selectedTab)
        }
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .ignoresSafeArea(.keyboard) // Prevent tab bar from moving with keyboard
    }

    /// Determine which edge to slide in from based on tab order
    private var selectedTabEdge: Edge {
        guard let currentIndex = tabs.firstIndex(where: { $0.id == selectedTab }),
              let previousIndex = tabs.firstIndex(where: { $0.id == selectedTab }) else {
            return .leading
        }

        return currentIndex > previousIndex ? .trailing : .leading
    }
}

// MARK: - Edge Extension

private extension Edge {
    var opposite: Edge {
        switch self {
        case .top: return .bottom
        case .bottom: return .top
        case .leading: return .trailing
        case .trailing: return .leading
        }
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
