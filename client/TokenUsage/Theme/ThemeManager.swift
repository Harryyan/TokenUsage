import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    private static let storageKey = "selectedThemeID"

    @Published var current: Theme

    init() {
        let id = UserDefaults.standard.string(forKey: Self.storageKey) ?? Theme.pixelGold.id
        self.current = Theme.withID(id)
    }

    func select(_ theme: Theme) {
        current = theme
        UserDefaults.standard.set(theme.id, forKey: Self.storageKey)
    }

    // MARK: Forwarded color slots (let views read `theme.bg` instead of `theme.current.bg`)

    var bg: Color { current.bg }
    var panel: Color { current.panel }
    var borderBright: Color { current.borderBright }
    var borderDim: Color { current.borderDim }
    var text: Color { current.text }
    var textDim: Color { current.textDim }
    var textMuted: Color { current.textMuted }
    var accent: Color { current.accent }
    var statusGreen: Color { current.statusGreen }
    var statusRed: Color { current.statusRed }
    var statusAmber: Color { current.statusAmber }
    var input: Color { current.input }
    var output: Color { current.output }
    var cacheWrite: Color { current.cacheWrite }
    var cacheRead: Color { current.cacheRead }
}
