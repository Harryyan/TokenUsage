import SwiftUI

struct BlockCard: View {
    let block: ActiveBlock
    let palette: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                LabelText(text: "5H BLOCK", color: palette.textSecondary, tracking: 2)
                Spacer()
                Text(verbatim: "\(Int((block.progressPercent * 100).rounded()))% ELAPSED")
                    .font(.spaceMono(10))
                    .tracking(0.6)
                    .foregroundStyle(palette.textDisabled)
            }

            VStack(spacing: 7) {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    row(
                        label: "RESETS IN",
                        value: countdown(to: block.endTime, from: ctx.date),
                        emphasize: true
                    )
                }
                row(
                    label: "SPENT",
                    value: CostFormatter.standard(block.costUSD),
                    emphasize: false
                )
                if let projected = block.projectedCostUSD {
                    row(
                        label: "PROJECTED",
                        value: CostFormatter.standard(projected),
                        emphasize: false
                    )
                }
            }

            SegmentedBar(progress: block.progressPercent, palette: palette)
                .padding(.top, 2)
        }
    }

    private func row(label: LocalizedStringKey, value: String, emphasize: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            LabelText(text: label, color: palette.textSecondary, tracking: 1.4)
            Spacer()
            Text(verbatim: value)
                .font(.spaceMono(emphasize ? 16 : 13, weight: emphasize ? .bold : .regular))
                .tracking(emphasize ? 1.0 : 0)
                .foregroundStyle(palette.textDisplay)
                .monospacedDigit()
        }
    }

    private func countdown(to end: Date, from now: Date) -> String {
        let total = max(0, Int(end.timeIntervalSince(now)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
