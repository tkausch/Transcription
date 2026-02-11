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

    var body: some Scene {
        WindowGroup {
            TranscriptionListView()
                .environment(appSettings)
                .environment(TranscriptionService.shared)
                .environment(SummarizationService.shared)
                .modifier(OnboardingCoverModifier(appSettings: appSettings))
        }
        .modelContainer(sharedModelContainer)
    }
}
