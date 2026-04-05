//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import Foundation
import Observation

enum TranscriptionMode: String, CaseIterable, Identifiable {
    case transcribe = "transcribe"
    case translate = "translate"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .transcribe:
            return String(localized: "Transcribe only")
        case .translate:
            return String(localized: "Translate to English")
        }
    }
}

@Observable
final class AppSettings {

    nonisolated(unsafe) static let shared = AppSettings()

    private enum Keys {
        static let isModelDownloaded = "isModelDownloaded"
        static let selectedModel = "selectedModel"
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let forceDarkMode = "forceDarkMode"
        static let transcriptionMode = "transcriptionMode"
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

    var forceDarkMode: Bool {
        didSet { UserDefaults.standard.set(forceDarkMode, forKey: Keys.forceDarkMode) }
    }
    
    var transcriptionMode: TranscriptionMode {
        didSet { 
            UserDefaults.standard.set(transcriptionMode.rawValue, forKey: Keys.transcriptionMode)
            print("[AppSettings] TranscriptionMode changed to: \(transcriptionMode.rawValue)")
        }
    }

    init() {
        self.isModelDownloaded = UserDefaults.standard.bool(forKey: Keys.isModelDownloaded)
        self.selectedModel = UserDefaults.standard.string(forKey: Keys.selectedModel) ?? AppSettings.defaultModel
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: Keys.hasSeenOnboarding)
        self.forceDarkMode = UserDefaults.standard.bool(forKey: Keys.forceDarkMode)
        
        let modeRawValue = UserDefaults.standard.string(forKey: Keys.transcriptionMode) ?? TranscriptionMode.transcribe.rawValue
        self.transcriptionMode = TranscriptionMode(rawValue: modeRawValue) ?? .transcribe
        print("[AppSettings] Initialized transcriptionMode: \(self.transcriptionMode.rawValue)")
    }
}
