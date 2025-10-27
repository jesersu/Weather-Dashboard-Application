//
//  WeDaApp.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI
import SwiftData
import BackgroundTasks
import DollarGeneralPersist

@main
struct WeDaApp: App {
    // Background task manager for silent weather updates
    private let backgroundTaskManager = BackgroundTaskManager()

    init() {
        // Initialize SwiftData (via LocalStorageService.shared lazy initialization)
        // This ensures the ModelContainer is created early in app lifecycle
        Task { @MainActor in
            _ = LocalStorageService.shared
        }

        // Register background tasks BEFORE app finishes launching
        // This is required by BGTaskScheduler API
        backgroundTaskManager.registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Schedule initial background refresh when app launches
                    backgroundTaskManager.scheduleBackgroundRefresh()
                }
        }
    }
}
