//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import Foundation
import Observation
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

    private init(appSettings: AppSettings = AppSettings()) {
        self.appSettings = appSettings
    }

    // MARK: - Setup

    /// Loads the WhisperKit pipeline for the model selected in AppSettings.
    /// Must be called before transcribing. Safe to call multiple times.
    func load() async {
        guard case .idle = state else { return }

        state = .loading
        do {
            let config = WhisperKitConfig(model: appSettings.selectedModel)
            pipe = try await WhisperKit(config)
            state = .ready
        } catch {
            state = .failed(error)
        }
    }

    // MARK: - Transcription

    /// Transcribes the audio file referenced by the transcription and updates its text, language, and duration.
    func transcribe(_ transcription: Transcription) async throws {
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

        let results = await pipe.transcribe(audioPaths: [transcription.audioFileURL.path])

        let transcriptionResults = results.compactMap { $0 }.flatMap { $0 }

        transcription.text = transcriptionResults
            .map(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)

        // Use language from the first result that has one
        transcription.language = transcriptionResults.first?.language

        // Sum up audio seconds across all segments for total duration
        transcription.duration = transcriptionResults
            .map { $0.timings.inputAudioSeconds }
            .reduce(0, +)
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
            return "The transcription model has not been initialized. Please download the model in Settings."
        case .notReady:
            return "The transcription service is not ready. Please try again."
        }
    }
}
