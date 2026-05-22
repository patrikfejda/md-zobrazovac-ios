import Foundation

/// A folder node in the navigable library tree. Built from manifest entry paths
/// like `pages/notes/foo.md` — each `/`-separated component becomes a nesting
/// level. Folders are sorted before files; both alphabetically.
struct LibraryFolder: Identifiable, Hashable {
    /// Last path component (e.g. `notes`). Empty for the synthetic root.
    let name: String
    /// Full path from the manifest root (e.g. `pages/notes`). Empty for root.
    let path: String
    var folders: [LibraryFolder]
    var files: [ContentEntry]

    var id: String { path }

    var isEmpty: Bool { folders.isEmpty && files.isEmpty }
}

extension ContentManifest {
    /// Build a folder tree from the renderable pages. The returned root has
    /// `name == ""` and `path == ""`; its children are the top-level folders
    /// and files.
    func libraryTree() -> LibraryFolder {
        var root = LibraryFolder(name: "", path: "", folders: [], files: [])
        for entry in pages {
            let components = entry.path
                .split(separator: "/", omittingEmptySubsequences: true)
                .map(String.init)
            guard !components.isEmpty else { continue }
            insert(entry, components: components, into: &root, prefix: "")
        }
        sort(&root)
        return root
    }

    private func insert(
        _ entry: ContentEntry,
        components: [String],
        into folder: inout LibraryFolder,
        prefix: String
    ) {
        if components.count == 1 {
            folder.files.append(entry)
            return
        }
        let head = components[0]
        let childPath = prefix.isEmpty ? head : "\(prefix)/\(head)"
        let rest = Array(components.dropFirst())

        if let index = folder.folders.firstIndex(where: { $0.name == head }) {
            insert(entry, components: rest, into: &folder.folders[index], prefix: childPath)
        } else {
            var child = LibraryFolder(name: head, path: childPath, folders: [], files: [])
            insert(entry, components: rest, into: &child, prefix: childPath)
            folder.folders.append(child)
        }
    }

    private func sort(_ folder: inout LibraryFolder) {
        folder.folders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        folder.files.sort { $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending }
        for i in folder.folders.indices {
            sort(&folder.folders[i])
        }
    }
}
