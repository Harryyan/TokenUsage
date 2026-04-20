import Foundation

actor CCUsageService {
    private let npxPath: String

    init() {
        self.npxPath = Self.findNpxPath()
    }

    private static func findNpxPath() -> String {
        let candidates = [
            "/opt/homebrew/bin/npx",
            "/usr/local/bin/npx",
            "/usr/bin/npx"
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return "/opt/homebrew/bin/npx"
    }

    func fetchToday() async throws -> DailyResponse {
        let dateStr = Self.formatDate(Date())
        let output = try await run(["ccusage", "daily", "--json", "--since", dateStr, "--offline"])
        return try JSONDecoder().decode(DailyResponse.self, from: output)
    }

    func fetchWeek() async throws -> DailyResponse {
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let dateStr = Self.formatDate(startOfWeek)
        let output = try await run(["ccusage", "daily", "--json", "--since", dateStr, "--offline"])
        return try JSONDecoder().decode(DailyResponse.self, from: output)
    }

    func fetchMonth() async throws -> DailyResponse {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        let startOfMonth = Calendar.current.date(from: components)!
        let dateStr = Self.formatDate(startOfMonth)
        let output = try await run(["ccusage", "daily", "--json", "--since", dateStr, "--offline"])
        return try JSONDecoder().decode(DailyResponse.self, from: output)
    }

    func fetchAll() async throws -> DailyResponse {
        let output = try await run(["ccusage", "daily", "--json", "--offline"])
        return try JSONDecoder().decode(DailyResponse.self, from: output)
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }

    private func run(_ arguments: [String]) async throws -> Data {
        let npx = npxPath
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: npx)
                process.arguments = arguments

                var env = ProcessInfo.processInfo.environment
                let homeDir = env["HOME"] ?? NSHomeDirectory()
                let existingPath = env["PATH"] ?? ""
                let paths = [
                    "/opt/homebrew/bin",
                    "/usr/local/bin",
                    "/usr/bin",
                    "/bin",
                    "\(homeDir)/.nvm/versions/node/*/bin",
                    existingPath
                ]
                env["PATH"] = paths.joined(separator: ":")
                env["NO_COLOR"] = "1"
                process.environment = env

                let pipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = pipe
                process.standardError = errorPipe

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: CCUsageError.commandFailed(error.localizedDescription))
                    return
                }

                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()

                guard process.terminationStatus == 0 else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: CCUsageError.commandFailed(errorMessage))
                    return
                }

                guard !data.isEmpty else {
                    continuation.resume(throwing: CCUsageError.emptyResponse)
                    return
                }

                continuation.resume(returning: data)
            }
        }
    }
}

enum CCUsageError: LocalizedError {
    case commandFailed(String)
    case emptyResponse
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let msg): return "ccusage failed: \(msg)"
        case .emptyResponse: return "No data returned from ccusage"
        case .parseError(let msg): return "Parse error: \(msg)"
        }
    }
}
