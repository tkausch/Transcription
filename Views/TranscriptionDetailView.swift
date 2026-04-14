//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI

// MARK: - Detail View

struct TranscriptionDetailView: View {
    @Bindable var transcription: Transcription
    var onRetry: (() -> Void)? = nil

    @State private var audioPlayer = AudioPlayerViewModel()
    @State private var isTranscriptionExpanded = true

    private func loadAudio() {
        if FileManager.default.fileExists(atPath: transcription.audioFileURL.path) {
            audioPlayer.load(url: transcription.audioFileURL)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // MARK: Date and Duration
                HStack(spacing: 4) {
                    Text(transcription.createdAt, style: .date)
                    if let duration = transcription.duration {
                        Text("·")
                        Text(Duration.seconds(duration).formatted(.time(pattern: .minuteSecond)) + " min")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                // MARK: Audio Player Section
                if !transcription.isTranscribing {
                    if FileManager.default.fileExists(atPath: transcription.audioFileURL.path) {
                        AudioPlayerView(vm: audioPlayer)
                    } else {
                        Text("Audio file not available.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                }

                // MARK: Summary Section
                if !transcription.isTranscribing {
                    SummaryView(transcription: transcription)

                    Divider()
                }

                // MARK: Transcription Section
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        withAnimation {
                            isTranscriptionExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: isTranscriptionExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text({
                                var title = "Transcription"
                                if let language = transcription.language {
                                    title += " (\(language))"
                                }
                                return title
                            }())
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            if let text = transcription.text, !text.isEmpty, !transcription.isTranscribing {
                                Button {
                                    #if os(iOS)
                                    UIPasteboard.general.string = text
                                    #else
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(text, forType: .string)
                                    #endif
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .labelStyle(.iconOnly)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .help("Copy transcript to clipboard")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if isTranscriptionExpanded {
                        TranscriptionTextContent(transcription: transcription, onRetry: onRetry)
                            .padding(.top, 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(transcription.title ?? "Transcription")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .id(transcription.id)
        .onAppear {
            loadAudio()
        }
        .onDisappear {
            audioPlayer.stop()
        }
        .onChange(of: transcription.id) {
            audioPlayer.stop()
            loadAudio()
        }
        .onChange(of: transcription.isTranscribing) { _, isTranscribing in
            // Reload audio once transcription finishes — file may not have existed on onAppear
            if !isTranscribing {
                loadAudio()
            }
        }
    }
}
