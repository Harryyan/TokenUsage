import AppKit
import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case chineseSimplified

    var id: String { rawValue }

    /// The language code to write into AppleLanguages. nil means "follow system".
    var code: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .chineseSimplified: return "zh-Hans"
        }
    }

    /// Menu label. "System" is localized; native languages show their own
    /// native name so a user who can't read the current UI can still find
    /// their language.
    var displayKey: LocalizedStringKey {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .chineseSimplified: return "简体中文"
        }
    }
}

enum AppLanguageManager {
    private static let preferenceKey = "userPreferredLanguage"
    private static let appleLanguagesKey = "AppleLanguages"

    static var current: AppLanguage {
        get {
            guard let raw = UserDefaults.standard.string(forKey: preferenceKey),
                  let lang = AppLanguage(rawValue: raw) else {
                return .system
            }
            return lang
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: preferenceKey)
        }
    }

    /// Call at app launch, before any SwiftUI view renders, so Bundle.main
    /// resolves localizations in the chosen language.
    static func applyPreferredLanguageIfNeeded() {
        let pref = current
        if let code = pref.code {
            UserDefaults.standard.set([code], forKey: appleLanguagesKey)
        } else {
            UserDefaults.standard.removeObject(forKey: appleLanguagesKey)
        }
    }

    /// Persist the new choice and relaunch the app so the new locale loads.
    static func setAndRelaunch(_ language: AppLanguage) {
        current = language
        if let code = language.code {
            UserDefaults.standard.set([code], forKey: appleLanguagesKey)
        } else {
            UserDefaults.standard.removeObject(forKey: appleLanguagesKey)
        }
        UserDefaults.standard.synchronize()
        relaunch()
    }

    private static func relaunch() {
        let url = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }
}
