//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI

struct TranscriptionRowView: View {
    let transcription: Transcription

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transcription.sourceType == .recording ? "mic.fill" : "waveform")
                .resizable()
                .scaledToFit()
#if os(macOS)
                .frame(width: 22, height: 22)
                .padding(8)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
#else
                .frame(width: 28, height: 28)
#endif
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(transcription.title ?? transcription.audioFileURL.deletingPathExtension().lastPathComponent)
#if os(macOS)
                    .font(.body.weight(.semibold))
#else
                    .font(.headline)
#endif
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(transcription.createdAt, style: .date)
                    if let duration = transcription.duration {
                        Text("·")
                        Text(Duration.seconds(duration).formatted(.time(pattern: .minuteSecond)) + " min")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            #if os(macOS)
            Spacer()
            #endif
        }
#if os(macOS)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
#else
        .padding(.vertical, 4)
#endif
    }
}
