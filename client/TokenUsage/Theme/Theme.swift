import SwiftUI

struct Theme: Identifiable, Equatable {
    let id: String
    let displayKey: LocalizedStringKey

    // Surfaces
    let bg: Color
    let panel: Color
    let borderBright: Color
    let borderDim: Color

    // Text
    let text: Color
    let textDim: Color
    let textMuted: Color

    // Accent (drives SCORE + tab highlight + section arrows)
    let accent: Color

    // Status dot in header
    let statusGreen: Color
    let statusRed: Color
    let statusAmber: Color

    // Token category colors (HP bar segments + breakdown swatches)
    let input: Color
    let output: Color
    let cacheWrite: Color
    let cacheRead: Color

    static func == (lhs: Theme, rhs: Theme) -> Bool { lhs.id == rhs.id }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

extension Theme {
    static let pixelGold = Theme(
        id: "pixelGold",
        displayKey: "Pixel Gold",
        bg: Color(red: 0.05, green: 0.06, blue: 0.10),
        panel: Color(red: 0.09, green: 0.09, blue: 0.16),
        borderBright: Color(red: 0.29, green: 0.31, blue: 0.48),
        borderDim: Color(red: 0.16, green: 0.18, blue: 0.29),
        text: Color(red: 0.91, green: 0.90, blue: 0.94),
        textDim: Color(red: 0.48, green: 0.49, blue: 0.62),
        textMuted: Color(red: 0.28, green: 0.29, blue: 0.42),
        accent: Color(red: 0.94, green: 0.75, blue: 0.25),
        statusGreen: Color(red: 0.31, green: 0.91, blue: 0.31),
        statusRed: Color(red: 1.0, green: 0.25, blue: 0.38),
        statusAmber: Color(red: 1.0, green: 0.69, blue: 0.13),
        input: Color(red: 0.31, green: 0.63, blue: 1.0),
        output: Color(red: 0.82, green: 0.38, blue: 1.0),
        cacheWrite: Color(red: 1.0, green: 0.50, blue: 0.25),
        cacheRead: Color(red: 0.25, green: 0.91, blue: 0.82)
    )

    static let terminalGreen = Theme(
        id: "terminalGreen",
        displayKey: "Terminal Green",
        bg: Color(hex: 0x0A0F0A),
        panel: Color(hex: 0x0F1810),
        borderBright: Color(hex: 0x3A7A4E),
        borderDim: Color(hex: 0x153020),
        text: Color(hex: 0xB8F5B8),
        textDim: Color(hex: 0x5FB070),
        textMuted: Color(hex: 0x2D5A3A),
        accent: Color(hex: 0x5FFF5F),
        statusGreen: Color(hex: 0x5FFF5F),
        statusRed: Color(hex: 0xFF6B6B),
        statusAmber: Color(hex: 0xFFC857),
        input: Color(hex: 0x4FD1FF),
        output: Color(hex: 0xC3FF5F),
        cacheWrite: Color(hex: 0xFFC857),
        cacheRead: Color(hex: 0x5FFFCC)
    )

    static let synthwave = Theme(
        id: "synthwave",
        displayKey: "Synthwave",
        bg: Color(hex: 0x1A0B2E),
        panel: Color(hex: 0x2A1147),
        borderBright: Color(hex: 0x7B2CBF),
        borderDim: Color(hex: 0x3D1A5F),
        text: Color(hex: 0xF5E8FF),
        textDim: Color(hex: 0xB693D0),
        textMuted: Color(hex: 0x6B4A85),
        accent: Color(hex: 0xFF2E88),
        statusGreen: Color(hex: 0x9FFF8D),
        statusRed: Color(hex: 0xFF4E6B),
        statusAmber: Color(hex: 0xFFB84D),
        input: Color(hex: 0x4FD1FF),
        output: Color(hex: 0xC77DFF),
        cacheWrite: Color(hex: 0xFF8A4D),
        cacheRead: Color(hex: 0x7EFFE3)
    )

    static let gruvbox = Theme(
        id: "gruvbox",
        displayKey: "Gruvbox",
        bg: Color(hex: 0x1D2021),
        panel: Color(hex: 0x282828),
        borderBright: Color(hex: 0x665C54),
        borderDim: Color(hex: 0x3C3836),
        text: Color(hex: 0xEBDBB2),
        textDim: Color(hex: 0xA89984),
        textMuted: Color(hex: 0x7C6F64),
        accent: Color(hex: 0xFABD2F),
        statusGreen: Color(hex: 0xB8BB26),
        statusRed: Color(hex: 0xFB4934),
        statusAmber: Color(hex: 0xFE8019),
        input: Color(hex: 0x83A598),
        output: Color(hex: 0xD3869B),
        cacheWrite: Color(hex: 0xFE8019),
        cacheRead: Color(hex: 0x8EC07C)
    )

    static let gameBoy = Theme(
        id: "gameBoy",
        displayKey: "Game Boy",
        bg: Color(hex: 0x0F380F),
        panel: Color(hex: 0x1E4D1E),
        borderBright: Color(hex: 0x8BAC0F),
        borderDim: Color(hex: 0x306230),
        text: Color(hex: 0x9BBC0F),
        textDim: Color(hex: 0x7A9C0F),
        textMuted: Color(hex: 0x4A7A2A),
        accent: Color(hex: 0x9BBC0F),
        statusGreen: Color(hex: 0x9BBC0F),
        statusRed: Color(hex: 0xA85A2A),
        statusAmber: Color(hex: 0xCFBE3F),
        input: Color(hex: 0x9BBC0F),
        output: Color(hex: 0xCFDF3F),
        cacheWrite: Color(hex: 0x7A9C0F),
        cacheRead: Color(hex: 0x5A8A4A)
    )

    static let all: [Theme] = [.pixelGold, .terminalGreen, .synthwave, .gruvbox, .gameBoy]

    static func withID(_ id: String) -> Theme {
        all.first { $0.id == id } ?? .pixelGold
    }
}
