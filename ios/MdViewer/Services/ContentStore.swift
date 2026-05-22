import CryptoKit
import Foundation
import Observation

/// Owns the on-disk content cache and the in-memory manifest.
/// Reads are synchronous from disk because files are small (≤ a few MB total
/// for a personal knowledge base — if you grow beyond that, switch to async).
@Observable
final class ContentStore {
    private(set) var manifest: ContentManifest?
    private(set) var loadError: String?

    private let rootURL: URL
    private let manifestURL: URL

    init(rootURL: URL? = nil) {
        let resolved = rootURL ?? Self.defaultRootURL()
        self.rootURL = resolved
        self.manifestURL = resolved.appending(path: "manifest.json")
        loadFromDisk()
    }

    /// `Application Support/MdViewerContent/`. Created lazily.
    static func defaultRootURL() -> URL {
        URL.applicationSupportDirectory.appending(path: "MdViewerContent", directoryHint: .isDirectory)
    }

    /// Ensure the root directory exists on disk. Safe to call repeatedly.
    func ensureRootExists() throws {
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    func loadFromDisk() {
        do {
            try ensureRootExists()
            guard FileManager.default.fileExists(atPath: manifestURL.path) else {
                manifest = nil
                return
            }
            let data = try Data(contentsOf: manifestURL)
            let decoded = try JSONDecoder().decode(ContentManifest.self, from: data)
            guard decoded.schemaVersion == ContentManifestSchema.currentVersion else {
                loadError = "Neznáma verzia manifestu: \(decoded.schemaVersion). Synchronizuj znova."
                manifest = nil
                return
            }
            manifest = decoded
            loadError = nil
        } catch {
            manifest = nil
            loadError = "Lokálny obsah sa nepodarilo načítať: \(error.localizedDescription)"
        }
    }

    func localFileURL(for entry: ContentEntry) -> URL {
        rootURL.appending(path: entry.path)
    }

    func readText(for entry: ContentEntry) -> String? {
        let url = localFileURL(for: entry)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    /// Atomically replace the manifest after a successful sync.
    func writeManifest(_ manifest: ContentManifest) throws {
        try ensureRootExists()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(manifest)
        try data.write(to: manifestURL, options: .atomic)
        self.manifest = manifest
    }

    /// Write a single content file relative to root.
    func writeFile(at relativePath: String, data: Data) throws {
        let target = rootURL.appending(path: relativePath)
        let parent = target.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        try data.write(to: target, options: .atomic)
    }

    func removeFile(at relativePath: String) {
        let target = rootURL.appending(path: relativePath)
        try? FileManager.default.removeItem(at: target)
    }

    func computedSHA256(at relativePath: String) -> String? {
        let target = rootURL.appending(path: relativePath)
        guard let data = try? Data(contentsOf: target) else { return nil }
        return Self.sha256(data)
    }

    static func sha256(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// For Settings → "Vymazať lokálny obsah".
    func wipe() {
        try? FileManager.default.removeItem(at: rootURL)
        manifest = nil
        loadError = nil
    }
}
