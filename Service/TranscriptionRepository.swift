//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftData
import Foundation


protocol TranscriptionRepositoryProtocol {
    func fetchAll() throws -> [Transcription]
    func fetch(by id: UUID) throws -> Transcription?
    func save(_ transcription: Transcription) throws
    func update(_ transcription: Transcription) throws
    func delete(_ transcription: Transcription) throws
    func search(query: String) throws -> [Transcription]
}



@MainActor
final class TranscriptionRepository: TranscriptionRepositoryProtocol {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() throws -> [Transcription] {
        let descriptor = FetchDescriptor<Transcription>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let results = try modelContext.fetch(descriptor)
        return results
    }
    
    func fetch(by id: UUID) throws -> Transcription? {
        let descriptor = FetchDescriptor<Transcription>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func save(_ transcription: Transcription) throws {
        modelContext.insert(transcription)
        try modelContext.save()
    }
    
    func update(_ transcription: Transcription) throws {
        // SwiftData automatically tracks changes
        try modelContext.save()
    }
    
    func delete(_ transcription: Transcription) throws {
        modelContext.delete(transcription)
        try modelContext.save()
    }
    
    func search(query: String) throws -> [Transcription] {
        let descriptor = FetchDescriptor<Transcription>(
            predicate: #Predicate { transcription in
                (transcription.title ?? "").localizedStandardContains(query) ||
                (transcription.text ?? "").localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    

    #if DEBUG
    func makeSampleTestTranscription() -> Transcription {
        let sample = Transcription(audioFilename: "welcome_recording.m4a")
        sample.title = "Welcome"
        sample.text = "This is a sample transcription to help you get started. Open an audio file or tap the microphone button to record something new. Your transcriptions will appear here once processing is complete."
        sample.duration = 42.0
        return sample
    }
    #endif

}
