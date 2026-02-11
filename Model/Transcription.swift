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
    var text: String?
    var language: String?
    var duration: TimeInterval?
    var createdAt: Date
    var audioFileURL: URL
    var isTranscribing: Bool = false
    var source: TranscriptionSource = TranscriptionSource.file
    var summary: String?

    init(audioFileURL: URL, source: TranscriptionSource = .file) {
        self.id = UUID()
        self.createdAt = Date()
        self.audioFileURL = audioFileURL
        self.source = source
    }
}
