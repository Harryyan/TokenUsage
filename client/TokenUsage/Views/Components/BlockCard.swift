import SwiftUI

struct BlockCard: View {
    @EnvironmentObject var theme: ThemeManager
    let block: ActiveBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PixelSectionHeader(text: "5H BLOCK")

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("RESETS IN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.textMuted)
                    Text(verbatim: "\(block.remainingMinutes)m")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.accent)
                    Spacer()
                    Text(verbatim: "· \(resetClock)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(theme.textDim)
                }

                progressBar

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
                    }
                }
            }
            .pixelFrame(accent: theme.accent.opacity(0.5))
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
                    .fill(theme.accent)
                    .frame(width: max(geo.size.width * block.progressPercent, 0))
            }
        }
        .frame(height: 6)
        .border(theme.borderDim, width: 1)
    }

    private var resetClock: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: block.endTime)
    }
}
