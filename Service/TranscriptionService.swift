//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import Foundation
import Observation
import AVFoundation
import WhisperKit

@Observable
@MainActor
final class TranscriptionService {

    static let shared = TranscriptionService()

    enum State {
        case idle
        case loading
        case ready
        case transcribing
        case failed(Error)
    }

    private(set) var state: State = .idle

    private var pipe: WhisperKit?
    private let appSettings: AppSettings

    private init(appSettings: AppSettings = .shared) {
        self.appSettings = appSettings
    }

    // MARK: - Setup

    /// Loads the WhisperKit pipeline for the model selected in AppSettings.
    /// Must be called before transcribing. Safe to call multiple times.
    func load() async {
        guard case .idle = state else { return }

        state = .loading
        let model = appSettings.selectedModel
        do {
            // Run heavy model initialisation off the main actor to avoid blocking the UI.
            let newPipe = try await Task.detached(priority: .userInitiated) {
                let config = WhisperKitConfig(model: model)
                return try await WhisperKit(config)
            }.value
            pipe = newPipe
            state = .ready
        } catch {
            state = .failed(error)
        }
    }

    // MARK: - Transcription

    /// Transcribes the audio file referenced by the transcription and updates its text, language, and duration.
    func transcribe(_ transcription: Transcription) async throws {
        try await transcribeAudioAt(
            path: transcription.audioFileURL.path,
            onProgress: { [weak transcription] fraction in
                transcription?.transcriptionProgress = fraction
            },
            onResult: { text, language, duration in
                transcription.text = text
                transcription.language = language
                transcription.duration = duration
            }
        )
    }

#if os(iOS)
    /// Transcribes an audio file for use from an AppIntent (not persisted to SwiftData).
    func transcribeTransient(_ transcription: TransientTranscription) async throws {
        try await transcribeAudioAt(
            path: transcription.audioFileURL.path,
            onProgress: { [weak transcription] fraction in
                transcription?.transcriptionProgress = fraction
            },
            onResult: { text, language, duration in
                transcription.text = text
                transcription.language = language
                transcription.duration = duration
            }
        )
    }
#endif

    // MARK: - Core transcription engine

    private func transcribeAudioAt(
        path audioPath: String,
        onProgress: @escaping @MainActor (Double) -> Void,
        onResult: @MainActor @escaping (String, String?, TimeInterval) -> Void
    ) async throws {
        // Ensure the pipeline is ready, loading it if needed
        if case .idle = state { await load() }

        guard let pipe else {
            throw TranscriptionError.notInitialized
        }

        guard case .ready = state else {
            throw TranscriptionError.notReady(state)
        }

        state = .transcribing
        defer {
            if case .transcribing = state { state = .ready }
        }

        // Get total audio duration for progress calculation
        let audioDuration: Double = await Task.detached(priority: .userInitiated) {
            let asset = AVURLAsset(url: URL(fileURLWithPath: audioPath))
            let duration = try? await asset.load(.duration)
            return duration.map { CMTimeGetSeconds($0) } ?? 0
        }.value

        onProgress(0)

        // Set segment discovery callback to report progress per decoded segment
        pipe.segmentDiscoveryCallback = { segments in
            guard audioDuration > 0, let lastEnd = segments.last.map({ Double($0.end) }) else { return }
            let fraction = min(lastEnd / audioDuration, 1.0)
            Task { @MainActor in
                onProgress(fraction)
            }
        }
        defer { pipe.segmentDiscoveryCallback = nil }

        // Disable fallback thresholds to suppress noisy fallback warnings
        // Use the transcription mode from settings to determine task type
        print("[TranscriptionService] Reading transcriptionMode from settings: \(appSettings.transcriptionMode.rawValue)")
        print("[TranscriptionService] Comparison: transcriptionMode == .transcribe is \(appSettings.transcriptionMode == .transcribe)")
        let task: DecodingTask = appSettings.transcriptionMode == .transcribe ? .transcribe : .translate
        print("[TranscriptionService] Selected DecodingTask: \(task)")
        
        let decodeOptions = DecodingOptions(
            task: task,
            compressionRatioThreshold: nil, 
            firstTokenLogProbThreshold: nil
        )
        print("[TranscriptionService] DecodingOptions task: \(decodeOptions.task ?? .transcribe)")

        let results = await Task.detached(priority: .userInitiated) {
            await pipe.transcribe(audioPaths: [audioPath], decodeOptions: decodeOptions)
        }.value

        let transcriptionResults = results.compactMap { $0 }.flatMap { $0 }

        let text = transcriptionResults
            .map(\.text)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let language = transcriptionResults.first?.language

        let duration = transcriptionResults
            .map { $0.timings.inputAudioSeconds }
            .reduce(0, +)

        onResult(text, language, duration)
    }

    // MARK: - Reset

    /// Releases the loaded pipeline, e.g. when the selected model changes.
    func unload() {
        pipe = nil
        state = .idle
    }
}

// MARK: - Errors

enum TranscriptionError: LocalizedError {
    case notInitialized
    case notReady(TranscriptionService.State)

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return String(localized: "The transcription model has not been initialized. Please download the model in Settings.")
        case .notReady:
            return String(localized: "The transcription service is not ready. Please try again.")
        }
    }
}
