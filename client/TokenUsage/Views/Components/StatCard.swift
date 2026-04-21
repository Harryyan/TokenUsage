import SwiftUI

// MARK: - Design Tokens

enum Theme {
    static let costAccent = Color(red: 0.30, green: 0.85, blue: 0.50)
    static let inputColor = Color(red: 0.40, green: 0.65, blue: 1.0)
    static let outputColor = Color(red: 0.76, green: 0.55, blue: 1.0)
    static let cacheWriteColor = Color(red: 1.0, green: 0.60, blue: 0.25)
    static let cacheReadColor = Color(red: 0.20, green: 0.83, blue: 0.75)

    static let cardFill = Color.white.opacity(0.04)
    static let cardBorder = Color.white.opacity(0.07)
    static let radius: CGFloat = 10
}

// MARK: - Card Background Modifier

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius)
                    .fill(Theme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius)
                            .strokeBorder(Theme.cardBorder, lineWidth: 0.5)
                    )
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Token Proportion Bar

struct TokenProportionBar: View {
    let input: Int
    let output: Int
    let cacheWrite: Int
    let cacheRead: Int

    private var total: Int { input + output + cacheWrite + cacheRead }

    var body: some View {
        GeometryReader { geo in
            if total == 0 {
                Capsule().fill(Color.white.opacity(0.06))
            } else {
                HStack(spacing: 1.5) {
                    segment(Theme.inputColor, count: input, width: geo.size.width)
                    segment(Theme.outputColor, count: output, width: geo.size.width)
                    segment(Theme.cacheWriteColor, count: cacheWrite, width: geo.size.width)
                    segment(Theme.cacheReadColor, count: cacheRead, width: geo.size.width)
                }
            }
        }
        .frame(height: 5)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func segment(_ color: Color, count: Int, width: CGFloat) -> some View {
        if count > 0 {
            let fraction = CGFloat(count) / CGFloat(total)
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: max(width * fraction, 3))
        }
    }
}

// MARK: - Token Breakdown Row

struct TokenBreakdownRow: View {
    let label: String
    let tokens: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
            Spacer()
            Text(TokenFormatter.abbreviated(tokens))
                .font(.system(size: 11.5, design: .monospaced))
                .monospacedDigit()
            Text("(\(TokenFormatter.precise(tokens)))")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .tracking(0.8)
    }
}
