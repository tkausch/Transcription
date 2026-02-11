//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI
import SwiftData

struct TranscriptionListView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var appSettings
    @State private var viewModel: TranscriptionListViewModel?
    @State private var navigationPath: [Transcription] = []

    private func makeViewModel() -> TranscriptionListViewModel {
        TranscriptionListViewModel(modelContext: modelContext, appSettings: appSettings)
    }

    var body: some View {
        if let vm = viewModel {
            content(vm: vm)
        } else {
            Color.clear.task {
                let vm = makeViewModel()
                viewModel = vm
                vm.onAppear()
            }
        }
    }

    @ViewBuilder
    private func content(vm: TranscriptionListViewModel) -> some View {
        NavigationSplitView {
            Group {
                if vm.transcriptions.isEmpty {
                    emptyState
                } else {
                    list(vm: vm)
                }
            }
            .navigationTitle("Transcriptions")
            .toolbar { toolbarItems(vm: vm) }
            .navigationDestination(isPresented: Bindable(vm).showSettings) {
                SettingsView()
            }
            // Push detail on iPhone when selection is set programmatically
            .navigationDestination(for: Transcription.self) { transcription in
                TranscriptionDetailView(transcription: transcription)
            }
        } detail: {
            if let transcription = vm.selectedTranscription {
                TranscriptionDetailView(transcription: transcription)
            } else {
                ContentUnavailableView {
                    Label("No Selection", systemImage: "waveform")
                } description: {
                    Text("Select a transcription from the list.")
                }
            }
        }
        .onChange(of: vm.selectedTranscription) { _, newValue in
            if let transcription = newValue {
                navigationPath = [transcription]
            }
        }
        .fileImporter(
            isPresented: Bindable(vm).showFilePicker,
            allowedContentTypes: TranscriptionListViewModel.audioContentTypes,
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                vm.importAudioFile(url: url)
            }
        }
        .alert("Import Failed", isPresented: Binding(
            get: { vm.importError != nil },
            set: { if !$0 { vm.importError = nil } }
        )) {
            Button("OK", role: .cancel) { vm.importError = nil }
        } message: {
            Text(vm.importError?.localizedDescription ?? "")
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Transcripts", systemImage: "waveform.badge.plus")
        } description: {
            Text("Open a file or start a new recording to get started.")
        }
    }

    private func list(vm: TranscriptionListViewModel) -> some View {
        List(selection: Bindable(vm).selectedTranscription) {
            ForEach(vm.transcriptions, id: \.id) { transcription in
                NavigationLink(value: transcription) {
                    TranscriptionRowView(transcription: transcription)
                }
                .tag(transcription)
                .contextMenu {
                    Button(role: .destructive) {
                        vm.delete(transcription)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDelete(perform: vm.deleteTranscriptions)
        }
#if os(macOS)
        .onDeleteCommand {
            if let selected = vm.selectedTranscription {
                vm.delete(selected)
            }
        }
#endif
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func toolbarItems(vm: TranscriptionListViewModel) -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                vm.showSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                vm.showFilePicker = true
            } label: {
                Label("Open Audio File", systemImage: "waveform.badge.plus")
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
}

#Preview {
    TranscriptionListView()
        .modelContainer(for: Transcription.self, inMemory: true)
        .environment(AppSettings.shared)
}
