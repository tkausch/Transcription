//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.

import Foundation
import UniformTypeIdentifiers

#if os(iOS)
import UIKit

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        processSharedItem()
    }
    
    private func processSharedItem() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            cancelRequest(message: "No audio file shared")
            return
        }

        if itemProvider.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
            handleAudioFile(itemProvider)
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            handleFileURL(itemProvider)
        } else {
            cancelRequest(message: "Please share an audio file")
        }
    }

    private func handleAudioFile(_ itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: UTType.audio.identifier, options: nil) { [weak self] (item, error) in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.cancelRequest(message: "Failed to load audio file: \(error.localizedDescription)")
                }
                return
            }

            guard let url = item as? URL else {
                DispatchQueue.main.async {
                    self.cancelRequest(message: "Invalid audio file")
                }
                return
            }

            DispatchQueue.main.async {
                self.openInMainApp(url: url)
            }
        }
    }

    private func handleFileURL(_ itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] (item, error) in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.cancelRequest(message: "Failed to load file: \(error.localizedDescription)")
                }
                return
            }

            guard let url = item as? URL else {
                DispatchQueue.main.async {
                    self.cancelRequest(message: "Invalid file")
                }
                return
            }

            let audioExtensions = ["mp3", "m4a", "wav", "aiff", "aif", "ogg", "flac"]
            guard audioExtensions.contains(url.pathExtension.lowercased()) else {
                DispatchQueue.main.async {
                    self.cancelRequest(message: "Please share an audio file")
                }
                return
            }

            DispatchQueue.main.async {
                self.openInMainApp(url: url)
            }
        }
    }

    private func openInMainApp(url: URL) {
        let encodedPath = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let appURL = URL(string: "transcribe://open?path=\(encodedPath)") else {
            cancelRequest(message: "Failed to create app URL")
            return
        }

        // Use extensionContext to open URL in the containing app
        extensionContext?.open(appURL, completionHandler: { [weak self] success in
            if success {
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            } else {
                self?.cancelRequest(message: "Failed to open main app")
            }
        })
    }

    private func cancelRequest(message: String) {
        let error = NSError(
            domain: "com.transcribe.shareextension",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        extensionContext?.cancelRequest(withError: error)
    }
}

#else
import AppKit

class ShareViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        processSharedItem()
    }
    
    private func processSharedItem() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            cancelRequest(message: "No audio file shared")
            return
        }

        if itemProvider.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
            handleAudioFile(itemProvider)
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            handleFileURL(itemProvider)
        } else {
            cancelRequest(message: "Please share an audio file")
        }
    }

    private func handleAudioFile(_ itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: UTType.audio.identifier, options: nil) { [weak self] (item, error) in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.cancelRequest(message: "Failed to load audio file: \(error.localizedDescription)")
                }
                return
            }

            guard let url = item as? URL else {
                DispatchQueue.main.async {
                    self.cancelRequest(message: "Invalid audio file")
                }
                return
            }

            DispatchQueue.main.async {
                self.openInMainApp(url: url)
            }
        }
    }

    private func handleFileURL(_ itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] (item, error) in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.cancelRequest(message: "Failed to load file: \(error.localizedDescription)")
                }
                return
            }

            guard let url = item as? URL else {
                DispatchQueue.main.async {
                    self.cancelRequest(message: "Invalid file")
                }
                return
            }

            let audioExtensions = ["mp3", "m4a", "wav", "aiff", "aif", "ogg", "flac"]
            guard audioExtensions.contains(url.pathExtension.lowercased()) else {
                DispatchQueue.main.async {
                    self.cancelRequest(message: "Please share an audio file")
                }
                return
            }

            DispatchQueue.main.async {
                self.openInMainApp(url: url)
            }
        }
    }

    private func openInMainApp(url: URL) {
        let encodedPath = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let appURL = URL(string: "transcribe://open?path=\(encodedPath)") else {
            cancelRequest(message: "Failed to create app URL")
            return
        }

        NSWorkspace.shared.open(appURL)
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    private func cancelRequest(message: String) {
        let error = NSError(
            domain: "com.transcribe.shareextension",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        extensionContext?.cancelRequest(withError: error)
    }
}
#endif
