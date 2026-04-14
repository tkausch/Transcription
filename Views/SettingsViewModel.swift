//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import Observation
import WhisperKit

@Observable
@MainActor
final class SettingsViewModel {

    // Well-known WhisperKit models.
    static let availableModels: [String] = [
        "openai_whisper-large-v2",
        "openai_whisper-large-v3",

        "openai_whisper-base",
        "openai_whisper-base.en",
        "openai_whisper-small",
        "openai_whisper-small.en",
        "openai_whisper-medium",
        "openai_whisper-medium.en",

    ]

    // Approximate download sizes for each model.
    static let modelSizes: [String: String] = [
        "openai_whisper-large-v2":  "~3 GB",
        "openai_whisper-large-v3":  "~3 GB",
        "openai_whisper-base":      "~145 MB",
        "openai_whisper-base.en":   "~145 MB",
        "openai_whisper-small":     "~500 MB",
        "openai_whisper-small.en":  "~500 MB",
        "openai_whisper-medium":    "~1.5 GB",
        "openai_whisper-medium.en": "~1.5 GB",
    ]

    enum DownloadState {
        case idle, downloading, done, failed
    }

    private let appSettings: AppSettings
    private let transcriptionService: TranscriptionService

    private(set) var downloadState: DownloadState = .idle
    private(set) var downloadProgress: Double = 0
    private(set) var downloadMessage = ""
    private(set) var errorMessage: String? = nil
    var showDownloadConfirmation = false

    var isDownloading: Bool { downloadState == .downloading }

    static func displayName(for model: String) -> String {
        model.replacingOccurrences(of: "openai_whisper-", with: "")
    }

    @MainActor
    init(appSettings: AppSettings = .shared, transcriptionService: TranscriptionService = .shared) {
        self.appSettings = appSettings
        self.transcriptionService = transcriptionService
        // Ensure selected model is valid
        if !Self.availableModels.contains(appSettings.selectedModel) {
            appSettings.selectedModel = AppSettings.defaultModel
        }
    }

    // MARK: - Download

    func requestDownload() {
        showDownloadConfirmation = true
    }

    func downloadModel() async {
        downloadState = .downloading
        downloadProgress = 0
        downloadMessage = String(localized: "Preparing download…")
        errorMessage = nil

        deleteModelFiles(for: appSettings.selectedModel)

        do {
            _ = try await WhisperKit.download(
                variant: appSettings.selectedModel,
                progressCallback: { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.downloadProgress = progress.fractionCompleted
                        let completed = progress.completedUnitCount
                        let total = progress.totalUnitCount
                        self?.downloadMessage = total > 0
                            ? String(localized: "Downloading model files (\(completed) of \(total))…")
                            : String(localized: "Downloading…")
                    }
                }
            )
            downloadProgress = 1
            downloadMessage = String(localized: "Loading model...")
            appSettings.isModelDownloaded = true
            
            // Unload any existing model first
            transcriptionService.unload()
            
            // Load and prewarm the new model so it's ready for transcription
            print("[SettingsViewModel] Model downloaded, loading and prewarming...")
            await transcriptionService.load()
            
            downloadMessage = String(localized: "Model ready.")
            downloadState = .done
            print("[SettingsViewModel] Model loaded and ready")
        } catch {
            downloadState = .failed
            errorMessage = error.localizedDescription
            appSettings.isModelDownloaded = false
        }
    }

    func onModelChanged() {
        appSettings.isModelDownloaded = false
        downloadState = .idle
        transcriptionService.unload()
        print("[SettingsViewModel] Model changed, unloaded transcription service")
    }

    // MARK: - Private

    private func deleteModelFiles(for model: String) {
        let fm = FileManager.default
        guard let cacheDir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let modelDir = cacheDir
            .appending(component: "huggingface/models/argmaxinc/whisperkit-coreml", directoryHint: .isDirectory)
            .appending(component: model, directoryHint: .isDirectory)
        if fm.fileExists(atPath: modelDir.path) {
            try? fm.removeItem(at: modelDir)
        }
    }
}
