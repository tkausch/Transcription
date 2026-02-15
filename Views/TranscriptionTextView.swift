//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI

struct TranscriptionTextView: View {
    @Bindable var transcription: Transcription

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Transcription")
                    .font(.headline)
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

            if transcription.isTranscribing {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: transcription.transcriptionProgress)
                    Text("Transcribing… \(Int(transcription.transcriptionProgress * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            } else if let text = transcription.text, !text.isEmpty {
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
    }
}
