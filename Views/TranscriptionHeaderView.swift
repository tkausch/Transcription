//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI

struct TranscriptionHeaderView: View {
    let transcription: Transcription

    var body: some View {
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
    }
}
