import Foundation
import Security

/// Reads OAuth-derived rate-limit usage from Anthropic, the same source that
/// powers the official Claude Code statusline (claude-hud).
///
/// Pipeline:
///   1. Look up the Claude Code OAuth credential in macOS Keychain
///      (service: "Claude Code-credentials").
///   2. Decode the embedded JSON for `accessToken` / `subscriptionType` / `expiresAt`.
///   3. GET https://api.anthropic.com/api/oauth/usage with Bearer auth.
///   4. Return five-hour and seven-day utilization + reset timestamps.
///
/// Cached for 5 minutes to mirror Anthropic's usage endpoint window.
actor AnthropicUsageService {
    struct Limits: Equatable {
        let planName: String
        let fiveHourPercent: Double      // 0..100
        let sevenDayPercent: Double      // 0..100
        let fiveHourResetAt: Date?
        let sevenDayResetAt: Date?
        let fetchedAt: Date
    }

    enum FetchError: LocalizedError, Equatable {
        case noCredentials
        case credentialsExpired
        case customApiEndpoint
        case http(Int)
        case rateLimited
        case parse
        case network(String)

        var errorDescription: String? {
            switch self {
            case .noCredentials: return "Claude Code credentials not found in Keychain"
            case .credentialsExpired: return "Claude Code OAuth token expired"
            case .customApiEndpoint: return "Custom ANTHROPIC_BASE_URL set; OAuth usage API unavailable"
            case .http(let code): return "HTTP \(code) from Anthropic usage API"
            case .rateLimited: return "Rate limited by Anthropic usage API"
            case .parse: return "Failed to parse usage response"
            case .network(let msg): return "Network: \(msg)"
            }
        }
    }

    private static let serviceName = "Claude Code-credentials"
    private static let cacheTTL: TimeInterval = 5 * 60
    private static let url = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    private var cached: Limits?

    func fetch(force: Bool = false) async throws -> Limits {
        if !force, let cached, Date().timeIntervalSince(cached.fetchedAt) < Self.cacheTTL {
            return cached
        }

        if isCustomEndpoint() {
            throw FetchError.customApiEndpoint
        }

        let credentials = try readCredentials()
        let limits = try await fetchUsage(token: credentials.accessToken,
                                          subscriptionType: credentials.subscriptionType)
        self.cached = limits
        return limits
    }

    // MARK: - Custom endpoint guard

    private func isCustomEndpoint() -> Bool {
        let env = ProcessInfo.processInfo.environment
        let base = (env["ANTHROPIC_BASE_URL"] ?? env["ANTHROPIC_API_BASE_URL"] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty else { return false }
        guard let url = URL(string: base), let host = url.host else { return true }
        return host != "api.anthropic.com"
    }

    // MARK: - Keychain

    private struct Credentials {
        let accessToken: String
        let subscriptionType: String
    }

    private func readCredentials() throws -> Credentials {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw FetchError.noCredentials
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any],
              let accessToken = oauth["accessToken"] as? String,
              !accessToken.isEmpty else {
            throw FetchError.noCredentials
        }
        if let expiresAt = oauth["expiresAt"] as? Double {
            // expiresAt is unix-millis
            let expiry = Date(timeIntervalSince1970: expiresAt / 1000)
            if expiry <= Date() {
                throw FetchError.credentialsExpired
            }
        }
        let subscriptionType = (oauth["subscriptionType"] as? String) ?? ""
        return Credentials(accessToken: accessToken, subscriptionType: subscriptionType)
    }

    // MARK: - HTTP

    private func fetchUsage(token: String, subscriptionType: String) async throws -> Limits {
        var request = URLRequest(url: Self.url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("claude-code/2.1", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw FetchError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw FetchError.network("non-HTTP response")
        }
        switch http.statusCode {
        case 200: break
        case 429: throw FetchError.rateLimited
        default: throw FetchError.http(http.statusCode)
        }

        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FetchError.parse
        }
        // The usage endpoint returns a flat JSON object. Earlier internal docs
        // suggested a {data: {...}} wrapper — keep the fallback for resilience.
        let payload: [String: Any] = (root["data"] as? [String: Any]) ?? root

        let five = payload["five_hour"] as? [String: Any]
        let seven = payload["seven_day"] as? [String: Any]

        return Limits(
            planName: prettyPlanName(subscriptionType),
            fiveHourPercent: utilization(from: five?["utilization"]),
            sevenDayPercent: utilization(from: seven?["utilization"]),
            fiveHourResetAt: parseDate(five?["resets_at"]),
            sevenDayResetAt: parseDate(seven?["resets_at"]),
            fetchedAt: Date()
        )
    }

    // MARK: - Parsers

    private func utilization(from value: Any?) -> Double {
        guard let n = value as? Double else { return 0 }
        guard n.isFinite else { return 0 }
        return min(100, max(0, n))
    }

    private func parseDate(_ value: Any?) -> Date? {
        guard let s = value as? String else { return nil }
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFractional.date(from: s) { return d }
        return ISO8601DateFormatter().date(from: s)
    }

    private func prettyPlanName(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }
}
