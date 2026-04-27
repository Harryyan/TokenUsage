import Foundation
import SwiftUI
import Combine

@MainActor
final class UsageViewModel: ObservableObject {
    @Published var snapshot: UsageSnapshot = .empty
    @Published var refreshState: RefreshState = .idle
    @Published var selectedPeriod: TimePeriod = .today
    @Published var menuBarDisplayMode: MenuBarDisplayMode = .tokenOnly
    @Published var activeBlock: ActiveBlock?
    @Published var oauthLimits: AnthropicUsageService.Limits?

    @AppStorage("menuBarDisplayMode") private var storedDisplayMode: String = MenuBarDisplayMode.tokenOnly.rawValue

    private let service = CCUsageService()
    private let anthropic = AnthropicUsageService()
    private var refreshTimer: Timer?
    private var isRefreshing = false

    private static let refreshInterval: TimeInterval = 300

    var menuBarText: String {
        let usage = snapshot.today
        let tokens = usage.totalTokens

        switch menuBarDisplayMode {
        case .tokenOnly:
            return "◈ \(TokenFormatter.abbreviated(tokens))"
        case .tokenAndCost:
            return "◈ \(TokenFormatter.abbreviated(tokens)) · \(CostFormatter.abbreviated(usage.totalCost))"
        case .costOnly:
            return "◈ \(CostFormatter.abbreviated(usage.totalCost))"
        }
    }

    var currentPeriodUsage: PeriodUsage {
        switch selectedPeriod {
        case .today: return snapshot.today
        case .week: return snapshot.week
        case .month: return snapshot.month
        case .total: return snapshot.total
        }
    }

