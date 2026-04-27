import SwiftUI
import AppKit

struct UsageDetailView: View {
    @ObservedObject var viewModel: UsageViewModel
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.colorScheme) private var systemScheme
    @State private var hoveredBarIdx: Int?

    private var palette: Palette { theme.palette(for: systemScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleRow
                .padding(.bottom, 18)
            periodNav
                .padding(.bottom, 28)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                        .padding(.bottom, 24)

                    if hasChartData {
                        chart
                            .padding(.bottom, 22)
                    }

                    breakdown
                        .padding(.bottom, 20)

                    if let block = viewModel.activeBlock {
                        Hairline(color: palette.border)
                            .padding(.bottom, 20)
                        BlockCard(
                            block: block,
                            liveUsage: viewModel.oauthLimits,
                            palette: palette
                        )
                        .padding(.bottom, 20)
                    }

                    if let limits = viewModel.oauthLimits {
                        Hairline(color: palette.border)
                            .padding(.bottom, 20)
                        WeeklyRow(limits: limits, palette: palette)
                            .padding(.bottom, 20)
                    }

                    if !viewModel.currentPeriodUsage.modelBreakdowns.isEmpty {
                        Hairline(color: palette.border)
                            .padding(.bottom, 20)
                        models
                            .padding(.bottom, 14)
                    }
                }
            }
            .frame(maxHeight: 380)

            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 16)
        .frame(width: 340)
        .background(palette.bg)
        .foregroundStyle(palette.textPrimary)
        .preferredColorScheme(theme.preferredColorScheme)
    }

    // MARK: - Title row

    private var titleRow: some View {
        HStack(spacing: 0) {
            Text(verbatim: "TOKENUSAGE")
                .font(.spaceMono(11, weight: .bold))
                .tracking(2.6)
                .foregroundStyle(palette.textSecondary)

            Spacer()

            settingsMenu
                .padding(.trailing, 4)

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.textPrimary)
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.refreshState.isLoading)
        }
    }

    private var settingsMenu: some View {
        Menu {
            Picker("Display Mode", selection: Binding(
                get: { viewModel.menuBarDisplayMode },
                set: { viewModel.setDisplayMode($0) }
            )) {
                ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.displayKey).tag(mode)
                }
            }
            .pickerStyle(.inline)

            Picker("Appearance", selection: $theme.mode) {
                ForEach(AppearanceMode.allCases) { m in
                    Text(m.displayKey).tag(m)
                }
            }
            .pickerStyle(.inline)

            Menu("Language") {
                Picker("Language", selection: Binding(
                    get: { AppLanguageManager.current },
                    set: { AppLanguageManager.setAndRelaunch($0) }
                )) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayKey).tag(lang)
                    }
                }
                .pickerStyle(.inline)
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.textPrimary)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .frame(width: 26)
    }

    // MARK: - Period nav

    private var periodNav: some View {
        HStack(spacing: 18) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                let active = viewModel.selectedPeriod == period
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        viewModel.selectedPeriod = period
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(period.tabLabel)
                            .font(.spaceMono(10, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(active ? palette.textDisplay : palette.textDisabled)
                            .textCase(.uppercase)
                        Circle()
                            .fill(active ? palette.accent : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Hero

    private var hero: some View {
        let usage = viewModel.currentPeriodUsage
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(verbatim: "$")
                    .font(.doto(30))
                    .foregroundStyle(palette.textDisplay)
                    .padding(.trailing, 4)
                Text(verbatim: heroAmount(usage.totalCost))
                    .font(.doto(56))
                    .foregroundStyle(palette.textDisplay)
            }

            HStack(spacing: 6) {
                Text(verbatim: "\(TokenFormatter.abbreviated(usage.totalTokens)) TOKENS")
                Text(verbatim: "·")
                    .foregroundStyle(palette.textDisabled)
                Text(viewModel.selectedPeriod.tabLabel)
            }
            .font(.spaceMono(10))
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(palette.textSecondary)
        }
    }

    private func heroAmount(_ cost: Double) -> String {
        if cost >= 10_000 {
            return String(format: "%.0fK", cost / 1_000)
        } else if cost >= 1_000 {
            return String(format: "%.1fK", cost / 1_000)
        }
        return String(format: "%.2f", cost)
    }

    // MARK: - 7-day chart

    private var hasChartData: Bool {
        viewModel.last7Days.contains(where: { $0.cost > 0 })
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                chartLeftReadout
                Spacer()
                chartRightReadout
            }
            MiniBarChart(
                data: viewModel.last7Days,
                palette: palette,
                hoveredIndex: $hoveredBarIdx
            )
        }
    }

    @ViewBuilder
    private var chartLeftReadout: some View {
        if let idx = hoveredBarIdx, idx < viewModel.last7Days.count {
            let point = viewModel.last7Days[idx]
            let isToday = idx == viewModel.last7Days.count - 1
            Text(verbatim: Self.weekdayLabel(point.date, isToday: isToday))
                .font(.spaceMono(10))
                .tracking(1.6)
                .foregroundStyle(palette.textPrimary)
        } else {
            LabelText(text: "7-DAY", color: palette.textSecondary, tracking: 1.6)
        }
    }

    @ViewBuilder
    private var chartRightReadout: some View {
        if let idx = hoveredBarIdx, idx < viewModel.last7Days.count {
            let point = viewModel.last7Days[idx]
            HStack(spacing: 8) {
                Text(verbatim: TokenFormatter.abbreviated(point.tokens))
                    .foregroundStyle(palette.textDisabled)
                Text(verbatim: CostFormatter.standard(point.cost))
                    .foregroundStyle(palette.textPrimary)
            }
            .font(.spaceMono(10))
            .tracking(0.4)
        } else {
            Text(verbatim: "AVG \(CostFormatter.standard(viewModel.last7DaysAvgCost))")
                .font(.spaceMono(10))
                .tracking(0.4)
                .foregroundStyle(palette.textDisabled)
        }
    }

    private static func weekdayLabel(_ dateStr: String, isToday: Bool) -> String {
        if isToday { return "TODAY" }
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE d"
        if let date = parser.date(from: dateStr) {
            return formatter.string(from: date).uppercased()
        }
        return dateStr.uppercased()
    }

    // MARK: - Breakdown

    private var breakdown: some View {
        let usage = viewModel.currentPeriodUsage
        return VStack(spacing: 9) {
            statRow("Input", value: TokenFormatter.abbreviated(usage.inputTokens))
            statRow("Output", value: TokenFormatter.abbreviated(usage.outputTokens))
            statRow("Cache Write", value: TokenFormatter.abbreviated(usage.cacheCreationTokens))
            statRow("Cache Read", value: TokenFormatter.abbreviated(usage.cacheReadTokens))
        }
    }

    private func statRow(_ label: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            LabelText(text: label, color: palette.textSecondary, tracking: 1.4)
            Spacer()
            Text(verbatim: value)
                .font(.spaceMono(12))
                .foregroundStyle(palette.textPrimary)
                .monospacedDigit()
        }
    }

    // MARK: - Models

    private var models: some View {
        VStack(alignment: .leading, spacing: 11) {
            LabelText(text: "MODELS", color: palette.textSecondary, tracking: 1.8)
                .padding(.bottom, 4)
            ForEach(Array(viewModel.currentPeriodUsage.modelBreakdowns.prefix(5).enumerated()), id: \.element.id) { idx, b in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Rectangle()
                        .fill(palette.textDisplay)
                        .opacity(idx == 0 ? 1.0 : (idx == 1 ? 0.55 : 0.28))
                        .frame(width: 6, height: 6)
                    Text(Self.shortModelName(b.modelName))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(verbatim: CostFormatter.standard(b.cost))
                        .font(.spaceMono(13))
                        .foregroundStyle(palette.textDisplay)
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Hairline(color: palette.border)
            HStack {
                HStack(spacing: 7) {
                    StatusDot(
                        color: statusColor,
                        size: 6,
                        pulsing: viewModel.refreshState == .success
                    )
                    if viewModel.snapshot.lastUpdated != .distantPast {
                        TimelineView(.periodic(from: .now, by: 60)) { _ in
                            Text("Synced \(DateFormatters.relativeTime(from: viewModel.snapshot.lastUpdated))")
                                .font(.spaceMono(9))
                                .tracking(1.6)
                                .textCase(.uppercase)
                                .foregroundStyle(palette.textDisabled)
                        }
                    } else {
                        Text(verbatim: "INITIALIZING")
                            .font(.spaceMono(9))
                            .tracking(1.6)
                            .foregroundStyle(palette.textDisabled)
                    }
                }
                Spacer()
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .font(.spaceMono(9))
                        .tracking(2.0)
                        .foregroundStyle(palette.textSecondary)
                        .textCase(.uppercase)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch viewModel.refreshState {
        case .success: return palette.accent
        case .failed: return palette.error
        case .loading, .refreshing: return palette.warning
        case .idle: return palette.textDisabled
        }
    }

    private static func shortModelName(_ name: String) -> String {
        name
            .replacingOccurrences(of: "claude-", with: "")
            .replacingOccurrences(of: "-20251001", with: "")
    }
}

private extension TimePeriod {
    var tabLabel: LocalizedStringKey {
        switch self {
        case .today: return "TODAY"
        case .week: return "WEEK"
        case .month: return "MONTH"
        case .total: return "ALL"
        }
    }
}
