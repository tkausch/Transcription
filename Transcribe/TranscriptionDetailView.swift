//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI

struct TranscriptionDetailView: View {
    let transcription: Transcription

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transcription.title ?? transcription.audioFileURL.lastPathComponent)
                        .font(.title2)
                        .bold()
                    HStack(spacing: 12) {
                        Label(transcription.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        if let duration = transcription.duration {
                            Label(Duration.seconds(duration).formatted(.units(allowed: [.minutes, .seconds])), systemImage: "clock")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Divider()

                if let text = transcription.text, !text.isEmpty {
                    Text(text)
                        .font(.body)
                        .textSelection(.enabled)
                } else {
                    ContentUnavailableView {
                        Label("No Transcription", systemImage: "waveform")
                    } description: {
                        Text("The transcription for this recording is not available yet.")
                    }
                }
            }
            .padding()
        }
        .navigationTitle(transcription.audioFileURL.lastPathComponent)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
