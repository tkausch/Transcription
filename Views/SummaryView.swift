//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI
import SwiftData

struct SummaryView: View {
    @Bindable var transcription: Transcription

    @Environment(SummarizationService.self) private var summarizationService
    @Environment(\.modelContext) private var modelContext
    @State private var isSummarizing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Summary")
                    .font(.headline)
                Spacer()
                if let summary = transcription.summary, !summary.isEmpty {
                    // Copy button once summary exists
                    Button {
                        #if os(iOS)
                        UIPasteboard.general.string = summary
                        #else
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(summary, forType: .string)
                        #endif
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Copy summary to clipboard")
                } else if summarizationService.state != .unavailable,
                          let text = transcription.text, !text.isEmpty,
                          !transcription.isTranscribing {
                    // Summarize button when no summary yet
                    Button {
                        Task {
                            isSummarizing = true
                            await summarizationService.summarize(transcription)
                            try? modelContext.save()
                            isSummarizing = false
                        }
                    } label: {
                        Label("Summarize", systemImage: "sparkles")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .disabled(isSummarizing)
                    .help("Generate summary with Apple Intelligence")
                }
            }

            if isSummarizing {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Generating summary…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let summary = transcription.summary {
                Text(summary)
                    .font(.body)
                    .textSelection(.enabled)
            } else if summarizationService.state == .unavailable {
                Text("Apple Intelligence is not available on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Tap ✦ to generate a summary.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
