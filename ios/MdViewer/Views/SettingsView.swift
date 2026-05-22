import SwiftUI

struct SettingsView: View {
    @Environment(ContentStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppStorageKey.colorSchemeOverride) private var colorSchemeOverride: ColorSchemeOverride = .auto
    @AppStorage(AppStorageKey.readerFontScale) private var fontScale: Double = AppDefaults.fontScale
    @AppStorage(AppStorageKey.contentManifestURL) private var manifestURL: String = AppDefaults.manifestURL
    @AppStorage(AppStorageKey.lastSyncAt) private var lastSyncAtTimestamp: Double = 0

    @State private var syncService: ContentSyncService?
    @State private var showWipeConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                fontSection
                sourceSection
                syncSection
                storageSection
            }
            .navigationTitle("Nastavenia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hotovo") { dismiss() }
                }
            }
            .task {
                if syncService == nil {
                    syncService = ContentSyncService(store: store)
                }
            }
        }
        .preferredColorScheme(colorSchemeOverride.preferredColorScheme)
    }

    private var appearanceSection: some View {
        Section("Vzhľad") {
            Picker("Režim", selection: $colorSchemeOverride) {
                ForEach(ColorSchemeOverride.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
        }
    }

    private var fontSection: some View {
        Section("Veľkosť písma") {
            HStack {
                Text("A").font(.caption)
                Slider(value: $fontScale, in: 0.8...1.6, step: 0.05)
                Text("A").font(.title2)
            }
            Text("Ukážka textu pri zvolenej veľkosti.")
                .font(.system(size: 17 * fontScale))
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        }
    }

    private var sourceSection: some View {
        Section {
            TextField("https://raw.githubusercontent.com/.../manifest.json", text: $manifestURL, axis: .vertical)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lineLimit(3, reservesSpace: false)
        } header: {
            Text("Zdroj obsahu")
        } footer: {
            Text("URL na manifest.json vo tvojom GitHub repe. Napríklad raw.githubusercontent.com/USER/REPO/main/content/manifest.json")
        }
    }

    @ViewBuilder
    private var syncSection: some View {
        Section("Synchronizácia") {
            if let syncService {
                Button {
                    Task { await syncService.sync(manifestURLString: manifestURL) }
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text(syncService.isSyncing ? "Synchronizujem…" : "Stiahnuť obsah")
                    }
                }
                .disabled(syncService.isSyncing || manifestURL.isEmpty)

                if let progress = syncService.progress {
                    progressRow(progress)
                }

                if let lastError = syncService.lastError {
                    Text(lastError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if lastSyncAtTimestamp > 0 {
                    let date = Date(timeIntervalSince1970: lastSyncAtTimestamp)
                    Text("Posledná synchronizácia: \(date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func progressRow(_ progress: SyncProgress) -> some View {
        HStack {
            ProgressView()
            Text(progressLabel(progress))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func progressLabel(_ progress: SyncProgress) -> String {
        switch progress.phase {
        case .fetchingManifest: "Sťahujem manifest…"
        case .downloadingFiles: "Sťahujem súbory \(progress.current + 1) / \(progress.total)…"
        case .finalizing: "Dokončujem…"
        }
    }

    private var storageSection: some View {
        Section("Úložisko") {
            if let manifest = store.manifest {
                LabeledContent("Počet súborov", value: "\(manifest.entries.count)")
            }
            Button(role: .destructive) {
                showWipeConfirm = true
            } label: {
                Label("Vymazať lokálny obsah", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Vymazať všetok stiahnutý obsah?",
            isPresented: $showWipeConfirm,
            titleVisibility: .visible
        ) {
            Button("Vymazať", role: .destructive) { store.wipe() }
            Button("Zrušiť", role: .cancel) {}
        }
    }
}

#Preview {
    SettingsView()
        .environment(ContentStore())
}
