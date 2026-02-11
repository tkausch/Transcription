//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import Foundation
import FoundationModels
import Observation

@Observable
@MainActor
final class SummarizationService {

    static let shared = SummarizationService()

    enum State: Equatable {
        case unavailable
        case available
        case summarizing
    }

    private(set) var state: State

    private init() {
        state = SystemLanguageModel.default.isAvailable ? .available : .unavailable
    }

    // MARK: - Summarize

    /// Max characters per chunk. ~4 chars/token, 4096 token limit, minus headroom for system prompt and prefix.
    private static let chunkSize = 10_000

    /// Generates a summary for the transcription text and updates the model object directly.
    /// For long transcripts the text is split into chunks, each chunk is summarized separately,
    /// and the chunk summaries are then merged into a final summary.
    func summarize(_ transcription: Transcription) async {
        guard case .available = state else { return }
        guard let fullText = transcription.text, !fullText.isEmpty else { return }

        state = .summarizing
        transcription.summary = nil

        defer {
            state = .available
        }

        do {
            let chunks = split(fullText, chunkSize: Self.chunkSize)
            print("[SummarizationService] Summarizing \(chunks.count) chunk(s) for transcript of \(fullText.count) characters.")

            let chunkSummaries: [String]
            if chunks.count == 1 {
                // Single chunk — summarize directly.
                chunkSummaries = [try await summarizeChunk(chunks[0])]
            } else {
                // Multiple chunks — summarize each independently.
                var summaries: [String] = []
                for (index, chunk) in chunks.enumerated() {
                    print("[SummarizationService] Summarizing chunk \(index + 1)/\(chunks.count)…")
                    summaries.append(try await summarizeChunk(chunk))
                }
                chunkSummaries = summaries
            }

            // If we have multiple chunk summaries, merge them into a final summary.
            if chunkSummaries.count == 1 {
                transcription.summary = chunkSummaries[0]
            } else {
                transcription.summary = try await mergeSummaries(chunkSummaries)
            }
        } catch {
            print("[SummarizationService] Failed to generate summary: \(error)")
        }
    }

    // MARK: - Private helpers

    /// Splits text into chunks of at most `chunkSize` characters, breaking on whitespace boundaries.
    private func split(_ text: String, chunkSize: Int) -> [String] {
        guard text.count > chunkSize else { return [text] }
        var chunks: [String] = []
        var remaining = text[text.startIndex...]
        while !remaining.isEmpty {
            if remaining.count <= chunkSize {
                chunks.append(String(remaining))
                break
            }
            let end = remaining.index(remaining.startIndex, offsetBy: chunkSize)
            // Try to break on the last whitespace before the cut-off.
            if let breakPoint = remaining[..<end].lastIndex(where: { $0.isWhitespace }) {
                chunks.append(String(remaining[..<breakPoint]))
                remaining = remaining[remaining.index(after: breakPoint)...]
            } else {
                chunks.append(String(remaining[..<end]))
                remaining = remaining[end...]
            }
        }
        return chunks
    }

    /// Summarizes a single chunk of text using a fresh session.
    private func summarizeChunk(_ chunk: String) async throws -> String {
        let session = LanguageModelSession(instructions: """
            You are a concise summarizer. Given a portion of a spoken audio transcript, \
            produce a short summary of 2-4 sentences capturing the key points. \
            Respond only with the summary text, no preamble.
            """)
        let response = try await session.respond(to: "Summarize the following transcript excerpt:\n\n\(chunk)")
        return response.content
    }

    /// Merges multiple chunk summaries into a single cohesive summary using a fresh session.
    private func mergeSummaries(_ summaries: [String]) async throws -> String {
        let combined = summaries.enumerated()
            .map { "Part \($0.offset + 1):\n\($0.element)" }
            .joined(separator: "\n\n")
        let session = LanguageModelSession(instructions: """
            You are a concise summarizer. You will receive several partial summaries of a \
            spoken audio transcript. Combine them into a single cohesive summary of 3-5 sentences. \
            Respond only with the final summary text, no preamble.
            """)
        let response = try await session.respond(to: "Combine these partial summaries into one:\n\n\(combined)")
        return response.content
    }
}
