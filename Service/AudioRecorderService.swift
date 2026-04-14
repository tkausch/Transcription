//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class AudioRecorderService: NSObject {
    
    enum RecordingState {
        case idle
        case recording
        case paused
        case stopped
    }
    
    private(set) var state: RecordingState = .idle
    private(set) var currentTime: TimeInterval = 0
    private(set) var audioLevel: Float = 0
    private(set) var hasPermission: Bool = false
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingURL: URL?
    
    override init() {
        super.init()
        checkPermission()
    }
    
    // MARK: - Permission
    
    func checkPermission() {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                hasPermission = true
            case .denied, .undetermined:
                hasPermission = false
            @unknown default:
                hasPermission = false
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                hasPermission = true
            case .denied, .undetermined:
                hasPermission = false
            @unknown default:
                hasPermission = false
            }
        }
        #else
        // On macOS, microphone permission is handled by the system
        // The app will be granted permission automatically when Info.plist has NSMicrophoneUsageDescription
        hasPermission = true
        #endif
    }
    
    func requestPermission() async -> Bool {
        #if os(iOS)
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        #else
        // On macOS, permission is handled automatically by the system
        return true
        #endif
    }
    
    // MARK: - Recording Controls
    
    func startRecording() throws -> URL {
        // Request permission if needed
        guard hasPermission else {
            throw RecordingError.permissionDenied
        }
        
        #if os(iOS)
        // Setup audio session (iOS only)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
        #endif
        
        // Create recording URL and ensure directory exists
        let filename = "\(UUID().uuidString).m4a"
        let directory = try AudioFileStore.directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = try AudioFileStore.url(for: filename)
        recordingURL = url
        print("[AudioRecorder] Recording to: \(url.path)")
        
        // Configure recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Create and start recorder
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
        
        state = .recording
        currentTime = 0
        startTimer()
        
        return url
    }
    
    func pauseRecording() {
        audioRecorder?.pause()
        state = .paused
        stopTimer()
    }
    
    func resumeRecording() {
        audioRecorder?.record()
        state = .recording
        startTimer()
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        state = .stopped
        stopTimer()
        
        let url = recordingURL
        recordingURL = nil
        
        #if os(iOS)
        // Deactivate audio session (iOS only)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
        
        return url
    }
    
    func cancelRecording() {
        audioRecorder?.stop()
        state = .idle
        stopTimer()
        
        // Delete the recording file
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        recordingURL = nil
        currentTime = 0
        audioLevel = 0
        
        #if os(iOS)
        // Deactivate audio session (iOS only)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }
    
    // MARK: - Timer & Metering
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMeters()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateMeters() {
        guard let recorder = audioRecorder else { return }
        
        recorder.updateMeters()
        currentTime = recorder.currentTime
        
        // Get average power for the channel (0 = first channel)
        let averagePower = recorder.averagePower(forChannel: 0)
        
        // Convert dB to linear scale (0.0 to 1.0)
        // -160 dB is silence, 0 dB is max
        let normalizedLevel = max(0.0, (averagePower + 160.0) / 160.0)
        audioLevel = normalizedLevel
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if flag {
                state = .stopped
            } else {
                state = .idle
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            state = .idle
            print("[AudioRecorder] Encoding error: \(error?.localizedDescription ?? "unknown")")
        }
    }
}

// MARK: - Errors

enum RecordingError: LocalizedError {
    case permissionDenied
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return String(localized: "Microphone access is required to record audio. Please enable it in Settings.")
        case .recordingFailed:
            return String(localized: "Failed to start recording. Please try again.")
        }
    }
}
