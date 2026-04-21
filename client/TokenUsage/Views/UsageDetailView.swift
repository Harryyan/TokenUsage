import SwiftUI

struct UsageDetailView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            PixelDivider()
            periodTabs
            PixelDivider()
            ScrollView {
                VStack(spacing: 12) {
                    heroCard
                    if !viewModel.currentPeriodUsage.modelBreakdowns.isEmpty {
                        modelSection
                    }
                    if viewModel.selectedPeriod != .today {
                        averageSection
                    }
                }
                .padding(12)
            }
            .frame(maxHeight: 380)
            PixelDivider()
            footerSection
        }
        .frame(width: 360)
        .background(Pixel.bg)
        .foregroundStyle(Pixel.text)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("★")
                        .foregroundStyle(Pixel.gold)
                    Text("CLAUDE CODE USAGE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                HStack(spacing: 5) {
                    Text("●")
                        .font(.system(size: 7))
                        .foregroundStyle(statusColor)
                    if viewModel.snapshot.lastUpdated != .distantPast {
                        Text("Synced \(DateFormatters.relativeTime(from: viewModel.snapshot.lastUpdated))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Pixel.textMuted)
                    }
                }
            }
            Spacer()
            HStack(spacing: 6) {
                pixelButton("↻") {
                    Task { await viewModel.refresh() }
                }
                .disabled(viewModel.refreshState.isLoading)

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
                    Text("⚙")
                        .font(.system(size: 13))
                        .foregroundStyle(Pixel.textDim)
                        .frame(width: 24, height: 24)
                        .background(Pixel.panel)
                        .border(Pixel.borderDim, width: 1)
                }
                .buttonStyle(.plain)
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func pixelButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Pixel.textDim)
                .frame(width: 24, height: 24)
                .background(Pixel.panel)
                .border(Pixel.borderDim, width: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Period Tabs

    private var periodTabs: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                let active = viewModel.selectedPeriod == period
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.selectedPeriod = period
                    }
                } label: {
                    HStack(spacing: 4) {
                        if active {
                            Text("▶")
                                .font(.system(size: 8))
                                .foregroundStyle(Pixel.gold)
                        }
                        Text(period.tabLabel)
                            .font(.system(size: 11, weight: active ? .bold : .regular, design: .monospaced))
                            .foregroundStyle(active ? Pixel.gold : Pixel.textDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(active ? Pixel.gold.opacity(0.08) : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        let usage = viewModel.currentPeriodUsage

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("◆").foregroundStyle(Pixel.gold)
                Text("SCORE").foregroundStyle(Pixel.gold.opacity(0.7))
                Text("◆").foregroundStyle(Pixel.gold)
                Spacer()
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))

            Text(CostFormatter.standard(usage.totalCost))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(Pixel.gold)
                .shadow(color: Pixel.gold.opacity(0.4), radius: 12)

            HStack {
                Text(TokenFormatter.precise(usage.totalTokens))
                    .foregroundStyle(Pixel.text)
                Text("tokens")
                    .foregroundStyle(Pixel.textDim)
                Spacer()
                Text(TokenFormatter.abbreviated(usage.totalTokens))
                    .foregroundStyle(Pixel.textDim)
            }
            .font(.system(size: 12, design: .monospaced))

            PixelBar(
                input: usage.inputTokens,
                output: usage.outputTokens,
                cacheWrite: usage.cacheCreationTokens,
                cacheRead: usage.cacheReadTokens
            )
            .padding(.vertical, 2)

            VStack(spacing: 4) {
                TokenBreakdownRow(label: "Input", tokens: usage.inputTokens, color: Pixel.inputBlue)
                TokenBreakdownRow(label: "Output", tokens: usage.outputTokens, color: Pixel.outputPurple)
                TokenBreakdownRow(label: "Cache W", tokens: usage.cacheCreationTokens, color: Pixel.cacheOrange)
                TokenBreakdownRow(label: "Cache R", tokens: usage.cacheReadTokens, color: Pixel.cacheCyan)
            }
        }
        .pixelFrame(accent: Pixel.gold.opacity(0.5))
    }

    // MARK: - Models

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            PixelSectionHeader(text: "Models")

            VStack(spacing: 4) {
                ForEach(viewModel.currentPeriodUsage.modelBreakdowns) { b in
                    let total = b.inputTokens + b.outputTokens
                        + b.cacheCreationTokens + b.cacheReadTokens
                    HStack {
                        Text(Self.shortModelName(b.modelName))
                            .lineLimit(1)
                        Spacer()
                        Text(TokenFormatter.abbreviated(total))
                            .monospacedDigit()
                        Text(CostFormatter.standard(b.cost))
                            .foregroundStyle(Pixel.gold.opacity(0.7))
                            .frame(width: 64, alignment: .trailing)
                    }
                    .font(.system(size: 11, design: .monospaced))
                }
            }
            .pixelFrame()
        }
    }

    // MARK: - Average

    private var averageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            PixelSectionHeader(text: "Daily Avg")

            HStack {
                HStack(spacing: 4) {
                    Text("#").foregroundStyle(Pixel.inputBlue)
                    Text(TokenFormatter.abbreviated(viewModel.currentPeriodUsage.averageDailyTokens))
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("$").foregroundStyle(Pixel.gold)
                    Text(CostFormatter.standard(viewModel.currentPeriodUsage.averageDailyCost))
                }
            }
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .pixelFrame()
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 6) {
            Text("★").foregroundStyle(Pixel.gold)
            Text("LIFETIME").foregroundStyle(Pixel.textMuted)
            Spacer()
            Text(TokenFormatter.abbreviated(viewModel.snapshot.total.totalTokens))
                .foregroundStyle(Pixel.textDim)
            Text("·").foregroundStyle(Pixel.textMuted)
            Text(CostFormatter.standard(viewModel.snapshot.total.totalCost))
                .foregroundStyle(Pixel.gold.opacity(0.7))
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch viewModel.refreshState {
        case .success: return Pixel.green
        case .failed: return Pixel.red
        case .loading, .refreshing: return Pixel.amber
        case .idle: return Pixel.textMuted
        }
    }

    private static func shortModelName(_ name: String) -> String {
        name.replacingOccurrences(of: "claude-", with: "")
            .replacingOccurrences(of: "-20251001", with: "")
    }
}

private extension TimePeriod {
    var tabLabel: String {
        switch self {
        case .today: return "TODAY"
        case .week: return "WEEK"
        case .month: return "MONTH"
        case .total: return "ALL"
        }
    }
}
