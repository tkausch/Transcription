//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI

// MARK: - Detail View

struct TranscriptionDetailView: View {
    @Bindable var transcription: Transcription

    @State private var audioPlayer = AudioPlayerViewModel()

    private func loadAudio() {
        if FileManager.default.fileExists(atPath: transcription.audioFileURL.path) {
            audioPlayer.load(url: transcription.audioFileURL)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: Summary Section
                if !transcription.isTranscribing {
                    SummaryView(transcription: transcription)

                    Divider()
                }

                // MARK: Transcription Section
                TranscriptionTextView(transcription: transcription)

                Divider()

                // MARK: Info Section
                Text("Info")
                    .font(.headline)

                TranscriptionInfoView(transcription: transcription)

                // MARK: Audio Player Section
                if !transcription.isTranscribing {
                    Divider()

                    Text("Audio")
                        .font(.headline)

                    if FileManager.default.fileExists(atPath: transcription.audioFileURL.path) {
                        AudioPlayerView(vm: audioPlayer)
                    } else {
                        Text("Audio file not available.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
        .onChange(of: transcription.isTranscribing) { _, isTranscribing in
            // Reload audio once transcription finishes — file may not have existed on onAppear
            if !isTranscribing {
                loadAudio()
            }
        }
    }
}
