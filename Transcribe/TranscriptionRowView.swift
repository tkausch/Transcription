//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI

struct TranscriptionRowView: View {
    let transcription: Transcription

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(transcription.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(transcription.audioFileURL.lastPathComponent)
                .font(.headline)
                .lineLimit(1)

            if let text = transcription.text, !text.isEmpty {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            } else {
                Text("No transcription yet.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}
