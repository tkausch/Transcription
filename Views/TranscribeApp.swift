//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI
import SwiftData

@main
struct TranscribeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transcription.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private let appSettings = AppSettings.shared
    @State private var isLaunching = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                TranscriptionListView()
                    .environment(appSettings)
                    .environment(TranscriptionService.shared)
                    .environment(SummarizationService.shared)
                    .modifier(OnboardingCoverModifier(appSettings: appSettings))

                if isLaunching {
                    LaunchScreenView()
                        .transition(.opacity)
                }
            }
            .task {
                // Brief delay to show launch screen, then fade out
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.easeOut(duration: 0.4)) {
                    isLaunching = false
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
