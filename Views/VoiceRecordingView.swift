//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import SwiftUI
import SwiftData

struct VoiceRecordingView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel: VoiceRecordingViewModel
    
    init(modelContext: ModelContext, onRecordingComplete: @escaping (Transcription) -> Void) {
        self._viewModel = State(wrappedValue: VoiceRecordingViewModel(
            modelContext: modelContext,
            onRecordingComplete: onRecordingComplete
        ))
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelRecording { dismiss() }
                    }
                    .disabled(viewModel.recorder.state == .idle)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if viewModel.recorder.state != .idle && viewModel.recorder.state != .stopped {
                            viewModel.stopRecording { dismiss() }
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Microphone Permission Required", isPresented: $viewModel.showPermissionAlert) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                #if os(iOS)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                #endif
            } message: {
                Text("Please enable microphone access in Settings to record audio.")
            }
            .alert("Recording Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred.")
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
                        .fill(viewModel.recorder.state == .recording ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: 3, height: viewModel.barHeight(for: index))
                        .animation(.easeInOut(duration: 0.1), value: viewModel.recorder.audioLevel)
                }
            }
            .frame(height: 100)
            
            // Status text
            Text(viewModel.statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var timeDisplay: some View {
        Text(viewModel.formattedTime)
            .font(.system(size: 48, weight: .light, design: .monospaced))
            .monospacedDigit()
    }
    
    private var recordingControls: some View {
        HStack(spacing: 40) {
            if viewModel.recorder.state == .idle {
                // Record button
                Button {
                    viewModel.startRecording()
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
            } else if viewModel.recorder.state == .recording {
                // Pause button
                Button {
                    viewModel.pauseRecording()
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
                    viewModel.stopRecording { dismiss() }
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
            } else if viewModel.recorder.state == .paused {
                // Resume button
                Button {
                    viewModel.resumeRecording()
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
                    viewModel.stopRecording { dismiss() }
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
}

#Preview {
    VoiceRecordingView(
        modelContext: ModelContext(
            try! ModelContainer(for: Transcription.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        ),
        onRecordingComplete: { _ in }
    )
}
