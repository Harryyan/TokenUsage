import SwiftUI
import Combine

enum AppearanceMode: String, CaseIterable, Identifiable {
    case auto, light, dark
    var id: String { rawValue }
    var displayKey: LocalizedStringKey {
        switch self {
        case .auto: return "Auto"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    private static let storageKey = "appearanceMode"

    @Published var mode: AppearanceMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.storageKey) }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppearanceMode.auto.rawValue
        self.mode = AppearanceMode(rawValue: raw) ?? .auto
    }

    func palette(for systemScheme: ColorScheme) -> Palette {
        let resolved: ColorScheme
        switch mode {
        case .auto: resolved = systemScheme
        case .light: resolved = .light
        case .dark: resolved = .dark
        }
        return resolved == .light ? .nothingLight : .nothingDark
    }

    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .auto: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
