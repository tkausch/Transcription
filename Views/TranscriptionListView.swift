//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI
import SwiftData
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct TranscriptionListView: View {

    @Binding var incomingURL: URL?

    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.openURL) private var openURL
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
            .navigationTitle("Recordings")
            .toolbar { toolbarItems(vm: vm) }
            .navigationDestination(isPresented: Bindable(vm).showSettings) {
                SettingsView()
            }
            .sheet(isPresented: Bindable(vm).showVoiceRecording) {
                VoiceRecordingView(modelContext: modelContext) { transcription in
                    vm.onRecordingComplete(transcription)
                }
            }
            // Push detail on iPhone when selection is set programmatically
            .navigationDestination(for: Transcription.self) { transcription in
                TranscriptionDetailView(transcription: transcription) {
                    vm.retryTranscription(for: transcription)
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 300, ideal: 320)
#endif
        } detail: {
            if let transcription = vm.selectedTranscription {
                TranscriptionDetailView(transcription: transcription) {
                    vm.retryTranscription(for: transcription)
                }
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
        .onChange(of: incomingURL) { _, url in
            guard let url else { return }
            
            // Handle custom URL scheme from Share Extension
            if url.scheme == "transcribe" {
                handleCustomURL(url, vm: vm)
            } else {
                // Handle direct file URLs
                vm.importAudioFile(url: url)
            }
            
            incomingURL = nil
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Recordings", systemImage: "waveform.badge.plus")
        } description: {
            Text("Open a file or start a new recording to get started.")
        }
    }
    
    private func transcriptionRow(transcription: Transcription, vm: TranscriptionListViewModel) -> some View {
        NavigationLink(value: transcription) {
            TranscriptionRowView(transcription: transcription)
        }
        .tag(transcription)
#if os(macOS)
        .listRowSeparator(.visible)
        .alignmentGuide(.listRowSeparatorLeading) { d in d[.leading] + 50 }
#else
        .listRowSeparator(.hidden)
#endif
        .contextMenu {
            Button(role: .destructive) {
                vm.delete(transcription)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func list(vm: TranscriptionListViewModel) -> some View {
        List(selection: Bindable(vm).selectedTranscription) {
            if !vm.importedTranscriptions.isEmpty {
                Section {
                    ForEach(vm.importedTranscriptions, id: \.id) { transcription in
                        transcriptionRow(transcription: transcription, vm: vm)
                    }
                    .onDelete(perform: vm.deleteImportedTranscriptions)
                } header: {
                    Text("Imported Audio")
                }
            }
            
            if !vm.recordedTranscriptions.isEmpty {
                Section {
                    ForEach(vm.recordedTranscriptions, id: \.id) { transcription in
                        transcriptionRow(transcription: transcription, vm: vm)
                    }
                    .onDelete(perform: vm.deleteRecordedTranscriptions)
                } header: {
                    Text("Voice Recordings")
                }
            }
        }
#if os(macOS)
        .listStyle(.inset)
#endif
#if os(macOS)
        .onDeleteCommand {
            if let selected = vm.selectedTranscription {
                vm.delete(selected)
            }
        }
#endif
    }

    // MARK: - Actions
    
    private func handleCustomURL(_ url: URL, vm: TranscriptionListViewModel) {
        // Parse the custom URL scheme: transcribe://open?path=<encoded-url>
        guard url.host == "open",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let pathItem = queryItems.first(where: { $0.name == "path" }),
              let encodedPath = pathItem.value,
              let decodedPath = encodedPath.removingPercentEncoding,
              let fileURL = URL(string: decodedPath) else {
            print("[TranscriptionListView] Failed to parse custom URL: \(url)")
            return
        }
        
        print("[TranscriptionListView] Received file from Share Extension: \(fileURL.path)")
        vm.importAudioFile(url: fileURL)
    }

    private func openVoiceRecording(vm: TranscriptionListViewModel) {
#if os(macOS)
        // On macOS, open Voice Memos app
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: "/System/Applications/VoiceMemos.app"),
            configuration: NSWorkspace.OpenConfiguration()
        )
#else
        // On iOS, show built-in voice recording screen
        vm.showVoiceRecording = true
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
                Label("Open Audio File", systemImage: "folder.badge.plus")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                openVoiceRecording(vm: vm)
            } label: {
                Label("Record", systemImage: "mic")
            }
        }
    }
}

#Preview {
    TranscriptionListView(incomingURL: .constant(nil))
        .modelContainer(for: Transcription.self, inMemory: true)
        .environment(AppSettings.shared)
}
