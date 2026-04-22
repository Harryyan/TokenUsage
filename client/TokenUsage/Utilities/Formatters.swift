import Foundation

enum TokenFormatter {
    static func abbreviated(_ value: Int) -> String {
        let absValue = abs(value)
        switch absValue {
        case 0..<1_000:
            return "\(value)"
        case 1_000..<10_000:
            let k = Double(value) / 1_000
            return String(format: "%.1fK", k)
        case 10_000..<1_000_000:
            let k = Double(value) / 1_000
            if k == k.rounded(.down) {
                return String(format: "%.0fK", k)
            }
            return String(format: "%.1fK", k)
        case 1_000_000..<10_000_000:
            let m = Double(value) / 1_000_000
            return String(format: "%.2fM", m)
        case 10_000_000..<1_000_000_000:
            let m = Double(value) / 1_000_000
            if m == m.rounded(.down) {
                return String(format: "%.0fM", m)
            }
            return String(format: "%.1fM", m)
        default:
            let b = Double(value) / 1_000_000_000
            return String(format: "%.2fB", b)
        }
    }

    static func precise(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

enum CostFormatter {
    static func abbreviated(_ value: Double) -> String {
        let absValue = abs(value)
        switch absValue {
        case 0..<0.01:
            return "$0.00"
        case 0.01..<10:
            return String(format: "$%.2f", value)
        case 10..<100:
            return String(format: "$%.1f", value)
        case 100..<1_000:
            return String(format: "$%.0f", value)
        case 1_000..<10_000:
            return String(format: "$%.1fK", value / 1_000)
        default:
            return String(format: "$%.0fK", value / 1_000)
        }
    }

    static func precise(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.4f", value)
    }

    static func standard(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

enum DurationFormatter {
    static func humanized(seconds totalSeconds: Int) -> String {
        let s = max(0, totalSeconds)
        let hours = s / 3600
        let mins = (s % 3600) / 60
        let secs = s % 60

        if hours > 0 && mins > 0 {
            return String(
                format: NSLocalizedString("%lldh %lldm", comment: "duration: hours and minutes"),
                hours, mins
            )
        } else if hours > 0 {
            return String(
                format: NSLocalizedString("%lldh", comment: "duration: hours"),
                hours
            )
        } else if mins > 0 {
            return String(
                format: NSLocalizedString("%lldm", comment: "duration: minutes"),
                mins
            )
        } else {
            return String(
                format: NSLocalizedString("%llds", comment: "duration: seconds"),
                secs
            )
        }
    }
}

enum DateFormatters {
    static func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    static func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
