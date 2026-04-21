import SwiftUI

struct UsageDetailView: View {
    @ObservedObject var viewModel: UsageViewModel
    @Namespace private var tabNamespace

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().opacity(0.3)
            periodTabBar
            ScrollView {
                VStack(spacing: 14) {
                    heroCard
                    if !viewModel.currentPeriodUsage.modelBreakdowns.isEmpty {
                        modelSection
                    }
                    if viewModel.selectedPeriod != .today {
                        averageSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: 380)
            Divider().opacity(0.3)
            footerSection
        }
        .frame(width: 360)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.015), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Claude Code Usage")
                    .font(.system(size: 13, weight: .semibold))
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    if viewModel.snapshot.lastUpdated != .distantPast {
                        Text("Updated \(DateFormatters.relativeTime(from: viewModel.snapshot.lastUpdated))")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
            HStack(spacing: 4) {
                refreshButton
                settingsMenu
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var refreshButton: some View {
        Button {
            Task { await viewModel.refresh() }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.white.opacity(0.05)))
                .rotationEffect(.degrees(viewModel.refreshState.isLoading ? 360 : 0))
                .animation(
                    viewModel.refreshState.isLoading
                        ? .linear(duration: 1).repeatForever(autoreverses: false)
                        : .default,
                    value: viewModel.refreshState.isLoading
                )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.refreshState.isLoading)
    }

    private var settingsMenu: some View {
        Menu {
            ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                Button {
                    viewModel.setDisplayMode(mode)
                } label: {
                    if viewModel.menuBarDisplayMode == mode {
                        Label(mode.rawValue, systemImage: "checkmark")
                    } else {
                        Text(mode.rawValue)
                    }
                }
            }
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        } label: {
            Image(systemName: "gear")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.white.opacity(0.05)))
        }
        .buttonStyle(.plain)
        .menuStyle(.borderlessButton)
    }

    // MARK: - Period Tabs

    private var periodTabBar: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.selectedPeriod = period
                    }
                } label: {
                    Text(period.tabLabel)
                        .font(.system(size: 12, weight: viewModel.selectedPeriod == period ? .semibold : .regular))
                        .foregroundStyle(viewModel.selectedPeriod == period ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background {
                            if viewModel.selectedPeriod == period {
                                Capsule()
                                    .fill(Color.white.opacity(0.10))
                                    .matchedGeometryEffect(id: "activeTab", in: tabNamespace)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.white.opacity(0.04)))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        let usage = viewModel.currentPeriodUsage

        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(CostFormatter.standard(usage.totalCost))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.costAccent)
                    .shadow(color: Theme.costAccent.opacity(0.25), radius: 20, y: 4)

                Text("\(TokenFormatter.precise(usage.totalTokens)) tokens")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            TokenProportionBar(
                input: usage.inputTokens,
                output: usage.outputTokens,
                cacheWrite: usage.cacheCreationTokens,
                cacheRead: usage.cacheReadTokens
            )
            .padding(.vertical, 2)

            VStack(spacing: 5) {
                TokenBreakdownRow(label: "Input", tokens: usage.inputTokens, color: Theme.inputColor)
                TokenBreakdownRow(label: "Output", tokens: usage.outputTokens, color: Theme.outputColor)
                TokenBreakdownRow(label: "Cache Write", tokens: usage.cacheCreationTokens, color: Theme.cacheWriteColor)
                TokenBreakdownRow(label: "Cache Read", tokens: usage.cacheReadTokens, color: Theme.cacheReadColor)
            }
        }
        .cardStyle()
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPeriod)
    }

    // MARK: - Models

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Models")

            VStack(spacing: 6) {
                ForEach(viewModel.currentPeriodUsage.modelBreakdowns) { breakdown in
                    let total = breakdown.inputTokens + breakdown.outputTokens
                        + breakdown.cacheCreationTokens + breakdown.cacheReadTokens
                    HStack {
                        Text(Self.shortModelName(breakdown.modelName))
                            .font(.system(size: 11.5))
                            .lineLimit(1)
                        Spacer()
                        Text(TokenFormatter.abbreviated(total))
                            .font(.system(size: 11.5, design: .monospaced))
                            .monospacedDigit()
                        Text(CostFormatter.standard(breakdown.cost))
                            .font(.system(size: 11.5, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 64, alignment: .trailing)
                    }
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Average

    private var averageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Daily Average")

            HStack {
                Label {
                    Text(TokenFormatter.abbreviated(viewModel.currentPeriodUsage.averageDailyTokens))
                        .font(.system(size: 12, design: .monospaced))
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "number")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.inputColor)
                }
                Spacer()
                Label {
                    Text(CostFormatter.standard(viewModel.currentPeriodUsage.averageDailyCost))
                        .font(.system(size: 12, design: .monospaced))
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "dollarsign")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.costAccent)
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 6) {
            Text("Lifetime")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
            Spacer()
            Text(TokenFormatter.abbreviated(viewModel.snapshot.total.totalTokens))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
            Text("·")
                .foregroundStyle(.quaternary)
            Text(CostFormatter.standard(viewModel.snapshot.total.totalCost))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.costAccent.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch viewModel.refreshState {
        case .success: return .green
        case .failed: return .red
        case .loading, .refreshing: return .orange
        case .idle: return Color.secondary
        }
    }

    private static func shortModelName(_ name: String) -> String {
        name.replacingOccurrences(of: "claude-", with: "")
            .replacingOccurrences(of: "-20251001", with: "")
    }
}

// MARK: - Tab Label

private extension TimePeriod {
    var tabLabel: String {
        switch self {
        case .today: return "Today"
        case .week: return "Week"
        case .month: return "Month"
        case .total: return "All"
        }
    }
}
