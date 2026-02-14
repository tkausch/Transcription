//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import Foundation
import SwiftData

enum TranscriptionSource: String, Codable {
    case file
    case recording
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
    var source: TranscriptionSource = TranscriptionSource.file
    var summary: String?

    /// Resolves the stored filename to the current app sandbox path at runtime.
    var audioFileURL: URL {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appending(component: "AudioFiles", directoryHint: .isDirectory)
                         .appending(component: audioFilename, directoryHint: .notDirectory)
    }

    init(audioFilename: String, source: TranscriptionSource = .file) {
        self.id = UUID()
        self.createdAt = Date()
        self.audioFilename = audioFilename
        self.source = source
    }
}
