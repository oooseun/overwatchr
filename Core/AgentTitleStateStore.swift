import Foundation

public struct AgentTitleStateEntry: Codable, Equatable, Sendable {
    public let terminalID: String?
    public let tty: String?
    public let tool: String?
    public let sessionID: String?
    public let topic: String?
    public let cwd: String?
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case terminalID = "terminal_id"
        case tty
        case tool
        case sessionID = "session_id"
        case topic
        case cwd
        case updatedAt = "updated_at"
    }
}

public struct AgentTitleStateStore: Sendable {
    public static let defaultFileURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".cache/agent-title/sessions.jsonl")
    public static let environmentOverrideKey = "AGENT_TITLE_STATE_FILE"

    public let fileURL: URL

    public init(
        fileURL: URL? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        if let fileURL {
            self.fileURL = fileURL
        } else if let override = environment[AgentTitleStateStore.environmentOverrideKey], !override.isEmpty {
            self.fileURL = URL(fileURLWithPath: override)
        } else {
            self.fileURL = AgentTitleStateStore.defaultFileURL
        }
    }

    public func latest(sessionID: String) throws -> AgentTitleStateEntry? {
        try latest { $0.sessionID == sessionID }
    }

    public func latest(tty: String) throws -> AgentTitleStateEntry? {
        try latest { $0.tty == tty }
    }

    public func latest(terminalID: String) throws -> AgentTitleStateEntry? {
        try latest { $0.terminalID == terminalID }
    }

    private func latest(matching predicate: (AgentTitleStateEntry) -> Bool) throws -> AgentTitleStateEntry? {
        try loadAll()
            .filter(predicate)
            .max { lhs, rhs in
                (lhs.updatedAt ?? "") < (rhs.updatedAt ?? "")
            }
    }

    private func loadAll() throws -> [AgentTitleStateEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        guard let string = String(data: data, encoding: .utf8) else {
            return []
        }

        let decoder = JSONDecoder()
        return string
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> AgentTitleStateEntry? in
                guard let lineData = String(line).data(using: .utf8) else {
                    return nil
                }
                return try? decoder.decode(AgentTitleStateEntry.self, from: lineData)
            }
    }
}
