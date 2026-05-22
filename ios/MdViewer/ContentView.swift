import SwiftUI

struct ContentView: View {
    @Environment(ContentStore.self) private var store
    @AppStorage(AppStorageKey.contentManifestURL) private var manifestURL: String = AppDefaults.manifestURL
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if let manifest = store.manifest, !manifest.pages.isEmpty {
                    LibraryView(manifest: manifest)
                } else {
                    EmptyLibraryView(
                        hasManifestURL: !manifestURL.isEmpty,
                        loadError: store.loadError,
                        onOpenSettings: { showSettings = true }
                    )
                }
            }
            .navigationTitle(store.manifest?.title ?? "Markdown zobrazovač")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Nastavenia")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

private struct EmptyLibraryView: View {
    let hasManifestURL: Bool
    let loadError: String?
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let loadError {
                ContentUnavailableView(
                    "Chyba",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else if hasManifestURL {
                ContentUnavailableView(
                    "Žiadny obsah",
                    systemImage: "tray",
                    description: Text("Otvor Nastavenia a stlač Synchronizovať.")
                )
            } else {
                ContentUnavailableView(
                    "Nastav zdroj obsahu",
                    systemImage: "link",
                    description: Text("V Nastaveniach vlož URL na manifest.json.")
                )
            }
            Button("Otvoriť nastavenia", action: onOpenSettings)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(ContentStore())
}
