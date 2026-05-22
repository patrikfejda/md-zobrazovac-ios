import SwiftUI

enum ColorSchemeOverride: String, CaseIterable, Identifiable {
    case auto
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: "Automaticky"
        case .light: "Svetlý"
        case .dark: "Tmavý"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .auto: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppStorageKey {
    static let colorSchemeOverride = "colorSchemeOverride"
    static let readerFontScale = "readerFontScale"
    static let contentManifestURL = "contentManifestURL"
    static let lastSyncAt = "lastSyncAt"
}

enum AppDefaults {
    static let fontScale: Double = 1.0
    static let manifestURL: String = ""
}
