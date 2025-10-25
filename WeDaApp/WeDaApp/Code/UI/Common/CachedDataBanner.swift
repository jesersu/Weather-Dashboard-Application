//
//  CachedDataBanner.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI
import DollarGeneralTemplateHelpers

/// Reusable banner to indicate cached/offline data is being displayed
public struct CachedDataBanner: View {
    let message: String

    public init(message: String = L10n.Search.cachedData) {
        self.message = message
    }

    public var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text(message)
                .font(.caption)
        }
        .foregroundColor(.orange)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack {
        CachedDataBanner()
        CachedDataBanner(message: "Showing cached weather data")
    }
}
