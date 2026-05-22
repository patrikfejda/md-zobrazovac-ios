import SwiftUI

struct LibraryView: View {
    let folder: LibraryFolder

    var body: some View {
        List {
            if folder.isEmpty {
                Text("Tento priečinok je prázdny.")
                    .foregroundStyle(.secondary)
            } else {
                if !folder.folders.isEmpty {
                    Section {
                        ForEach(folder.folders) { sub in
                            NavigationLink(value: sub) {
                                FolderRow(folder: sub)
                            }
                        }
                    }
                }
                if !folder.files.isEmpty {
                    Section {
                        ForEach(folder.files) { entry in
                            NavigationLink(value: entry) {
                                FileRow(entry: entry)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(folder.name.isEmpty ? "Knižnica" : folder.name)
    }
}

private struct FolderRow: View {
    let folder: LibraryFolder

    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundStyle(.tint)
            Text(folder.name)
            Spacer()
            Text("\(itemCount(folder))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func itemCount(_ folder: LibraryFolder) -> Int {
        folder.folders.count + folder.files.count
    }
}

private struct FileRow: View {
    let entry: ContentEntry

    var body: some View {
        HStack {
            Image(systemName: icon(for: entry.kind))
                .foregroundStyle(.secondary)
            Text(entry.displayTitle)
        }
    }

    private func icon(for kind: ContentKind) -> String {
        switch kind {
        case .markdown: "doc.text"
        case .html: "globe"
        case .image: "photo"
        case .other: "doc"
        }
    }
}
