//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FileProfileDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the profile file, on a temporary directory (PROFFILE-1 to PROFFILE-4, BEDSRC-1, and HALF-1).
@Suite(.timeLimit(.minutes(1)))
struct FileProfileDataSourceTests {

    /// A file in a new temporary directory that doesn't exist yet.
    static func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "Profile.json")
    }

    static func everyField() throws -> UserProfile {
        UserProfile(
            name: "Alex", birthYear: 1990,
            halfLifeFactors: [.pregnant(.second), .estrogen, .smokes, .cirrhosis, .fluvoxamine],
            bedtime: try #require(Bedtime(hour: 23, minute: 45)),
            halfLife: try #require(CaffeineHalfLife(seconds: 37_620)), hasCompletedOnboarding: true)
    }

    // MARK: - PROFFILE-2, BEDSRC-1, HALF-1: with no file, the defaults

    @Test func withNoFileThereIsNoProfileAndTheStandardValues() async throws {
        let source = FileProfileDataSource(fileURL: Self.temporaryFile())

        #expect(try await source.storedProfile() == nil)
        #expect(try await source.bedtime() == .standard)
        #expect(try await source.halfLife() == .standard)
    }

    // MARK: - PROFFILE-4: a stored profile reads back, from any instance

    @Test func aStoredProfileReadsBackInANewInstance() async throws {
        let url = Self.temporaryFile()
        let profile = try Self.everyField()

        try await FileProfileDataSource(fileURL: url).store(profile)
        let reopened = FileProfileDataSource(fileURL: url)

        #expect(try await reopened.storedProfile() == profile)
        #expect(try await reopened.bedtime() == profile.bedtime)
        #expect(try await reopened.halfLife() == profile.halfLife)
    }

    @Test(arguments: Trimester.allCases)
    func everyTrimesterReadsBack(_ trimester: Trimester) async throws {
        let source = FileProfileDataSource(fileURL: Self.temporaryFile())
        let profile = UserProfile(halfLifeFactors: [.pregnant(trimester)])

        try await source.store(profile)

        #expect(try await source.storedProfile() == profile)
    }

    @Test func aProfileWithNothingGivenReadsBack() async throws {
        let source = FileProfileDataSource(fileURL: Self.temporaryFile())

        try await source.store(UserProfile())

        #expect(try await source.storedProfile() == UserProfile())
    }

    // MARK: - PROFFILE-1: complete file protection

    @Test func theFileIsWrittenWithCompleteProtection() async throws {
        let url = Self.temporaryFile()

        try await FileProfileDataSource(fileURL: url).store(UserProfile(name: "Alex"))

        #expect(FileProfileDataSource.writingOptions.contains(.completeFileProtection))
        #expect(FileProfileDataSource.writingOptions.contains(.atomic))
        // The simulator doesn't report a file's protection class, so this part only checks on a device.
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
        if let protection = attributes[.protectionKey] as? FileProtectionType {
            #expect(protection == .complete)
        }
    }

    // MARK: - PROFFILE-3: a signal after each successful store, and none after a failed one

    @Test func storingSignalsEverySubscriber() async throws {
        let source = FileProfileDataSource(fileURL: Self.temporaryFile())
        var first = await source.changes().makeAsyncIterator()
        var second = await source.changes().makeAsyncIterator()

        try await source.store(UserProfile(name: "Alex"))

        #expect(await first.next() != nil)
        #expect(await second.next() != nil)
    }

    @Test func aFailedStoreThrowsAndSignalsNothing() async throws {
        // A regular file where the directory should be makes the write fail.
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data().write(to: directory)
        let source = FileProfileDataSource(fileURL: directory.appending(path: "Profile.json"))
        let signals = await source.changes()
        let received = Task {
            var count = 0
            for await _ in signals {
                count += 1
            }
            return count
        }

        await #expect(throws: (any Error).self) {
            try await source.store(UserProfile(name: "Alex"))
        }
        try await Task.sleep(for: .milliseconds(200))
        received.cancel()

        #expect(await received.value == 0)
    }

    // MARK: - A damaged file throws rather than reading as nothing

    @Test func aDamagedFileThrows() async throws {
        let url = Self.temporaryFile()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not a profile".utf8).write(to: url)
        let source = FileProfileDataSource(fileURL: url)

        await #expect(throws: (any Error).self) {
            try await source.storedProfile()
        }
        await #expect(throws: (any Error).self) {
            try await source.bedtime()
        }
    }

    // MARK: - Its default location

    @Test func itsDefaultFileIsInApplicationSupport() throws {
        let url = try FileProfileDataSource.defaultFileURL()

        #expect(url.lastPathComponent == "Profile.json")
        #expect(url.deletingLastPathComponent().lastPathComponent == "Application Support")
    }
}
