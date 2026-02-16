//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import SwiftUI
import SwiftData
#if os(macOS)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var incomingURLHandler: ((URL) -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register self as the services provider so transcribeAudio(_:userData:error:) is called
        NSApplication.shared.servicesProvider = self
        NSUpdateDynamicServices()
    }

    @objc func transcribeAudio(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>?) {
        guard let items = pasteboard.pasteboardItems else { return }
        for item in items {
            if let urlString = item.string(forType: .fileURL),
               let url = URL(string: urlString) {
                incomingURLHandler?(url)
            }
        }
    }
}
#endif

@main
struct TranscribeApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Transcription.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema has changed — delete the old store and start fresh
            let storeURL = modelConfiguration.url
            print("[SwiftData] Migration failed, deleting store at \(storeURL): \(error)")
            try? FileManager.default.removeItem(at: storeURL)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after store reset: \(error)")
            }
        }
    }()

    private let appSettings = AppSettings.shared
    @State private var isLaunching = true
    @State private var incomingURL: URL? = nil

    var body: some Scene {
        WindowGroup {
            ZStack {
                TranscriptionListView(incomingURL: $incomingURL)
                    .environment(appSettings)
                    .environment(TranscriptionService.shared)
                    .environment(SummarizationService.shared)
                    .modifier(OnboardingCoverModifier(appSettings: appSettings))

                if isLaunching {
                    LaunchScreenView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(appSettings.forceDarkMode ? .dark : nil)
            .task {
                // Start loading the model in the background immediately on launch,
                // so the pipeline is ready by the time the user imports a file.
                if appSettings.isModelDownloaded {
                    await TranscriptionService.shared.load()
                }
                // Brief delay to show launch screen, then fade out
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.easeOut(duration: 0.4)) {
                    isLaunching = false
                }
            }
            .onOpenURL { url in
                incomingURL = url
            }
#if os(macOS)
            .onAppear {
                appDelegate.incomingURLHandler = { url in
                    incomingURL = url
                }
            }
#endif
        }
        .modelContainer(sharedModelContainer)
    }
}
