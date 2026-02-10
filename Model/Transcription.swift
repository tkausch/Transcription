//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import Foundation
import SwiftData


@Model
final class Transcription {
    
    @Attribute(.unique) var id: UUID
    
    var title: String?
    var text: String?
    var duration: TimeInterval?
    var createdAt: Date
    var audioFileURL: URL
    
    init(audioFileURL: URL) {
        self.id = UUID()
        self.createdAt = Date()
        self.audioFileURL = audioFileURL
    }
}
