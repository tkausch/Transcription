//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import Foundation
import Observation

@Observable
final class AppSettings {

    static let shared = AppSettings()

    private enum Keys {
        static let isModelDownloaded = "isModelDownloaded"
        static let selectedModel = "selectedModel"
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }

    static let defaultModel = "openai_whisper-large-v3"

    var isModelDownloaded: Bool {
        didSet { UserDefaults.standard.set(isModelDownloaded, forKey: Keys.isModelDownloaded) }
    }

    var selectedModel: String {
        didSet { UserDefaults.standard.set(selectedModel, forKey: Keys.selectedModel) }
    }

    var hasSeenOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    init() {
        self.isModelDownloaded = UserDefaults.standard.bool(forKey: Keys.isModelDownloaded)
        self.selectedModel = UserDefaults.standard.string(forKey: Keys.selectedModel) ?? AppSettings.defaultModel
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: Keys.hasSeenOnboarding)
    }
}
