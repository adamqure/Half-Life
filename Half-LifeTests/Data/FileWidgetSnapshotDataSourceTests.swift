//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FileWidgetSnapshotDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the widget snapshot file, on a temporary directory (WSDS-1 to WSDS-4 in the Widgets article).
@Suite(.timeLimit(.minutes(1)))
struct FileWidgetSnapshotDataSourceTests {

    /// A file in a new temporary directory that doesn't exist yet.
    static func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "WidgetSnapshot.json")
    }

    static let sampleLatestDrinkAt = Date(timeIntervalSinceReferenceDate: 799_990_000.5)

    static func snapshot(latestDrinkAt: Date? = sampleLatestDrinkAt) throws -> WidgetSnapshot {
        let start = Date(timeIntervalSinceReferenceDate: 800_001_000.25)
        return WidgetSnapshot(
            forecast: [
                CaffeineLevel(date: start, milligrams: 84.123_456), CaffeineLevel(date: start + 300, milligrams: 80.5),
            ],
            bedtime: try #require(Bedtime(hour: 23, minute: 15)),
            favourites: [
                FavouriteDrink(type: .flatWhite, quantity: 2), FavouriteDrink(type: .energyDrink, quantity: 1),
            ],
            latestDrinkAt: latestDrinkAt, isOnboardingComplete: true,
            writtenAt: Date(timeIntervalSinceReferenceDate: 800_001_130.75))
    }

    // MARK: - WSDS-1: a stored snapshot reads back equal, from any instance

    @Test func aStoredSnapshotReadsBackEqualInANewInstance() async throws {
        let url = Self.temporaryFile()

        try await FileWidgetSnapshotDataSource(fileURL: url).store(try Self.snapshot())

        #expect(try await FileWidgetSnapshotDataSource(fileURL: url).storedSnapshot() == (try Self.snapshot()))
    }

    @Test func aSnapshotWithNoLatestDrinkReadsBackEqual() async throws {
        let url = Self.temporaryFile()
        let snapshot = try Self.snapshot(latestDrinkAt: nil)

        try await FileWidgetSnapshotDataSource(fileURL: url).store(snapshot)

        #expect(try await FileWidgetSnapshotDataSource(fileURL: url).storedSnapshot() == snapshot)
    }

    @Test func aNewSnapshotReplacesTheOldOne() async throws {
        let source = FileWidgetSnapshotDataSource(fileURL: Self.temporaryFile())
        try await source.store(try Self.snapshot())

        try await source.store(try Self.snapshot(latestDrinkAt: nil))

        #expect(try await source.storedSnapshot() == (try Self.snapshot(latestDrinkAt: nil)))
    }

    // MARK: - WSDS-2: protected until the first unlock, and never in an iCloud backup

    @Test func theFileIsProtectedUntilTheFirstUnlockAndLeftOutOfBackups() async throws {
        let url = Self.temporaryFile()

        try await FileWidgetSnapshotDataSource(fileURL: url).store(try Self.snapshot())

        #expect(
            FileWidgetSnapshotDataSource.writingOptions.contains(.completeFileProtectionUntilFirstUserAuthentication))
        #expect(FileWidgetSnapshotDataSource.writingOptions.contains(.atomic))
        #expect(try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true)
    }

    // MARK: - WSDS-3: with no file there's no snapshot, and a damaged file throws

    @Test func withNoFileThereIsNoSnapshot() async throws {
        #expect(try await FileWidgetSnapshotDataSource(fileURL: Self.temporaryFile()).storedSnapshot() == nil)
    }

    @Test func aDamagedFileThrows() async throws {
        let url = Self.temporaryFile()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not a snapshot".utf8).write(to: url)

        await #expect(throws: (any Error).self) {
            try await FileWidgetSnapshotDataSource(fileURL: url).storedSnapshot()
        }
    }

    // MARK: - WSDS-4: the app's file is in the App Group container, which the widget extension shares

    @Test func theAppsFileIsInTheAppGroupContainer() throws {
        let container = try #require(
            FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: FileWidgetSnapshotDataSource.appGroupIdentifier))

        #expect(FileWidgetSnapshotDataSource.appGroupFileURL() == container.appending(path: "WidgetSnapshot.json"))
        #expect(FileWidgetSnapshotDataSource.appGroupIdentifier == "group.com.quillanq.Half-Life")
    }
}
