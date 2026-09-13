//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FileSleepToleranceDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the tolerance file, on a temporary directory (TOLFILE-1 to TOLFILE-4 in the Insights article).
@Suite(.timeLimit(.minutes(1)))
struct FileSleepToleranceDataSourceTests {

    static let tolerance = SleepTolerance(milligrams: 55, nightsUnder: 17, nightsOver: 9)

    /// A file in a new temporary directory that doesn't exist yet.
    static func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "SleepTolerance.json")
    }

    static func write(_ json: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(json.utf8).write(to: url)
    }

    // MARK: - TOLFILE-1: with no file, there's no tolerance

    @Test func withNoFileThereIsNoTolerance() async throws {
        #expect(try await FileSleepToleranceDataSource(fileURL: Self.temporaryFile()).storedTolerance() == nil)
    }

    // MARK: - TOLFILE-2: a stored tolerance, or none, reads back from any instance, and a store signals

    @Test func aStoredToleranceReadsBackInANewInstance() async throws {
        let url = Self.temporaryFile()

        try await FileSleepToleranceDataSource(fileURL: url).store(Self.tolerance)

        #expect(try await FileSleepToleranceDataSource(fileURL: url).storedTolerance() == Self.tolerance)
    }

    @Test func storingNoneReplacesAStoredTolerance() async throws {
        let url = Self.temporaryFile()
        let source = FileSleepToleranceDataSource(fileURL: url)

        try await source.store(Self.tolerance)
        try await source.store(nil)

        #expect(try await FileSleepToleranceDataSource(fileURL: url).storedTolerance() == nil)
    }

    @Test func aStoreSignalsEverySubscriber() async throws {
        let source = FileSleepToleranceDataSource(fileURL: Self.temporaryFile())
        var first = await source.changes().makeAsyncIterator()
        var second = await source.changes().makeAsyncIterator()

        try await source.store(Self.tolerance)

        #expect(await first.next() != nil)
        #expect(await second.next() != nil)
    }

    // MARK: - TOLFILE-3: complete protection, never in an iCloud backup, in Application Support

    @Test func theFileIsWrittenWithCompleteProtectionAndLeftOutOfBackups() async throws {
        let url = Self.temporaryFile()

        try await FileSleepToleranceDataSource(fileURL: url).store(Self.tolerance)

        #expect(FileSleepToleranceDataSource.writingOptions.contains(.completeFileProtection))
        #expect(FileSleepToleranceDataSource.writingOptions.contains(.atomic))
        #expect(try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true)
        // The simulator doesn't report a file's protection class, so this part only checks on a device.
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
        if let protection = attributes[.protectionKey] as? FileProtectionType {
            #expect(protection == .complete)
        }
    }

    @Test func theDefaultFileIsInApplicationSupport() throws {
        let url = try FileSleepToleranceDataSource.defaultFileURL()

        #expect(url.lastPathComponent == "SleepTolerance.json")
        #expect(url.deletingLastPathComponent().lastPathComponent == "Application Support")
    }

    // MARK: - TOLFILE-4: a damaged file, or a tolerance outside 20 to 80 mg, throws

    @Test func aDamagedFileThrows() async throws {
        let url = Self.temporaryFile()
        try Self.write("not a tolerance", to: url)

        await #expect(throws: (any Error).self) {
            try await FileSleepToleranceDataSource(fileURL: url).storedTolerance()
        }
    }

    @Test(arguments: [15.0, 95])
    func aToleranceOutside20To80MgThrows(milligrams: Double) async throws {
        let url = Self.temporaryFile()
        try Self.write(#"{"version":1,"milligrams":\#(milligrams),"nightsUnder":5,"nightsOver":5}"#, to: url)

        await #expect(throws: DecodingError.self) {
            try await FileSleepToleranceDataSource(fileURL: url).storedTolerance()
        }
    }
}
