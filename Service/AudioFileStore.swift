//
// This File belongs to SwiftRestEssentials 
// Copyright © 2026 Thomas Kausch.
// All Rights Reserved.


import Foundation

/// Centralises all audio file management for the app's persistent store.
///
/// Audio files are kept in `<Application Support>/AudioFiles/`.
/// Each file is stored under a UUID-prefixed name to avoid collisions.
struct AudioFileStore {

    // MARK: - Directory

    static var directory: URL {
        get throws {
            guard let appSupport = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw CocoaError(.fileNoSuchFile)
            }
            return appSupport.appending(component: "AudioFiles", directoryHint: .isDirectory)
        }
    }

    // MARK: - Resolve

    /// Returns the full URL for a stored filename.
    static func url(for filename: String) throws -> URL {
        try directory.appending(component: filename, directoryHint: .notDirectory)
    }

    // MARK: - Copy

    /// Copies an audio file from `sourceURL` into the store.
    /// - Returns: The stored filename (e.g. `"uuid.mp3"`).
    @discardableResult
    static func copy(from sourceURL: URL) throws -> String {
        let dir = try directory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let filename = "\(UUID().uuidString).\(sourceURL.pathExtension)"
        let destination = dir.appending(component: filename, directoryHint: .notDirectory)
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        print("[AudioFileStore] Copied \(sourceURL.lastPathComponent) → \(destination.path)")
        return filename
    }

    // MARK: - Delete

    /// Deletes a stored audio file.  Silently ignores files that no longer exist.
    static func delete(filename: String) throws {
        let fileURL = try url(for: filename)
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("[AudioFileStore] Deleted \(filename)")
        } catch CocoaError.fileNoSuchFile {
            // Already gone — not an error
        }
    }
}
