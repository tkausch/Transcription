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
        "openai_whisper-large-v3-turbo",
        "openai_whisper-base",
        "openai_whisper-base.en",
        "openai_whisper-small",
        "openai_whisper-small.en",
        "openai_whisper-medium",
        "openai_whisper-medium.en",
       
    ]

    enum DownloadState {
        case idle, downloading, done, failed
    }

    private let appSettings: AppSettings

    private(set) var downloadState: DownloadState = .idle
    private(set) var downloadProgress: Double = 0
    private(set) var downloadMessage = ""
    private(set) var errorMessage: String? = nil

    var isDownloading: Bool { downloadState == .downloading }

    static func displayName(for model: String) -> String {
        model.replacingOccurrences(of: "openai_whisper-", with: "")
    }

    init(appSettings: AppSettings = .shared) {
        self.appSettings = appSettings
        // Ensure selected model is valid
        if !Self.availableModels.contains(appSettings.selectedModel) {
            appSettings.selectedModel = AppSettings.defaultModel
        }
    }

    // MARK: - Download

    func downloadModel() async {
        downloadState = .downloading
        downloadProgress = 0
        downloadMessage = "Preparing download…"
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
                            ? "Downloading model files (\(completed) of \(total))…"
                            : "Downloading…"
                    }
                }
            )
            downloadProgress = 1
            downloadMessage = "Model ready."
            downloadState = .done
            appSettings.isModelDownloaded = true
        } catch {
            downloadState = .failed
            errorMessage = error.localizedDescription
            appSettings.isModelDownloaded = false
        }
    }

    func onModelChanged() {
        appSettings.isModelDownloaded = false
        downloadState = .idle
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
