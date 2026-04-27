import SwiftUI

struct Palette: Equatable {
    let bg: Color
    let surface: Color
    let border: Color
    let borderVisible: Color
    let textDisabled: Color
    let textSecondary: Color
    let textPrimary: Color
    let textDisplay: Color
    let accent: Color
    let accentSoft: Color
    let success: Color
    let warning: Color
    let error: Color
    let barEmpty: Color
}

extension Palette {
    static let nothingDark = Palette(
        bg: Color(hex: 0x050505),
        surface: Color(hex: 0x0F0F0F),
        border: Color(hex: 0x1E1E1E),
        borderVisible: Color(hex: 0x2C2C2C),
        textDisabled: Color(hex: 0x5C5C5C),
        textSecondary: Color(hex: 0x8F8F8F),
        textPrimary: Color(hex: 0xE5E5E5),
        textDisplay: Color(hex: 0xFFFFFF),
        accent: Color(hex: 0x7FE0A8),
        accentSoft: Color(red: 127/255, green: 224/255, blue: 168/255).opacity(0.18),
        success: Color(hex: 0x7FE0A8),
        warning: Color(hex: 0xD4A843),
        error: Color(hex: 0xD71921),
        barEmpty: Color(hex: 0x1C1C1C)
    )

    static let nothingLight = Palette(
        bg: Color(hex: 0xEFEDE6),
        surface: Color(hex: 0xF7F5EE),
        border: Color(hex: 0xDCD9CF),
        borderVisible: Color(hex: 0xC7C3B6),
        textDisabled: Color(hex: 0xABA89D),
        textSecondary: Color(hex: 0x807D72),
        textPrimary: Color(hex: 0x1F1E1A),
        textDisplay: Color(hex: 0x0A0A08),
        accent: Color(hex: 0x2C8A5A),
        accentSoft: Color(red: 64/255, green: 168/255, blue: 110/255).opacity(0.18),
        success: Color(hex: 0x2C8A5A),
        warning: Color(hex: 0xC8941F),
        error: Color(hex: 0xC4101A),
        barEmpty: Color(hex: 0xDCD9CF)
    )
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
