import Foundation
import SwiftUI

// MARK: - ccusage JSON Response Models

struct DailyResponse: Codable {
    let daily: [DailyEntry]
    let totals: UsageTotals
}

struct WeeklyResponse: Codable {
    let weekly: [WeeklyEntry]
    let totals: UsageTotals
}

struct MonthlyResponse: Codable {
    let monthly: [MonthlyEntry]
    let totals: UsageTotals
}

struct DailyEntry: Codable, Identifiable {
    var id: String { date }
    let date: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let totalTokens: Int
    let totalCost: Double
    let modelsUsed: [String]
    let modelBreakdowns: [ModelBreakdown]
}

struct WeeklyEntry: Codable, Identifiable {
    var id: String { week }
    let week: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let totalTokens: Int
    let totalCost: Double
    let modelsUsed: [String]
    let modelBreakdowns: [ModelBreakdown]
}

struct MonthlyEntry: Codable, Identifiable {
    var id: String { month }
    let month: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let totalTokens: Int
    let totalCost: Double
    let modelsUsed: [String]
    let modelBreakdowns: [ModelBreakdown]
}

struct ModelBreakdown: Codable, Identifiable {
    var id: String { modelName }
    let modelName: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let cost: Double
}

struct UsageTotals: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let totalCost: Double
    let totalTokens: Int
}

struct BlocksResponse: Codable {
    let blocks: [BlockEntry]
}

struct BlockEntry: Codable {
    let id: String
    let startTime: String
    let endTime: String
    let isActive: Bool
    let isGap: Bool
    let totalTokens: Int
    let costUSD: Double
    let burnRate: BlockBurnRate?
    let projection: BlockProjection?
    let tokenLimitStatus: TokenLimitStatus?
}

struct TokenLimitStatus: Codable {
    let limit: Int
    let projectedUsage: Int
    let percentUsed: Double
    let status: String
}

struct BlockBurnRate: Codable {
    let tokensPerMinute: Double
    let costPerHour: Double
}

struct BlockProjection: Codable {
    let totalTokens: Int
    let totalCost: Double
    let remainingMinutes: Int
}

struct ActiveBlock: Equatable {
    let startTime: Date
    let endTime: Date
    let progressPercent: Double  // time elapsed in 5h window
    let costUSD: Double
    let projectedCostUSD: Double?
    let costPerHour: Double?
    let usage: BlockUsage?
}

struct BlockUsage: Equatable {
    let totalTokens: Int
    let limit: Int
    let projectedTokens: Int
    let status: BlockUsageStatus

    var currentPercent: Double {
        guard limit > 0 else { return 0 }
        return Double(totalTokens) / Double(limit)
    }

    var projectedPercent: Double {
        guard limit > 0 else { return 0 }
        return Double(projectedTokens) / Double(limit)
    }
}

enum BlockUsageStatus: String {
    case ok
    case warning
    case exceeded

    init(raw: String) {
        switch raw.lowercased() {
        case "warning": self = .warning
        case "exceeded": self = .exceeded
        default: self = .ok
        }
    }
}

// MARK: - App Display Models

struct UsageSnapshot {
    let today: PeriodUsage
    let week: PeriodUsage
    let month: PeriodUsage
    let total: PeriodUsage
    let lastUpdated: Date

    static let empty = UsageSnapshot(
        today: .empty,
        week: .empty,
        month: .empty,
        total: .empty,
        lastUpdated: .distantPast
    )
}

struct PeriodUsage {
    let totalTokens: Int
    let totalCost: Double
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let days: Int
    let modelBreakdowns: [ModelBreakdown]
    let dailyData: [DailyDataPoint]

    var averageDailyTokens: Int {
        guard days > 0 else { return 0 }
        return totalTokens / days
    }

    var averageDailyCost: Double {
        guard days > 0 else { return 0 }
        return totalCost / Double(days)
    }

    static let empty = PeriodUsage(
        totalTokens: 0,
        totalCost: 0,
        inputTokens: 0,
        outputTokens: 0,
        cacheCreationTokens: 0,
        cacheReadTokens: 0,
        days: 0,
        modelBreakdowns: [],
        dailyData: []
    )
}

struct DailyDataPoint: Identifiable {
    let id = UUID()
    let date: String
    let tokens: Int
    let cost: Double
}

// MARK: - Refresh State

enum RefreshState: Equatable {
    case idle
    case loading
    case refreshing
    case success
    case failed(String)

    var isLoading: Bool {
        switch self {
        case .loading, .refreshing: return true
        default: return false
        }
    }

    var statusText: String {
        switch self {
        case .idle: return "Idle"
        case .loading: return "Loading..."
        case .refreshing: return "Refreshing..."
        case .success: return "Updated"
        case .failed(let msg): return "Failed: \(msg)"
        }
    }

    var statusIcon: String {
        switch self {
        case .idle: return "circle"
        case .loading, .refreshing: return "arrow.triangle.2.circlepath"
        case .success: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Menu Bar Display Mode

enum MenuBarDisplayMode: String, CaseIterable {
    case tokenOnly = "Token Only"
    case tokenAndCost = "Token + Cost"
    case costOnly = "Cost Only"

    var displayKey: LocalizedStringKey {
        switch self {
        case .tokenOnly: return "Token Only"
        case .tokenAndCost: return "Token + Cost"
        case .costOnly: return "Cost Only"
        }
    }
}

enum TimePeriod: String, CaseIterable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case total = "Total"
}
