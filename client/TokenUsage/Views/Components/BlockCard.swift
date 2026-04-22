import SwiftUI

struct BlockCard: View {
    @EnvironmentObject var theme: ThemeManager
    let block: ActiveBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PixelSectionHeader(text: "5H BLOCK")

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 8) {
                    progressBar
                    Text(verbatim: "\(Int(block.progressPercent * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(barColor)
                        .frame(width: 40, alignment: .trailing)
                }

                HStack(alignment: .top, spacing: 8) {
                    metricColumn(
                        label: "SPENT",
                        value: CostFormatter.standard(block.costUSD),
                        color: theme.text
                    )
                    Spacer(minLength: 4)
                    if let projected = block.projectedCostUSD {
                        metricColumn(
                            label: "PROJECTED",
                            value: CostFormatter.standard(projected),
                            color: theme.textDim
                        )
                        Spacer(minLength: 4)
                    }
                    metricColumn(
                        label: "LEFT",
                        value: "\(block.remainingMinutes)m",
                        color: barColor
                    )
                }
            }
            .pixelFrame(accent: barColor.opacity(0.5))
        }
    }

    private func metricColumn(label: LocalizedStringKey, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.textMuted)
            Text(verbatim: value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(theme.bg)
                Rectangle()
                    .fill(barColor)
                    .frame(width: max(geo.size.width * block.progressPercent, 0))
            }
        }
        .frame(height: 10)
        .border(theme.borderDim, width: 1)
        .padding(1)
        .border(theme.borderBright, width: 1)
    }

    private var barColor: Color {
        switch block.progressPercent {
        case ..<0.3: return theme.statusGreen
        case ..<0.7: return theme.accent
        case ..<0.9: return theme.cacheWrite
        default: return theme.statusRed
        }
    }
}
