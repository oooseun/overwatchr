import Foundation
import XCTest
@testable import OverwatchrCore

final class AgentTitleStateStoreTests: XCTestCase {
    func testFindsLatestEntryBySessionID() throws {
        let fileURL = try makeStateFile(contents: """
        {"session_id":"target","topic":"old topic","tty":"/dev/ttys001","updated_at":"2026-05-26T01:00:00Z"}
        {"session_id":"other","topic":"other topic","tty":"/dev/ttys002","updated_at":"2026-05-26T02:00:00Z"}
        {"session_id":"target","topic":"right tab","tty":"/dev/ttys012","updated_at":"2026-05-26T03:00:00Z"}
        """)
        let store = AgentTitleStateStore(fileURL: fileURL)

        XCTAssertEqual(try store.latest(sessionID: "target")?.topic, "right tab")
        XCTAssertEqual(try store.latest(sessionID: "target")?.tty, "/dev/ttys012")
    }

    func testFindsLatestEntryByTTY() throws {
        let fileURL = try makeStateFile(contents: """
        {"session_id":"one","topic":"first","tty":"/dev/ttys012","updated_at":"2026-05-26T01:00:00Z"}
        {"session_id":"two","topic":"second","tty":"/dev/ttys012","terminal_id":"abc","updated_at":"2026-05-26T02:00:00Z"}
        """)
        let store = AgentTitleStateStore(fileURL: fileURL)

        XCTAssertEqual(try store.latest(tty: "/dev/ttys012")?.sessionID, "two")
        XCTAssertEqual(try store.latest(tty: "/dev/ttys012")?.terminalID, "abc")
    }

    func testSkipsMalformedLines() throws {
        let fileURL = try makeStateFile(contents: """
        not-json
        {"session_id":"target","topic":"usable","updated_at":"2026-05-26T02:00:00Z"}
        """)
        let store = AgentTitleStateStore(fileURL: fileURL)

        XCTAssertEqual(try store.latest(sessionID: "target")?.topic, "usable")
    }

    func testMissingFileReturnsNil() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("sessions.jsonl")
        let store = AgentTitleStateStore(fileURL: fileURL)

        XCTAssertNil(try store.latest(sessionID: "target"))
        XCTAssertNil(try store.latest(tty: "/dev/ttys012"))
        XCTAssertNil(try store.latest(terminalID: "abc"))
    }

    private func makeStateFile(contents: String) throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent("sessions.jsonl")
        try contents.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
