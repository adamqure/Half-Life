//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FileHalfLifeEstimateDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the estimate file, on a temporary directory (ESTFILE-1 to ESTFILE-4 in the Half-Life Estimator article).
@Suite(.timeLimit(.minutes(1)))
struct FileHalfLifeEstimateDataSourceTests {

    /// A file in a new temporary directory that doesn't exist yet.
    static func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "HalfLifeEstimate.json")
    }

    static func estimate() throws -> HalfLifeEstimate {
        HalfLifeEstimate(
            halfLife: try #require(CaffeineHalfLife(seconds: 25_123.5)),
            lowerBound: try #require(CaffeineHalfLife(seconds: 18_000.25)),
            upperBound: try #require(CaffeineHalfLife(seconds: 36_000.75)), prior: .standard, nightsUsed: 23,
            calculatedAt: Date(timeIntervalSinceReferenceDate: 802_137_600.125))
    }

    // MARK: - ESTFILE-1: with no file, there's no estimate

    @Test func withNoFileThereIsNoEstimate() async throws {
        #expect(try await FileHalfLifeEstimateDataSource(fileURL: Self.temporaryFile()).storedEstimate() == nil)
    }

    // MARK: - ESTFILE-2: a stored estimate reads back exactly, from any instance

    @Test func aStoredEstimateReadsBackInANewInstance() async throws {
        let url = Self.temporaryFile()

        try await FileHalfLifeEstimateDataSource(fileURL: url).store(try Self.estimate())

        #expect(try await FileHalfLifeEstimateDataSource(fileURL: url).storedEstimate() == (try Self.estimate()))
    }

    @Test func aStoreSignalsEverySubscriber() async throws {
        let source = FileHalfLifeEstimateDataSource(fileURL: Self.temporaryFile())
        var changes = await source.changes().makeAsyncIterator()

        try await source.store(try Self.estimate())

        #expect(await changes.next() != nil)
    }

    // MARK: - ESTFILE-3: complete protection, and never in an iCloud backup

    @Test func theFileIsWrittenWithCompleteProtectionAndLeftOutOfBackups() async throws {
        let url = Self.temporaryFile()

        try await FileHalfLifeEstimateDataSource(fileURL: url).store(try Self.estimate())

        #expect(FileHalfLifeEstimateDataSource.writingOptions.contains(.completeFileProtection))
        #expect(FileHalfLifeEstimateDataSource.writingOptions.contains(.atomic))
        #expect(try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true)
        // The simulator doesn't report a file's protection class, so this part only checks on a device.
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
        if let protection = attributes[.protectionKey] as? FileProtectionType {
            #expect(protection == .complete)
        }
    }

    @Test func theDefaultFileIsInApplicationSupport() throws {
        let url = try FileHalfLifeEstimateDataSource.defaultFileURL()

        #expect(url.lastPathComponent == "HalfLifeEstimate.json")
        #expect(url.deletingLastPathComponent().lastPathComponent == "Application Support")
    }

    // MARK: - ESTFILE-4: a damaged file throws

    @Test func aDamagedFileThrows() async throws {
        let url = Self.temporaryFile()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not an estimate".utf8).write(to: url)

        await #expect(throws: (any Error).self) {
            try await FileHalfLifeEstimateDataSource(fileURL: url).storedEstimate()
        }
    }

    @Test func aFileWithAnInvalidHalfLifeThrows() async throws {
        let url = Self.temporaryFile()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let json = """
            {"version":1,"halfLifeSeconds":0,"lowerBoundSeconds":1,"upperBoundSeconds":2,"priorSeconds":3,\
            "nightsUsed":0,"calculatedAt":0}
            """
        try Data(json.utf8).write(to: url)

        await #expect(throws: DecodingError.self) {
            try await FileHalfLifeEstimateDataSource(fileURL: url).storedEstimate()
        }
    }
}
