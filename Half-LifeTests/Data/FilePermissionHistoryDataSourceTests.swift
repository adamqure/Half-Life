//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FilePermissionHistoryDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the file that remembers whether Face ID has been requested, on a temporary directory.
struct FilePermissionHistoryDataSourceTests {

    /// A file in a new temporary directory that doesn't exist yet.
    static func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "PermissionHistory.json")
    }

    @Test func withNoFileNothingHasBeenRequested() async throws {
        let source = FilePermissionHistoryDataSource(fileURL: Self.temporaryFile())

        #expect(try await source.hasRequestedBiometrics() == false)
    }

    @Test func aRecordedRequestPersistsAcrossInstances() async throws {
        let file = Self.temporaryFile()

        try await FilePermissionHistoryDataSource(fileURL: file).recordBiometricsRequested()

        #expect(try await FilePermissionHistoryDataSource(fileURL: file).hasRequestedBiometrics())
    }

    /// The simulator doesn't report a file's protection class, so this checks the options the file is written with.
    @Test func theFileIsWrittenAtomicallyWithCompleteProtection() async throws {
        let options = Recorded<[Data.WritingOptions]>([])
        let source = FilePermissionHistoryDataSource(fileURL: Self.temporaryFile()) { data, url, writingOptions in
            options.update { $0.append(writingOptions) }
            try data.write(to: url, options: writingOptions)
        }

        try await source.recordBiometricsRequested()

        #expect(options.value == [[.atomic, .completeFileProtection]])
        #expect(try await source.hasRequestedBiometrics())
    }

    @Test func anUnreadableFileThrows() async throws {
        let file = Self.temporaryFile()
        try FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: file)

        await #expect(throws: (any Error).self) {
            try await FilePermissionHistoryDataSource(fileURL: file).hasRequestedBiometrics()
        }
    }

    @Test func aFailedWriteThrows() async throws {
        // A file where the directory should be makes the directory impossible to create.
        let blocker = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data().write(to: blocker)
        let file = blocker.appending(path: "PermissionHistory.json")

        await #expect(throws: (any Error).self) {
            try await FilePermissionHistoryDataSource(fileURL: file).recordBiometricsRequested()
        }
    }

    @Test func theDefaultFileIsInApplicationSupport() {
        #expect(
            FilePermissionHistoryDataSource().fileURL
                == URL.applicationSupportDirectory.appending(path: "PermissionHistory.json"))
    }
}
