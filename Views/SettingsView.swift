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
            appearanceSection()
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
        .navigationTitle("Settings")
        .alert("Download Model", isPresented: Bindable(vm).showDownloadConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Download") {
                Task { await vm.downloadModel() }
            }
        } message: {
            let modelSize = SettingsViewModel.modelSizes[appSettings.selectedModel] ?? "unknown size"
            Text("This will download \(modelSize) of data. Make sure you have a stable internet connection and sufficient storage space.")
        }
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
                    let name = SettingsViewModel.displayName(for: model)
                    let size = SettingsViewModel.modelSizes[model]
                    Text(size.map { "\(name) · \($0)" } ?? name).tag(model)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: settings.selectedModel) {
                vm.onModelChanged()
            }
        } header: {
            Text("Whisper Models")
        } footer: {
            Text("Larger models are more accurate but require more memory and take longer to download. Models ending in \".en\" are optimized for English-only audio and are faster and more accurate when English is the only language spoken.")
        }
        .disabled(vm.isDownloading)
    }

    // MARK: - Appearance Section

    private func appearanceSection() -> some View {
        @Bindable var settings = appSettings
        return Section {
            Toggle("Force Dark Mode", isOn: $settings.forceDarkMode)
        } header: {
            Text("Appearance")
        } footer: {
            Text("Override the system appearance and always use dark mode.")
        }
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
                    vm.requestDownload()
                }
            case .downloading:
                EmptyView()
            case .done:
                Button("Re-download") {
                    vm.requestDownload()
                }
                .foregroundStyle(.secondary)
            case .failed:
                Button("Retry") {
                    vm.requestDownload()
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
