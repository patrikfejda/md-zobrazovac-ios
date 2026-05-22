import SwiftUI

@main
struct MdViewerApp: App {
    @AppStorage(AppStorageKey.colorSchemeOverride) private var colorSchemeOverride: ColorSchemeOverride = .auto

    @State private var contentStore = ContentStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(contentStore)
                .preferredColorScheme(colorSchemeOverride.preferredColorScheme)
        }
    }
}
