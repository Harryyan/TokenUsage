import SwiftUI

// MARK: - RPG Double-Border Frame

struct PixelFrame: ViewModifier {
    @EnvironmentObject var theme: ThemeManager
    var accent: Color? = nil

    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(theme.panel)
            .overlay(Rectangle().strokeBorder(theme.borderDim, lineWidth: 1))
            .padding(2)
            .overlay(Rectangle().strokeBorder(accent ?? theme.borderBright, lineWidth: 2))
    }
}

extension View {
    func pixelFrame(accent: Color? = nil) -> some View {
        modifier(PixelFrame(accent: accent))
    }
}

// MARK: - Pixel HP Bar

struct PixelBar: View {
    @EnvironmentObject var theme: ThemeManager

    let input: Int
    let output: Int
    let cacheWrite: Int
    let cacheRead: Int

    private var total: Int { input + output + cacheWrite + cacheRead }

    var body: some View {
        GeometryReader { geo in
            if total == 0 {
                Rectangle().fill(theme.borderDim)
            } else {
                HStack(spacing: 1) {
                    segment(theme.input, count: input, width: geo.size.width)
                    segment(theme.output, count: output, width: geo.size.width)
                    segment(theme.cacheWrite, count: cacheWrite, width: geo.size.width)
                    segment(theme.cacheRead, count: cacheRead, width: geo.size.width)
                }
            }
        }
        .frame(height: 8)
        .background(theme.bg)
        .border(theme.borderDim, width: 1)
        .padding(1)
        .border(theme.borderBright, width: 1)
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
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        Rectangle()
            .fill(theme.borderBright)
            .frame(height: 2)
    }
}

// MARK: - Token Breakdown Row

struct TokenBreakdownRow: View {
    @EnvironmentObject var theme: ThemeManager

    let label: LocalizedStringKey
    let tokens: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .foregroundStyle(theme.textDim)
            Spacer()
            Text(TokenFormatter.abbreviated(tokens))
                .monospacedDigit()
            Text(verbatim: "(\(TokenFormatter.precise(tokens)))")
                .foregroundStyle(theme.textMuted)
        }
        .font(.system(size: 11, design: .monospaced))
    }
}

// MARK: - Section Header

struct PixelSectionHeader: View {
    @EnvironmentObject var theme: ThemeManager

    let text: LocalizedStringKey

    var body: some View {
        HStack(spacing: 6) {
            Text(verbatim: ">>>")
                .foregroundStyle(theme.accent)
            Text(text)
                .foregroundStyle(theme.textDim)
        }
        .font(.system(size: 10, weight: .bold, design: .monospaced))
    }
}
