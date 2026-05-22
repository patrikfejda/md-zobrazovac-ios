import SwiftUI

struct LibraryView: View {
    let manifest: ContentManifest

    var body: some View {
        List(manifest.pages) { entry in
            NavigationLink(value: entry) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.displayTitle)
                        .font(.body)
                    Text(entry.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationDestination(for: ContentEntry.self) { entry in
            PageView(entry: entry)
        }
    }
}
