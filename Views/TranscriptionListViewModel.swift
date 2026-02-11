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
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let destination = try copyToAudioStore(url: url)
            let transcription = Transcription(audioFileURL: destination)
            transcription.title = url.deletingPathExtension().lastPathComponent
            try repository.save(transcription)
            loadTranscriptions()
            selectedTranscription = transcription
            Task { await startTranscription(for: transcription) }
        } catch {
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

    private func copyToAudioStore(url: URL) throws -> URL {
        let dir = URL.applicationSupportDirectory
            .appending(component: "AudioFiles", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let destination = dir.appending(component: url.lastPathComponent, directoryHint: .notDirectory)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: url, to: destination)
        return destination
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
