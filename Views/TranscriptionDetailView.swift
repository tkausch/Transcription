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
                TranscriptionHeaderView(transcription: transcription)

                Divider()

                // MARK: Summary Section
                SummaryView(transcription: transcription)

                Divider()

                // MARK: Transcription Section
                TranscriptionTextView(transcription: transcription)

                Divider()

                // MARK: Info Section
                Text("Info")
                    .font(.headline)

                TranscriptionInfoView(transcription: transcription)

                Divider()

                // MARK: Audio Player Section
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
            .padding()
        }
        .navigationTitle(transcription.audioFileURL.lastPathComponent)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
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
    }
}
