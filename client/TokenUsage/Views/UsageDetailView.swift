import SwiftUI

struct UsageDetailView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            periodPicker
            Divider()
            periodContent
            Divider()
            footerSection
        }
        .frame(width: 340)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Claude Code Usage")
                    .font(.headline)
                HStack(spacing: 4) {
                    Image(systemName: viewModel.refreshState.statusIcon)
                        .font(.caption2)
                        .foregroundStyle(statusColor)
                    if viewModel.snapshot.lastUpdated != .distantPast {
                        Text("Updated \(DateFormatters.relativeTime(from: viewModel.snapshot.lastUpdated))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            HStack(spacing: 8) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.refreshState.isLoading)

                Menu {
                    ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                        Button {
                            viewModel.setDisplayMode(mode)
                        } label: {
                            HStack {
                                Text(mode.rawValue)
                                if viewModel.menuBarDisplayMode == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    Divider()
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                    Image(systemName: "gear")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("", selection: $viewModel.selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Period Content

    private var periodContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                primaryStats
                tokenBreakdown
                if !viewModel.currentPeriodUsage.modelBreakdowns.isEmpty {
                    modelBreakdownSection
                }
                if viewModel.selectedPeriod != .today {
                    averagesSection
                }
            }
            .padding(16)
        }
        .frame(maxHeight: 360)
    }

    private var primaryStats: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Tokens",
                value: TokenFormatter.precise(viewModel.currentPeriodUsage.totalTokens),
                subtitle: TokenFormatter.abbreviated(viewModel.currentPeriodUsage.totalTokens),
                icon: "number",
                color: .blue
            )
            StatCard(
                title: "Cost",
                value: CostFormatter.precise(viewModel.currentPeriodUsage.totalCost),
                subtitle: nil,
                icon: "dollarsign",
                color: .green
            )
        }
    }

    private var tokenBreakdown: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Token Breakdown")
                .font(.caption)
                .foregroundStyle(.secondary)

            let usage = viewModel.currentPeriodUsage
            TokenBreakdownRow(label: "Input", tokens: usage.inputTokens, color: .blue)
            TokenBreakdownRow(label: "Output", tokens: usage.outputTokens, color: .purple)
            TokenBreakdownRow(label: "Cache Write", tokens: usage.cacheCreationTokens, color: .orange)
            TokenBreakdownRow(label: "Cache Read", tokens: usage.cacheReadTokens, color: .teal)
        }
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var modelBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Model Breakdown")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(viewModel.currentPeriodUsage.modelBreakdowns) { breakdown in
                HStack {
                    Text(Self.shortModelName(breakdown.modelName))
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Text(TokenFormatter.abbreviated(breakdown.inputTokens + breakdown.outputTokens + breakdown.cacheCreationTokens + breakdown.cacheReadTokens))
                        .font(.caption)
                        .monospacedDigit()
                    Text(CostFormatter.standard(breakdown.cost))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var averagesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Daily Average")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Label {
                    Text(TokenFormatter.abbreviated(viewModel.currentPeriodUsage.averageDailyTokens))
                        .font(.caption)
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "number")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                Spacer()
                Label {
                    Text(CostFormatter.standard(viewModel.currentPeriodUsage.averageDailyCost))
                        .font(.caption)
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "dollarsign")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text("Total: \(TokenFormatter.abbreviated(viewModel.snapshot.total.totalTokens)) · \(CostFormatter.standard(viewModel.snapshot.total.totalCost))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
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
        case .idle: return .secondary
        }
    }

    private static func shortModelName(_ name: String) -> String {
        name.replacingOccurrences(of: "claude-", with: "")
            .replacingOccurrences(of: "-20251001", with: "")
    }
}
