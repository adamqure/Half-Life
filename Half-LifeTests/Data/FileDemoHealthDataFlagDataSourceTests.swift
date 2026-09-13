//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FileDemoHealthDataFlagDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the file that stores the demo Health data switch against DEMOFLAG-1 to DEMOFLAG-3 in the Apple Health Card
/// article. Each test uses its own temporary file.
struct FileDemoHealthDataFlagDataSourceTests {

    static func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "DemoHealthData.json")
    }

    /// Counts the signals `changes` delivers while `work` runs. Signals are buffered, so after a short wait every
    /// signal the work sent has been counted, and cancelling ends the count.
    static func signalCount(
        _ changes: AsyncStream<Void>, during work: () async throws -> Void
    ) async throws -> Int {
        let counter = Task {
            var count = 0
            for await _ in changes {
                count += 1
            }
            return count
        }
        try await work()
        try await Task.sleep(for: .milliseconds(200))
        counter.cancel()
        return await counter.value
    }

    // MARK: - DEMOFLAG-1: the switch is off until a value is stored

    @Test func theSwitchIsOffUntilAValueIsStored() async throws {
        let source = FileDemoHealthDataFlagDataSource(fileURL: Self.temporaryFileURL())

        #expect(try await source.usesDemoData() == false)
    }

    // MARK: - DEMOFLAG-2: a stored value reads back, including from a new instance

    @Test func aStoredValueReadsBackFromANewInstance() async throws {
        let fileURL = Self.temporaryFileURL()
        let source = FileDemoHealthDataFlagDataSource(fileURL: fileURL)

        try await source.setUsesDemoData(true)
        let afterTurningOn = try await FileDemoHealthDataFlagDataSource(fileURL: fileURL).usesDemoData()
        try await source.setUsesDemoData(false)
        let afterTurningOff = try await source.usesDemoData()

        #expect(afterTurningOn)
        #expect(!afterTurningOff)
    }

    @Test func aDamagedFileThrows() async throws {
        let fileURL = Self.temporaryFileURL()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not a switch".utf8).write(to: fileURL)
        let source = FileDemoHealthDataFlagDataSource(fileURL: fileURL)

        await #expect(throws: (any Error).self) {
            try await source.usesDemoData()
        }
    }

    @Test func theAppsFileIsInApplicationSupport() throws {
        let fileURL = try FileDemoHealthDataFlagDataSource.defaultFileURL()

        #expect(fileURL.lastPathComponent == "DemoHealthData.json")
        #expect(fileURL.deletingLastPathComponent().lastPathComponent == "Application Support")
    }

    // MARK: - DEMOFLAG-3: storing a new value signals, and storing the same value doesn't

    @Test func storingANewValueSignalsAndStoringTheSameValueDoesNot() async throws {
        let source = FileDemoHealthDataFlagDataSource(fileURL: Self.temporaryFileURL())
        let changes = await source.changes()

        let count = try await Self.signalCount(changes) {
            try await source.setUsesDemoData(true)
            try await source.setUsesDemoData(true)
            try await source.setUsesDemoData(false)
        }

        #expect(count == 2)
    }
}
