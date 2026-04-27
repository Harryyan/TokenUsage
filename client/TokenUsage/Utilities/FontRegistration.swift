import CoreText
import Foundation
import SwiftUI

extension Font {
    /// Doto Black — bundled dot-matrix pixel font, used for hero numerals only.
    static func doto(_ size: CGFloat) -> Font {
        .custom("Doto-Black", size: size)
    }

    /// Space Mono — bundled monospace, used for all ALL CAPS labels and data readouts.
    static func spaceMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let bold = weight == .bold || weight == .heavy || weight == .black || weight == .semibold
        return .custom(bold ? "SpaceMono-Bold" : "SpaceMono-Regular", size: size)
    }
}

enum FontRegistration {
    /// Registers bundled custom fonts for the current process.
    /// Called once at app launch.
    static func registerBundledFonts() {
        let fonts = ["Doto-Black", "SpaceMono-Regular", "SpaceMono-Bold"]
        for name in fonts {
            register(name)
        }
    }

    private static func register(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
            NSLog("[TokenUsage] ⚠️ Font \(name).ttf not found in bundle (resourcePath=\(Bundle.main.resourcePath ?? "nil"))")
            return
        }
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            NSLog("[TokenUsage] ✓ Registered font: \(name) at \(url.path)")
        } else {
            let msg = error?.takeRetainedValue().localizedDescription ?? "unknown"
            NSLog("[TokenUsage] ⚠️ Failed to register \(name): \(msg)")
        }
    }
}
