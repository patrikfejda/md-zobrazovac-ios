import SwiftUI

struct PageView: View {
    let entry: ContentEntry

    @Environment(ContentStore.self) private var store
    @AppStorage(AppStorageKey.readerFontScale) private var fontScale: Double = AppDefaults.fontScale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let text = store.readText(for: entry) {
                    switch entry.kind {
                    case .markdown:
                        MarkdownView(text: text, fontScale: fontScale)
                    case .html:
                        // Trivial fallback — strip tags and render as plain.
                        // Plug in WKWebView here if you need real HTML rendering.
                        Text(stripTags(text))
                            .font(.system(size: 17 * fontScale))
                    default:
                        Text(text)
                            .font(.system(size: 17 * fontScale))
                    }
                } else {
                    ContentUnavailableView(
                        "Obsah nie je k dispozícii",
                        systemImage: "doc.questionmark",
                        description: Text("Synchronizuj znova v Nastaveniach.")
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(entry.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stripTags(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
