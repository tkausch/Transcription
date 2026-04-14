//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class VoiceRecordingViewModel {
    
    private(set) var recorder = AudioRecorderService()
    var showPermissionAlert = false
    var showErrorAlert = false
    private(set) var errorMessage: String?
    
    private let repository: TranscriptionRepository
    private let onRecordingComplete: (Transcription) -> Void
    
    init(modelContext: ModelContext, onRecordingComplete: @escaping (Transcription) -> Void) {
        self.repository = TranscriptionRepository(modelContext: modelContext)
        self.onRecordingComplete = onRecordingComplete
    }
    
    // MARK: - Computed Properties
    
    var statusText: String {
        switch recorder.state {
        case .idle:
            return "Tap to start recording"
        case .recording:
            return "Recording..."
        case .paused:
            return "Paused"
        case .stopped:
            return "Stopped"
        }
    }
    
    var formattedTime: String {
        let minutes = Int(recorder.currentTime) / 60
        let seconds = Int(recorder.currentTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func barHeight(for index: Int) -> CGFloat {
        guard recorder.state == .recording else {
            return 20 + CGFloat.random(in: -5...5)
        }
        
        // Create animated waveform effect
        let baseHeight: CGFloat = 20
        let variation = CGFloat(recorder.audioLevel) * 60
        let offset = CGFloat(index) * 0.1
        let wave = sin(recorder.currentTime * 5 + offset) * variation
        
        return max(baseHeight, baseHeight + wave)
    }
    
    // MARK: - Actions
    
    func startRecording() {
        Task {
            // Check permission
            if !recorder.hasPermission {
                let granted = await recorder.requestPermission()
                if !granted {
                    showPermissionAlert = true
                    return
                }
                recorder.checkPermission()
            }
            
            // Start recording
            do {
                _ = try recorder.startRecording()
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    func pauseRecording() {
        recorder.pauseRecording()
    }
    
    func resumeRecording() {
        recorder.resumeRecording()
    }
    
    func stopRecording(onDismiss: @escaping () -> Void) {
        guard let url = recorder.stopRecording() else {
            errorMessage = "Failed to save recording"
            showErrorAlert = true
            return
        }
        
        // Create transcription object with source = .recording
        let filename = url.lastPathComponent
        let transcription = Transcription(audioFilename: filename, source: .recording)
        
        // Use formatted date and time as title for voice recordings
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        transcription.title = dateFormatter.string(from: Date())
        
        transcription.originalFilename = filename
        
        print("[VoiceRecording] Created transcription with source: \(transcription.source)")
        
        do {
            try repository.save(transcription)
            print("[VoiceRecording] Saved transcription - source after save: \(transcription.source)")
            onRecordingComplete(transcription)
            onDismiss()
        } catch {
            errorMessage = "Failed to save recording: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    func cancelRecording(onDismiss: @escaping () -> Void) {
        recorder.cancelRecording()
        onDismiss()
    }
}
