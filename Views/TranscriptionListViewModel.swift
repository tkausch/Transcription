//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@Observable
@MainActor
final class TranscriptionListViewModel {

    private let repository: TranscriptionRepository
    private let appSettings: AppSettings
    private let transcriptionService: TranscriptionService

    private(set) var transcriptions: [Transcription] = []
    var selectedTranscription: Transcription?
    var showSettings: Bool = false
    var showFilePicker: Bool = false
    var showVoiceRecording: Bool = false
    var importError: Error? = nil
    
    var importedTranscriptions: [Transcription] {
        let filtered = transcriptions.filter { $0.sourceType == .imported }
        print("[TranscriptionList] Imported: \(filtered.count) transcriptions")
        for t in filtered {
            print("  - \(t.title ?? "Untitled") - source: \(t.source)")
        }
        return filtered
    }
    
    var recordedTranscriptions: [Transcription] {
        let filtered = transcriptions.filter { $0.sourceType == .recording }
        print("[TranscriptionList] Recorded: \(filtered.count) transcriptions")
        for t in filtered {
            print("  - \(t.title ?? "Untitled") - source: \(t.source)")
        }
        return filtered
    }

    init(modelContext: ModelContext, appSettings: AppSettings = .shared, transcriptionService: TranscriptionService = .shared) {
        self.repository = TranscriptionRepository(modelContext: modelContext)
        self.appSettings = appSettings
        self.transcriptionService = transcriptionService
    }

    // MARK: - Load

    func onAppear() {
        loadTranscriptions()
        if !appSettings.isModelDownloaded {
            showSettings = true
        }
    }

    func loadTranscriptions() {
        transcriptions = (try? repository.fetchAll()) ?? []
        if let selected = selectedTranscription,
           !transcriptions.contains(where: { $0.id == selected.id }) {
            selectedTranscription = nil
        }
    }

    // MARK: - Import

    func importAudioFile(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            let filename = try AudioFileStore.copy(from: url)
            let transcription = Transcription(audioFilename: filename, source: .imported)
            transcription.title = url.deletingPathExtension().lastPathComponent
            transcription.originalFilename = url.lastPathComponent
            try repository.save(transcription)
            loadTranscriptions()
            // Yield to let SwiftUI process the list update before setting selection
            Task { @MainActor in
                self.selectedTranscription = transcription
                await startTranscription(for: transcription)
            }
        } catch {
            print("[Import] Failed to import \(url.lastPathComponent): \(error)")
            importError = error
        }
    }

    private func startTranscription(for transcription: Transcription) async {
        transcription.isTranscribing = true
        transcription.transcriptionError = nil
        try? repository.update(transcription)

        do {
            try await transcriptionService.transcribe(transcription)
            transcription.isTranscribing = false
            try? repository.update(transcription)
            loadTranscriptions()
        } catch {
            transcription.isTranscribing = false
            transcription.transcriptionError = error.localizedDescription
            try? repository.update(transcription)
        }
    }

    func retryTranscription(for transcription: Transcription) {
        Task { @MainActor in
            await startTranscription(for: transcription)
        }
    }
    
    func onRecordingComplete(_ transcription: Transcription) {
        loadTranscriptions()
        selectedTranscription = transcription
        Task { @MainActor in
            await startTranscription(for: transcription)
        }
    }

    // MARK: - Delete

    func delete(_ transcription: Transcription) {
        try? AudioFileStore.delete(filename: transcription.audioFilename)
        try? repository.delete(transcription)
        loadTranscriptions()
    }

    func deleteTranscriptions(offsets: IndexSet) {
        for index in offsets {
            let t = transcriptions[index]
            try? AudioFileStore.delete(filename: t.audioFilename)
            try? repository.delete(t)
        }
        loadTranscriptions()
    }
    
    func deleteImportedTranscriptions(offsets: IndexSet) {
        for index in offsets {
            let t = importedTranscriptions[index]
            try? AudioFileStore.delete(filename: t.audioFilename)
            try? repository.delete(t)
        }
        loadTranscriptions()
    }
    
    func deleteRecordedTranscriptions(offsets: IndexSet) {
        for index in offsets {
            let t = recordedTranscriptions[index]
            try? AudioFileStore.delete(filename: t.audioFilename)
            try? repository.delete(t)
        }
        loadTranscriptions()
    }

    // MARK: - Allowed audio types

    static let audioContentTypes: [UTType] = [
        .mp3, .mpeg4Audio, .wav, UTType(filenameExtension: "m4a")!
    ]
}
