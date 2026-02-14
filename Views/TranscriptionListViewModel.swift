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
    var importError: Error? = nil

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
            let filename = try copyToAudioStore(url: url)
            let transcription = Transcription(audioFilename: filename)
            transcription.title = url.deletingPathExtension().lastPathComponent
            transcription.originalFilename = url.lastPathComponent
            try repository.save(transcription)
            loadTranscriptions()
            selectedTranscription = transcription
            Task { await startTranscription(for: transcription) }
        } catch {
            print("[Import] Failed to import \(url.lastPathComponent): \(error)")
            importError = error
        }
    }

    private func startTranscription(for transcription: Transcription) async {
        transcription.isTranscribing = true
        try? repository.update(transcription)

        do {
            try await transcriptionService.transcribe(transcription)
            transcription.isTranscribing = false
            try? repository.update(transcription)
            loadTranscriptions()
        } catch {
            transcription.isTranscribing = false
            try? repository.update(transcription)
            importError = error
        }
    }

    private func copyToAudioStore(url: URL) throws -> String {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        let dir = appSupport.appending(component: "AudioFiles", directoryHint: .isDirectory)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)

        // UUID prefix avoids filename collisions; preserve original extension
        let filename = "\(UUID().uuidString).\(url.pathExtension)"
        let destination = dir.appending(component: filename, directoryHint: .notDirectory)
        try fm.copyItem(at: url, to: destination)
        print("[Import] Copied \(url.lastPathComponent) → \(destination.path)")
        return filename
    }

    // MARK: - Delete

    func delete(_ transcription: Transcription) {
        try? repository.delete(transcription)
        loadTranscriptions()
    }

    func deleteTranscriptions(offsets: IndexSet) {
        for index in offsets {
            try? repository.delete(transcriptions[index])
        }
        loadTranscriptions()
    }

    // MARK: - Allowed audio types

    static let audioContentTypes: [UTType] = [
        .mp3, .mpeg4Audio, .wav, UTType(filenameExtension: "m4a")!
    ]
}
