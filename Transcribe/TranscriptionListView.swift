//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI
import SwiftData

struct TranscriptionListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var transcriptions: [Transcription] = []
    @State private var selectedTranscription: Transcription?
    @State private var showSettings = false

    private var repository: TranscriptionRepository {
        TranscriptionRepository(modelContext: modelContext)
    }

    var body: some View {
        NavigationSplitView {
            Group {
                if transcriptions.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Transcriptions")
            .toolbar { toolbarItems }
            .navigationDestination(isPresented: $showSettings) {
                Text("Settings").navigationTitle("Settings")
            }
        } detail: {
            if let transcription = selectedTranscription {
                TranscriptionDetailView(transcription: transcription)
            } else {
                ContentUnavailableView {
                    Label("No Selection", systemImage: "waveform")
                } description: {
                    Text("Select a transcription from the list.")
                }
            }
        }
        .task { loadTranscriptions() }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Transcripts", systemImage: "waveform.badge.plus")
        } description: {
            Text("Open a file or start a new recording to get started.")
        }
    }

    private var list: some View {
        List(selection: $selectedTranscription) {
            ForEach(transcriptions, id: \.id) { transcription in
                NavigationLink(value: transcription) {
                    TranscriptionRowView(transcription: transcription)
                }
                .tag(transcription)
            }
            .onDelete(perform: deleteTranscriptions)
        }
        .navigationDestination(for: Transcription.self) { transcription in
            TranscriptionDetailView(transcription: transcription)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                showSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                addSample()
            } label: {
                Label("New Transcription", systemImage: "waveform.badge.plus")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                // TODO: start recording
            } label: {
                Label("Record", systemImage: "mic")
            }
        }
    }

    // MARK: - Actions

    private func addSample() {
#if DEBUG
        let sample = repository.makeSampleTestTranscription()
        try? repository.save(sample)
        loadTranscriptions()
#endif
    }

    private func deleteTranscriptions(offsets: IndexSet) {
        for index in offsets {
            try? repository.delete(transcriptions[index])
        }
        loadTranscriptions()
    }

    private func loadTranscriptions() {
        transcriptions = (try? repository.fetchAll()) ?? []
        if let selected = selectedTranscription, !transcriptions.contains(where: { $0.id == selected.id }) {
            selectedTranscription = nil
        }
    }
}

#Preview {
    TranscriptionListView()
        .modelContainer(for: Transcription.self, inMemory: true)
}
