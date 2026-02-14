//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI

struct TranscriptionInfoView: View {
    let transcription: Transcription

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 8) {
            GridRow {
                Text("File")
                    .foregroundStyle(.secondary)
                Text(transcription.originalFilename ?? "—")
                    .textSelection(.enabled)
            }
            GridRow {
                Text("Language")
                    .foregroundStyle(.secondary)
                Text(transcription.language ?? "—")
            }
            GridRow {
                Text("Duration")
                    .foregroundStyle(.secondary)
                if let duration = transcription.duration {
                    Text(Duration.seconds(duration).formatted(.units(allowed: [.hours, .minutes, .seconds])))
                } else {
                    Text("—")
                }
            }
            GridRow {
                Text("Created")
                    .foregroundStyle(.secondary)
                Text(transcription.createdAt.formatted(date: .long, time: .shortened))
            }
        }
        .font(.subheadline)
    }
}
