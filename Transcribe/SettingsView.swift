//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI
import WhisperKit

struct SettingsView: View {

    @Environment(AppSettings.self) private var appSettings

    @State private var availableModels: [String] = []
    @State private var isLoadingModels = false
    @State private var downloadState: DownloadState = .idle
    @State private var downloadProgress: Double = 0
    @State private var downloadMessage = ""
    @State private var errorMessage: String? = nil

    enum DownloadState {
        case idle, downloading, done, failed
    }

    var body: some View {
        Form {
            whisperModelsSection
            downloadSection
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
        .navigationTitle("Settings")
        .task { await loadAvailableModels() }
    }

    // MARK: - Whisper Models Section

    private var whisperModelsSection: some View {
        @Bindable var settings = appSettings
        return Section {
            if isLoadingModels {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading available models…")
                        .foregroundStyle(.secondary)
                }
            } else {
                Picker("Model", selection: $settings.selectedModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .onChange(of: settings.selectedModel) {
                    appSettings.isModelDownloaded = false
                    downloadState = .idle
                }
            }
        } header: {
            Text("Whisper Models")
        } footer: {
            Text("Larger models are more accurate but require more memory and take longer to download.")
        }
        .disabled(downloadState == .downloading)
    }

    // MARK: - Download Section

    private var downloadSection: some View {
        Section {
            // Status row
            switch downloadState {
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
                        Text("\(Int(downloadProgress * 100))%")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: downloadProgress)
                    Text(downloadMessage)
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
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Action row
            switch downloadState {
            case .idle:
                Button(appSettings.isModelDownloaded ? "Re-download" : "Download") {
                    Task { await downloadModel() }
                }
            case .downloading:
                EmptyView()
            case .done:
                Button("Re-download") {
                    Task { await downloadModel() }
                }
                .foregroundStyle(.secondary)
            case .failed:
                Button("Retry") {
                    Task { await downloadModel() }
                }
            }
        } header: {
            Text("Download")
        } footer: {
            Text("Keep the app open and in the foreground while the model is downloading. Sending the app to the background or closing it may interrupt the download.")
        }
    }

    // MARK: - Actions

    private func loadAvailableModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }
        availableModels = (try? await WhisperKit.fetchAvailableModels()) ?? []
        if !availableModels.contains(appSettings.selectedModel) {
            appSettings.selectedModel = AppSettings.defaultModel
        }
    }

    private func downloadModel() async {
        downloadState = .downloading
        downloadProgress = 0
        downloadMessage = "Preparing download…"
        errorMessage = nil

        do {
            _ = try await WhisperKit.download(
                variant: appSettings.selectedModel,
                progressCallback: { progress in
                    Task { @MainActor in
                        downloadProgress = progress.fractionCompleted
                        let completed = progress.completedUnitCount
                        let total = progress.totalUnitCount
                        downloadMessage = total > 0
                            ? "Downloading model files (\(completed) of \(total))…"
                            : "Downloading…"
                    }
                }
            )
            downloadProgress = 1
            downloadMessage = "Model ready."
            downloadState = .done
            appSettings.isModelDownloaded = true
        } catch {
            downloadState = .failed
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppSettings.shared)
}
