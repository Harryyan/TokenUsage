import SwiftUI

// MARK: - Pixel Design Tokens

enum Pixel {
    static let bg = Color(red: 0.05, green: 0.06, blue: 0.10)
    static let panel = Color(red: 0.09, green: 0.09, blue: 0.16)
    static let borderBright = Color(red: 0.29, green: 0.31, blue: 0.48)
    static let borderDim = Color(red: 0.16, green: 0.18, blue: 0.29)

    static let text = Color(red: 0.91, green: 0.90, blue: 0.94)
    static let textDim = Color(red: 0.48, green: 0.49, blue: 0.62)
    static let textMuted = Color(red: 0.28, green: 0.29, blue: 0.42)

    static let gold = Color(red: 0.94, green: 0.75, blue: 0.25)
    static let green = Color(red: 0.31, green: 0.91, blue: 0.31)
    static let red = Color(red: 1.0, green: 0.25, blue: 0.38)
    static let amber = Color(red: 1.0, green: 0.69, blue: 0.13)

    static let inputBlue = Color(red: 0.31, green: 0.63, blue: 1.0)
    static let outputPurple = Color(red: 0.82, green: 0.38, blue: 1.0)
    static let cacheOrange = Color(red: 1.0, green: 0.50, blue: 0.25)
    static let cacheCyan = Color(red: 0.25, green: 0.91, blue: 0.82)
}

// MARK: - RPG Double-Border Frame

struct PixelFrame: ViewModifier {
    var accent: Color = Pixel.borderBright

    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(Pixel.panel)
            .overlay(Rectangle().strokeBorder(Pixel.borderDim, lineWidth: 1))
            .padding(2)
            .overlay(Rectangle().strokeBorder(accent, lineWidth: 2))
    }
}

extension View {
    func pixelFrame(accent: Color = Pixel.borderBright) -> some View {
        modifier(PixelFrame(accent: accent))
    }
}

// MARK: - Pixel HP Bar

struct PixelBar: View {
    let input: Int
    let output: Int
    let cacheWrite: Int
    let cacheRead: Int

    private var total: Int { input + output + cacheWrite + cacheRead }

    var body: some View {
        GeometryReader { geo in
            if total == 0 {
                Rectangle().fill(Pixel.borderDim)
            } else {
                HStack(spacing: 1) {
                    segment(Pixel.inputBlue, count: input, width: geo.size.width)
                    segment(Pixel.outputPurple, count: output, width: geo.size.width)
                    segment(Pixel.cacheOrange, count: cacheWrite, width: geo.size.width)
                    segment(Pixel.cacheCyan, count: cacheRead, width: geo.size.width)
                }
            }
        }
        .frame(height: 8)
        .background(Pixel.bg)
        .border(Pixel.borderDim, width: 1)
        .padding(1)
        .border(Pixel.borderBright, width: 1)
    }

    @ViewBuilder
    private func segment(_ color: Color, count: Int, width: CGFloat) -> some View {
        if count > 0 {
            Rectangle()
                .fill(color)
                .frame(width: max(width * CGFloat(count) / CGFloat(total), 3))
        }
    }
}

// MARK: - Pixel Divider

struct PixelDivider: View {
    var body: some View {
        Rectangle()
            .fill(Pixel.borderBright)
            .frame(height: 2)
    }
}

// MARK: - Token Breakdown Row

struct TokenBreakdownRow: View {
    let label: String
    let tokens: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .foregroundStyle(Pixel.textDim)
            Spacer()
            Text(TokenFormatter.abbreviated(tokens))
                .monospacedDigit()
            Text("(\(TokenFormatter.precise(tokens)))")
                .foregroundStyle(Pixel.textMuted)
        }
        .font(.system(size: 11, design: .monospaced))
    }
}

// MARK: - Section Header

struct PixelSectionHeader: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Text(">>>")
                .foregroundStyle(Pixel.gold)
            Text(text.uppercased())
                .foregroundStyle(Pixel.textDim)
        }
        .font(.system(size: 10, weight: .bold, design: .monospaced))
    }
}
