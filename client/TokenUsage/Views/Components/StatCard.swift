import SwiftUI

// MARK: - ALL CAPS monospace label

struct LabelText: View {
    let text: LocalizedStringKey
    let color: Color
    var size: CGFloat = 10
    var tracking: CGFloat = 1.6

    var body: some View {
        Text(text)
            .font(.spaceMono(size))
            .tracking(tracking)
            .foregroundStyle(color)
            .textCase(.uppercase)
    }
}

// MARK: - Segmented progress bar

struct SegmentedBar: View {
    let progress: Double
    let palette: Palette
    var segments: Int = 24
    var height: CGFloat = 8
    var spacing: CGFloat = 2
    var fill: Color? = nil

    var body: some View {
        let clamped = max(0, min(1, progress))
        let filled = Int((Double(segments) * clamped).rounded())
        HStack(spacing: spacing) {
            ForEach(0..<segments, id: \.self) { i in
                Rectangle()
                    .fill(i < filled ? (fill ?? palette.textDisplay) : palette.barEmpty)
            }
        }
        .frame(height: height)
    }
}

// MARK: - 7-day mini bar chart

struct MiniBarChart: View {
    let data: [DailyDataPoint]
    let palette: Palette
    @Binding var hoveredIndex: Int?
    var height: CGFloat = 44

    var body: some View {
        let maxVal = max(data.map(\.cost).max() ?? 0, 0.01)
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(data.enumerated()), id: \.offset) { idx, point in
                let isLast = idx == data.count - 1
                let isHovered = hoveredIndex == idx
                let ratio = point.cost / maxVal
                let barHeight = max(CGFloat(ratio) * height, 2)

                ZStack(alignment: .bottom) {
                    // Full-column hit area
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                    // Visible bar
                    Rectangle()
                        .fill(barColor(isLast: isLast, isHovered: isHovered))
                        .frame(height: barHeight)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onHover { hovering in
                    if hovering {
                        hoveredIndex = idx
                    } else if hoveredIndex == idx {
                        hoveredIndex = nil
                    }
                }
            }
        }
        .frame(height: height)
    }

    private func barColor(isLast: Bool, isHovered: Bool) -> Color {
        if isLast {
            return isHovered ? palette.accent.opacity(0.6) : palette.accent
        }
        return palette.textPrimary.opacity(isHovered ? 0.65 : 0.4)
    }
}

// MARK: - Status dot (static; pulse driven by TimelineView when needed)

struct StatusDot: View {
    let color: Color
    var size: CGFloat = 6
    var pulsing: Bool = false

    var body: some View {
        Group {
            if pulsing {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let phase = (sin(t * 2.4) + 1) / 2
                    Circle()
                        .fill(color)
                        .frame(width: size, height: size)
                        .opacity(0.55 + phase * 0.45)
                }
            } else {
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Hairline divider

struct Hairline: View {
    let color: Color
    var body: some View {
        Rectangle().fill(color).frame(height: 1)
    }
}
