import Foundation

/// Schema for `manifest.json`. Bump `currentSchemaVersion` when this changes
/// and update the parser to reject older payloads explicitly.
enum ContentManifestSchema {
    static let currentVersion = 1
}

enum ContentKind: String, Codable, Sendable {
    case markdown
    case html
    case image
    case other
}

struct ContentEntry: Codable, Identifiable, Hashable, Sendable {
    /// Path relative to the manifest URL (e.g. `pages/index.md`).
    let path: String
    let title: String?
    let kind: ContentKind
    let sha256: String
    let size: Int

    var id: String { path }

    /// Filename without extension, used as fallback title.
    var fallbackTitle: String {
        (path as NSString).lastPathComponent
            .replacingOccurrences(of: ".md", with: "")
            .replacingOccurrences(of: ".html", with: "")
    }

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return fallbackTitle
    }
}

struct ContentManifest: Codable, Sendable {
    let schemaVersion: Int
    let title: String?
    let generatedAt: String?
    let entries: [ContentEntry]

    /// Returns only entries that are renderable as pages (markdown/html).
    var pages: [ContentEntry] {
        entries.filter { $0.kind == .markdown || $0.kind == .html }
    }
}
