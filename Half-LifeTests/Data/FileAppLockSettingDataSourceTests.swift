//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FileAppLockSettingDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the file that remembers whether the app lock is on (LOCKSRC-1 in the App Lock article), on a temporary
/// directory.
struct FileAppLockSettingDataSourceTests {

    /// A file in a new temporary directory that doesn't exist yet.
    static func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "AppLock.json")
    }

    @Test func withNoFileTheLockIsOff() async throws {
        let source = FileAppLockSettingDataSource(fileURL: Self.temporaryFile())

        #expect(try await source.isEnabled() == false)
    }

    @Test func theSettingPersistsAcrossInstances() async throws {
        let file = Self.temporaryFile()

        try await FileAppLockSettingDataSource(fileURL: file).setEnabled(true)
        #expect(try await FileAppLockSettingDataSource(fileURL: file).isEnabled())

        try await FileAppLockSettingDataSource(fileURL: file).setEnabled(false)
        #expect(try await FileAppLockSettingDataSource(fileURL: file).isEnabled() == false)
    }

    /// The simulator doesn't report a file's protection class, so this checks the options the file is written with.
    @Test func theFileIsWrittenAtomicallyWithCompleteProtection() async throws {
        let options = Recorded<[Data.WritingOptions]>([])
        let source = FileAppLockSettingDataSource(fileURL: Self.temporaryFile()) { data, url, writingOptions in
            options.update { $0.append(writingOptions) }
            try data.write(to: url, options: writingOptions)
        }

        try await source.setEnabled(true)

        #expect(options.value == [[.atomic, .completeFileProtection]])
        #expect(try await source.isEnabled())
    }

    @Test func anUnreadableFileThrows() async throws {
        let file = Self.temporaryFile()
        try FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: file)

        await #expect(throws: (any Error).self) {
            try await FileAppLockSettingDataSource(fileURL: file).isEnabled()
        }
    }

    @Test func aFailedWriteThrows() async throws {
        // A file where the directory should be makes the directory impossible to create.
        let blocker = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data().write(to: blocker)
        let file = blocker.appending(path: "AppLock.json")

        await #expect(throws: (any Error).self) {
            try await FileAppLockSettingDataSource(fileURL: file).setEnabled(true)
        }
    }

    @Test func theDefaultFileIsInApplicationSupport() {
        #expect(
            FileAppLockSettingDataSource().fileURL == URL.applicationSupportDirectory.appending(path: "AppLock.json"))
    }
}
