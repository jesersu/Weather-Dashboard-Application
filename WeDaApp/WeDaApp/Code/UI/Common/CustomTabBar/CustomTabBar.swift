//
//  CustomTabBar.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI

/// Floating custom tab bar with gradient background and smooth animations
struct CustomTabBar: View {
    let tabs: [TabBarItem]
    @Binding var selectedTab: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                TabBarButton(
                    item: tab,
                    isSelected: selectedTab == tab.id
                ) {
                    selectedTab = tab.id
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: Color.purple.opacity(0.15),
                    radius: 15,
                    x: 0,
                    y: -5
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(tabs: TabBarItem.allTabs, selectedTab: .constant("search"))
    }
    .background(Color(.systemGroupedBackground))
}
