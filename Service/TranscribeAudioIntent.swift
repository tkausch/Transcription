//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

#if os(iOS)
import AppIntents
import Foundation
import UniformTypeIdentifiers

/// An App Intent that transcribes an audio file and returns the transcription text.
/// The app is brought to the foreground so the WhisperKit model can run.
struct TranscribeAudioIntent: AppIntent {

    static var title: LocalizedStringResource = "Transcribe Audio"

    static var description = IntentDescription(
        "Transcribes an audio file using Whisper and returns the text."
    )

    /// Brings the app to the foreground so the model pipeline can load and run.
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Audio File", description: "The audio file to transcribe (MP3, M4A, WAV, MP4).")
    var audioFile: IntentFile

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Use withFile to get a URL, falling back to writing data manually
        let text = try await transcribeIntentFile(audioFile)
        guard !text.isEmpty else {
            throw TranscribeAudioIntentError.emptyResult
        }
        return .result(value: text)
    }

    // MARK: - Private

    @MainActor
    private func transcribeIntentFile(_ file: IntentFile) async throws -> String {
        // Try to use an existing file URL first (avoids copying data into memory)
        if let existingURL = file.fileURL {
            return try await runTranscription(audioURL: existingURL)
        }

        // Otherwise write the in-memory data to a temp file
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appending(component: file.filename, directoryHint: .notDirectory)
        let data = file.data
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        return try await runTranscription(audioURL: tempURL)
    }

    @MainActor
    private func runTranscription(audioURL: URL) async throws -> String {
        let transcription = TransientTranscription(audioURL: audioURL)
        try await TranscriptionService.shared.transcribeTransient(transcription)
        return transcription.text ?? ""
    }
}

// MARK: - Errors

enum TranscribeAudioIntentError: LocalizedError {
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .emptyResult:
            return "No speech was detected in the audio file."
        }
    }
}

// MARK: - Transient transcription (not persisted to SwiftData)

/// A lightweight, non-SwiftData transcription object used solely within the intent.
@MainActor
final class TransientTranscription {
    let audioFileURL: URL
    var text: String?
    var language: String?
    var duration: TimeInterval?
    var transcriptionProgress: Double = 0

    init(audioURL: URL) {
        self.audioFileURL = audioURL
    }
}

#endif