    var last7Days: [DailyDataPoint] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        var byDate: [String: DailyDataPoint] = [:]
        for entry in snapshot.total.dailyData {
            byDate[entry.date] = entry
        }
        var result: [DailyDataPoint] = []
        for offset in (0..<7).reversed() {
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = formatter.string(from: date)
            result.append(byDate[key] ?? DailyDataPoint(date: key, tokens: 0, cost: 0))
        }
        return result
    }

    var last7DaysAvgCost: Double {
        let nonEmpty = last7Days.filter { $0.cost > 0 }
        guard !nonEmpty.isEmpty else { return 0 }
        return nonEmpty.reduce(0) { $0 + $1.cost } / Double(nonEmpty.count)
    }

    /// Best estimate of current 5-hour usage (0–100). Prefers OAuth API,
    /// falls back to ccusage's empirical max-token estimate, then nil.
    var currentUsagePercent: Double? {
        if let oauth = oauthLimits {
            return oauth.fiveHourPercent
        }
        if let usage = activeBlock?.usage {
            return usage.currentPercent * 100
        }
        return nil
    }

    init() {
        if let mode = MenuBarDisplayMode(rawValue: storedDisplayMode) {
            menuBarDisplayMode = mode
        }
        startAutoRefresh()
        Task { await refresh() }
    }

    func refresh(silent: Bool = false) async {
        guard !isRefreshing else { return }
        isRefreshing = true

        let isFirstLoad = snapshot.lastUpdated == .distantPast
        if !silent || isFirstLoad {
            refreshState = isFirstLoad ? .loading : .refreshing
        }

        do {
            let allData = try await service.fetchAll()
            let now = Date()
            let cal = Calendar.current
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let todayStr = dateFormatter.string(from: now)

            let startOfWeekDate = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let startOfWeekStr = dateFormatter.string(from: startOfWeekDate)

            let startOfMonthDate = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let startOfMonthStr = dateFormatter.string(from: startOfMonthDate)

            let todayEntries = allData.daily.filter { $0.date >= todayStr }
            let weekEntries = allData.daily.filter { $0.date >= startOfWeekStr }
            let monthEntries = allData.daily.filter { $0.date >= startOfMonthStr }

            snapshot = UsageSnapshot(
                today: Self.buildPeriodUsage(from: todayEntries, periodDays: 1),
                week: Self.buildPeriodUsage(from: weekEntries, periodDays: Self.daysInCurrentWeek()),
                month: Self.buildPeriodUsage(from: monthEntries, periodDays: Self.daysInCurrentMonth()),
                total: Self.buildPeriodUsage(from: allData.daily, periodDays: Self.totalDays(from: allData)),
                lastUpdated: Date()
            )

            activeBlock = try? await fetchActiveBlock()

            // Pull authoritative rate-limit utilization from Anthropic OAuth API.
            // Silent fallback to ccusage data if unavailable (no Claude Code login,
            // custom endpoint, network error, etc.).
            oauthLimits = try? await anthropic.fetch()

            refreshState = .success
        } catch {
            refreshState = .failed(error.localizedDescription)
        }

        isRefreshing = false
    }

    private func fetchActiveBlock() async throws -> ActiveBlock? {
        let response = try await service.fetchActiveBlock()
        guard let block = response.blocks.first(where: { $0.isActive && !$0.isGap }) else {
            return nil
        }

        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let start = parser.date(from: block.startTime),
              let end = parser.date(from: block.endTime) else {
            return nil
        }

        let now = Date()
        let totalSec = end.timeIntervalSince(start)
        let elapsedSec = max(0, now.timeIntervalSince(start))
        let progress = totalSec > 0 ? min(1.0, elapsedSec / totalSec) : 0

        let usage: BlockUsage? = block.tokenLimitStatus.map { tls in
            BlockUsage(
                totalTokens: block.totalTokens,
                limit: tls.limit,
                projectedTokens: tls.projectedUsage,
                status: BlockUsageStatus(raw: tls.status)
            )
        }

        return ActiveBlock(
            startTime: start,
            endTime: end,
            progressPercent: progress,
            costUSD: block.costUSD,
            projectedCostUSD: block.projection?.totalCost,
            costPerHour: block.burnRate?.costPerHour,
            usage: usage
        )
    }

    func setDisplayMode(_ mode: MenuBarDisplayMode) {
        menuBarDisplayMode = mode
        storedDisplayMode = mode.rawValue
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refresh(silent: true)
            }
        }
    }

    private static func buildPeriodUsage(from entries: [DailyEntry], periodDays: Int) -> PeriodUsage {
        let allBreakdowns = entries.flatMap { $0.modelBreakdowns }
        let merged = mergeBreakdowns(allBreakdowns)
        let dailyData = entries.map {
            DailyDataPoint(date: $0.date, tokens: $0.totalTokens, cost: $0.totalCost)
        }

        return PeriodUsage(
            totalTokens: entries.reduce(0) { $0 + $1.totalTokens },
            totalCost: entries.reduce(0) { $0 + $1.totalCost },
            inputTokens: entries.reduce(0) { $0 + $1.inputTokens },
            outputTokens: entries.reduce(0) { $0 + $1.outputTokens },
            cacheCreationTokens: entries.reduce(0) { $0 + $1.cacheCreationTokens },
            cacheReadTokens: entries.reduce(0) { $0 + $1.cacheReadTokens },
            days: max(periodDays, 1),
            modelBreakdowns: merged,
            dailyData: dailyData
        )
    }

    private static func mergeBreakdowns(_ breakdowns: [ModelBreakdown]) -> [ModelBreakdown] {
        var dict: [String: (input: Int, output: Int, cacheCreate: Int, cacheRead: Int, cost: Double)] = [:]
        for b in breakdowns {
            var existing = dict[b.modelName, default: (0, 0, 0, 0, 0)]
            existing.input += b.inputTokens
            existing.output += b.outputTokens
            existing.cacheCreate += b.cacheCreationTokens
            existing.cacheRead += b.cacheReadTokens
            existing.cost += b.cost
            dict[b.modelName] = existing
        }
        return dict.map { name, val in
            ModelBreakdown(
                modelName: name,
                inputTokens: val.input,
                outputTokens: val.output,
                cacheCreationTokens: val.cacheCreate,
                cacheReadTokens: val.cacheRead,
                cost: val.cost
            )
        }.sorted { $0.cost > $1.cost }
    }

    private static func daysInCurrentWeek() -> Int {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: Date())
        let daysSinceMonday = (weekday + 5) % 7
        return daysSinceMonday + 1
    }

    private static func daysInCurrentMonth() -> Int {
        Calendar.current.component(.day, from: Date())
    }

    private static func totalDays(from response: DailyResponse) -> Int {
        guard let first = response.daily.first?.date else { return 1 }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let startDate = formatter.date(from: first) else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 1
        return max(days, 1)
    }

    deinit {
        refreshTimer?.invalidate()
    }
}
