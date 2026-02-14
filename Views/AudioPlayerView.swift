//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI
import AVFoundation
#if os(iOS)
import AVKit
#endif

// MARK: - Audio Player ViewModel

@Observable
@MainActor
final class AudioPlayerViewModel {
    private var player: AVPlayer?
    private var timeObserver: Any?

    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0

    var scrubTime: Double = 0

    private var loadedURL: URL?

    func load(url: URL) {
        guard url != loadedURL else { return }
        loadedURL = url
        stop()
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)

        // Observe duration once item is ready
        Task {
            do {
                let asset = AVURLAsset(url: url)
                let seconds = try await asset.load(.duration).seconds
                if seconds.isFinite { duration = seconds }
            } catch {}
        }

        // Observe current time every 0.25 s
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds
                self.scrubTime = time.seconds
            }
        }

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isPlaying = false
                self?.currentTime = 0
                self?.scrubTime = 0
                self?.player?.seek(to: .zero)
            }
        }
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
#if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .default)
            try? session.setActive(true)
#endif
            player.play()
            isPlaying = true
        }
    }

    func seek(to time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
        currentTime = time
    }

    func stop() {
        player?.pause()
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        player = nil
        loadedURL = nil
        isPlaying = false
    }
}

// MARK: - Audio Player View

struct AudioPlayerView: View {
    let vm: AudioPlayerViewModel

    private func formatted(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private var remaining: Double {
        guard vm.duration > 0 else { return 0 }
        return vm.duration - vm.currentTime
    }

    var body: some View {
        HStack(spacing: 12) {
            // Play / Pause button
            Button(action: { vm.togglePlayPause() }) {
                Image(systemName: vm.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)

            // Elapsed time
            Text(formatted(vm.currentTime))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 36, alignment: .trailing)

            // Scrubber
            Slider(
                value: Binding(
                    get: { vm.scrubTime },
                    set: { vm.seek(to: $0) }
                ),
                in: 0...(vm.duration > 0 ? vm.duration : 1)
            )

            // Remaining time
            Text("-" + formatted(remaining))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 40, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview {
    AudioPlayerView(vm: AudioPlayerViewModel())
        .padding()
}
