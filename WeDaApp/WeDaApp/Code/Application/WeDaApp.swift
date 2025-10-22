//
//  WeDaApp.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import SwiftUI
import BackgroundTasks

@main
struct WeDaApp: App {

    // Background task manager for silent weather updates
    private let backgroundTaskManager = BackgroundTaskManager()

    init() {
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
