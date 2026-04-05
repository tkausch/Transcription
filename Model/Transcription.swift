//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import Foundation
import SwiftData

enum TranscriptionSource: String, Codable {
    case imported = "imported"
    case recording = "recording"
}

@Model
final class Transcription {
    
    @Attribute(.unique) var id: UUID
    
    var title: String?
    var originalFilename: String?
    var text: String?
    var language: String?
    var duration: TimeInterval?
    var createdAt: Date
    /// Stored filename only (e.g. "uuid.mp3") — resolved to a full URL at runtime via `audioFileURL`.
    var audioFilename: String
    var isTranscribing: Bool = false
    /// Progress from 0.0 to 1.0 while transcribing. Ephemeral — not persisted.
    @Attribute(.ephemeral) var transcriptionProgress: Double = 0
    /// Error message from the last failed transcription attempt. Ephemeral — not persisted.
    @Attribute(.ephemeral) var transcriptionError: String? = nil
    var summary: String?
    var source: TranscriptionSource = TranscriptionSource.imported

    /// Resolves the stored filename to the current app sandbox path at runtime.
    var audioFileURL: URL {
        (try? AudioFileStore.url(for: audioFilename))
            ?? FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appending(component: "AudioFiles/\(audioFilename)")
    }

    init(audioFilename: String, source: TranscriptionSource = .imported) {
        self.id = UUID()
        self.createdAt = Date()
        self.audioFilename = audioFilename
        self.source = source
    }
}
