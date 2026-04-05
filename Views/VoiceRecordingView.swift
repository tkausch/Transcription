//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import SwiftUI
import SwiftData

struct VoiceRecordingView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var recorder = AudioRecorderService()
    @State private var showPermissionAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String?
    
    private let repository: TranscriptionRepository
    private let onRecordingComplete: (Transcription) -> Void
    
    init(modelContext: ModelContext, onRecordingComplete: @escaping (Transcription) -> Void) {
        self.repository = TranscriptionRepository(modelContext: modelContext)
        self.onRecordingComplete = onRecordingComplete
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Level meter with waveform visualization
                levelMeter
                
                // Elapsed time
                timeDisplay
                
                Spacer()
                
                // Recording controls
                recordingControls
                
                Spacer()
            }
            .padding()
            .navigationTitle("Voice Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        recorder.cancelRecording()
                        dismiss()
                    }
                    .disabled(recorder.state == .idle)
                }
            }
            .alert("Microphone Permission Required", isPresented: $showPermissionAlert) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable microphone access in Settings to record audio.")
            }
            .alert("Recording Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var levelMeter: some View {
        VStack(spacing: 16) {
            // Waveform visualization
            HStack(spacing: 4) {
                ForEach(0..<50, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(recorder.state == .recording ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: 3, height: barHeight(for: index))
                        .animation(.easeInOut(duration: 0.1), value: recorder.audioLevel)
                }
            }
            .frame(height: 100)
            
            // Status text
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var timeDisplay: some View {
        Text(formattedTime)
            .font(.system(size: 48, weight: .light, design: .monospaced))
            .monospacedDigit()
    }
    
    private var recordingControls: some View {
        HStack(spacing: 40) {
            if recorder.state == .idle {
                // Record button
                Button {
                    startRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 80, height: 80)
                        Image(systemName: "mic.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                    }
                }
            } else if recorder.state == .recording {
                // Pause button
                Button {
                    recorder.pauseRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 80, height: 80)
                        Image(systemName: "pause.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                    }
                }
                
                // Stop button
                Button {
                    stopRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 80, height: 80)
                        Image(systemName: "stop.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                    }
                }
            } else if recorder.state == .paused {
                // Resume button
                Button {
                    recorder.resumeRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 80, height: 80)
                        Image(systemName: "mic.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                    }
                }
                
                // Stop button
                Button {
                    stopRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 80, height: 80)
                        Image(systemName: "stop.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var statusText: String {
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
    
    private var formattedTime: String {
        let minutes = Int(recorder.currentTime) / 60
        let seconds = Int(recorder.currentTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func barHeight(for index: Int) -> CGFloat {
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
    
    private func startRecording() {
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
    
    private func stopRecording() {
        guard let url = recorder.stopRecording() else {
            errorMessage = "Failed to save recording"
            showErrorAlert = true
            return
        }
        
        // Create transcription object with source = .recording
        let filename = url.lastPathComponent
        let transcription = Transcription(audioFilename: filename, source: .recording)
        transcription.title = "Voice Recording"
        transcription.originalFilename = filename
        
        do {
            try repository.save(transcription)
            onRecordingComplete(transcription)
            dismiss()
        } catch {
            errorMessage = "Failed to save recording: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

#Preview {
    VoiceRecordingView(
        modelContext: ModelContext(
            try! ModelContainer(for: Transcription.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        ),
        onRecordingComplete: { _ in }
    )
}
