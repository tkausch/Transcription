//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import SwiftUI

struct SettingsView: View {

    @Environment(AppSettings.self) private var appSettings

    @State private var viewModel: SettingsViewModel?

    private func makeViewModel() -> SettingsViewModel {
        SettingsViewModel(appSettings: appSettings)
    }

    var body: some View {
        if let vm = viewModel {
            content(vm: vm)
        } else {
            Color.clear.onAppear {
                viewModel = makeViewModel()
            }
        }
    }

    private func content(vm: SettingsViewModel) -> some View {
        Form {
            whisperModelsSection(vm: vm)
            downloadSection(vm: vm)
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
        .navigationTitle("Settings")
    }

    // MARK: - Whisper Models Section

    private func whiskerModelsSection_disabled(_ vm: SettingsViewModel) -> Bool {
        vm.isDownloading
    }

    private func whisperModelsSection(vm: SettingsViewModel) -> some View {
        @Bindable var settings = appSettings
        return Section {
            Picker("Model", selection: $settings.selectedModel) {
                ForEach(SettingsViewModel.availableModels, id: \.self) { model in
                    Text(SettingsViewModel.displayName(for: model)).tag(model)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: settings.selectedModel) {
                vm.onModelChanged()
            }
        } header: {
            Text("Whisper Models")
        } footer: {
            Text("Larger models are more accurate but require more memory and take longer to download.")
        }
        .disabled(vm.isDownloading)
    }

    // MARK: - Download Section

    private func downloadSection(vm: SettingsViewModel) -> some View {
        Section {
            // Status row
            switch vm.downloadState {
            case .idle:
                if appSettings.isModelDownloaded {
                    Label("Model ready", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Not downloaded", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            case .downloading:
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Downloading…", systemImage: "arrow.down.circle")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(vm.downloadProgress * 100))%")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: vm.downloadProgress)
                    Text(vm.downloadMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .done:
                Label("Model ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed:
                VStack(alignment: .leading, spacing: 4) {
                    Label("Download failed", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Action row
            switch vm.downloadState {
            case .idle:
                Button(appSettings.isModelDownloaded ? "Re-download" : "Download") {
                    Task { await vm.downloadModel() }
                }
            case .downloading:
                EmptyView()
            case .done:
                Button("Re-download") {
                    Task { await vm.downloadModel() }
                }
                .foregroundStyle(.secondary)
            case .failed:
                Button("Retry") {
                    Task { await vm.downloadModel() }
                }
            }
        } header: {
            Text("Download")
        } footer: {
            Text("Keep the app open and in the foreground while the model is downloading. Sending the app to the background or closing it may interrupt the download.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppSettings.shared)
}
