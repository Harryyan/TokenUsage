import SwiftUI

struct BlockCard: View {
    let block: ActiveBlock
    let liveUsage: AnthropicUsageService.Limits?
    let palette: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                LabelText(text: "5H BLOCK", color: palette.textSecondary, tracking: 2)
                Spacer()
                Text(verbatim: headerSuffix)
                    .font(.spaceMono(10))
                    .tracking(0.6)
                    .foregroundStyle(headerColor)
            }

            VStack(spacing: 7) {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    row(
                        label: "RESETS IN",
                        value: countdown(to: effectiveResetAt, from: ctx.date),
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

            SegmentedBar(
                progress: barProgress,
                palette: palette,
                fill: barColor
            )
            .padding(.top, 2)
        }
    }

    // MARK: - Data resolution (OAuth API > ccusage > fallback)

    private var fivePercent: Double? {
        if let live = liveUsage { return live.fiveHourPercent }
        if let usage = block.usage { return usage.currentPercent * 100 }
        return nil
    }

    private var effectiveResetAt: Date {
        liveUsage?.fiveHourResetAt ?? block.endTime
    }

    private var statusForBar: BlockUsageStatus {
        guard let pct = fivePercent else { return .ok }
        if pct >= 100 { return .exceeded }
        if pct >= 80 { return .warning }
        return .ok
    }

    private var headerSuffix: String {
        if let pct = fivePercent {
            return "\(Int(pct.rounded()))% USED"
        }
        return "\(Int((block.progressPercent * 100).rounded()))% ELAPSED"
    }

    private var headerColor: Color {
        switch statusForBar {
        case .ok: return palette.textDisabled
        case .warning: return palette.warning
        case .exceeded: return palette.error
        }
    }

    private var barProgress: Double {
        if let pct = fivePercent { return min(1, pct / 100) }
        return block.progressPercent
    }

    private var barColor: Color {
        switch statusForBar {
        case .ok: return palette.textDisplay
        case .warning: return palette.warning
        case .exceeded: return palette.error
        }
    }

    // MARK: - Row helper

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

// MARK: - Weekly (7-day) row

struct WeeklyRow: View {
    let limits: AnthropicUsageService.Limits
    let palette: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                LabelText(text: "WEEKLY", color: palette.textSecondary, tracking: 2)
                Spacer()
                Text(verbatim: "\(Int(limits.sevenDayPercent.rounded()))% USED")
                    .font(.spaceMono(10))
                    .tracking(0.6)
                    .foregroundStyle(headerColor)
            }
            if let resetAt = limits.sevenDayResetAt {
                TimelineView(.periodic(from: .now, by: 60)) { ctx in
                    HStack(alignment: .firstTextBaseline) {
                        LabelText(text: "RESETS IN", color: palette.textSecondary, tracking: 1.4)
                        Spacer()
                        Text(verbatim: relative(to: resetAt, from: ctx.date))
                            .font(.spaceMono(13))
                            .foregroundStyle(palette.textDisplay)
                            .monospacedDigit()
                    }
                }
            }
            SegmentedBar(
                progress: min(1, limits.sevenDayPercent / 100),
                palette: palette,
                fill: barColor
            )
        }
    }

    private var status: BlockUsageStatus {
        if limits.sevenDayPercent >= 100 { return .exceeded }
        if limits.sevenDayPercent >= 80 { return .warning }
        return .ok
    }

    private var headerColor: Color {
        switch status {
        case .ok: return palette.textDisabled
        case .warning: return palette.warning
        case .exceeded: return palette.error
        }
    }

    private var barColor: Color {
        switch status {
        case .ok: return palette.textDisplay
        case .warning: return palette.warning
        case .exceeded: return palette.error
        }
    }

    private func relative(to target: Date, from now: Date) -> String {
        let total = max(0, Int(target.timeIntervalSince(now)))
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let mins = (total % 3600) / 60
        if days > 0 { return String(format: "%dD %dH", days, hours) }
        if hours > 0 { return String(format: "%dH %dM", hours, mins) }
        return String(format: "%dM", mins)
    }
}
