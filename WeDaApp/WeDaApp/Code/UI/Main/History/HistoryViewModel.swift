//
//  HistoryViewModel.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import DollarGeneralPersist
import DollarGeneralTemplateHelpers

@MainActor
final class HistoryViewModel: ObservableObject {

    @Published var history: [SearchHistoryItem] = []
    @Published var isLoading = false

    private let storageService: LocalStorageServiceProtocol

    init(storageService: LocalStorageServiceProtocol = LocalStorageService()) {
        self.storageService = storageService
        loadHistory()
    }

    func loadHistory() {
        do {
            history = try storageService.getHistory()
            LogInfo("Loaded \(history.count) history items")
        } catch {
            LogError("Failed to load history: \(error)")
        }
    }

    func deleteHistoryItem(id: String) {
        do {
            try storageService.removeHistoryItem(id: id)
            loadHistory()
            LogInfo("Deleted history item: \(id)")
        } catch {
            LogError("Failed to delete history item: \(error)")
        }
    }

    func clearHistory() {
        do {
            try storageService.clearHistory()
            loadHistory()
            LogInfo("Cleared history")
        } catch {
            LogError("Failed to clear history: \(error)")
        }
    }
}
