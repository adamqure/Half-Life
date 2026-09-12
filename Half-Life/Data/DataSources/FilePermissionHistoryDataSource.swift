//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FilePermissionHistoryDataSource
//

import Foundation
import OSLog

/// The permission history, in a small JSON file on the device.
///
/// The file is written atomically with `NSFileProtectionComplete` (constitution Article V.4), and never syncs. With
/// no file, nothing has been asked. See the Onboarding article.
struct FilePermissionHistoryDataSource: PermissionHistoryDataSource {
    /// What the file holds.
    private struct History: Codable {
        var hasRequestedBiometrics: Bool
    }

    private static let logger = Logger(for: FilePermissionHistoryDataSource.self)

    /// `PermissionHistory.json` in the app's Application Support directory.
    static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(path: "PermissionHistory.json")
    }

    /// The file the history is kept in.
    let fileURL: URL
    /// Writes data to a file with the given options.
    let write: @Sendable (Data, URL, Data.WritingOptions) throws -> Void

    /// Creates a history kept in `fileURL`.
    ///
    /// - Parameters:
    ///   - fileURL: The file the history is kept in. Defaults to ``defaultFileURL``.
    ///   - write: Writes the file. Defaults to `Data`'s own write. Tests check the options through it, because the
    ///     simulator doesn't report a file's protection class.
    init(
        fileURL: URL = Self.defaultFileURL,
        write: @escaping @Sendable (Data, URL, Data.WritingOptions) throws -> Void = {
            try $0.write(to: $1, options: $2)
        }
    ) {
        self.fileURL = fileURL
        self.write = write
    }

    /// Returns whether Half-Life has asked to use biometrics. With no file, it hasn't.
    ///
    /// - Throws: An error if the file exists but couldn't be read. It's logged with its domain and code only.
    func hasRequestedBiometrics() async throws -> Bool {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return false }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(History.self, from: data).hasRequestedBiometrics
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't read the permission history: \(domain, privacy: .public) \(code, privacy: .public)")
            throw error
        }
    }

    /// Records that Half-Life has asked to use biometrics, creating the file's directory if needed.
    ///
    /// - Throws: An error if the file couldn't be written. It's logged with its domain and code only.
    func recordBiometricsRequested() async throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(History(hasRequestedBiometrics: true))
            try write(data, fileURL, [.atomic, .completeFileProtection])
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't write the permission history: \(domain, privacy: .public) \(code, privacy: .public)")
            throw error
        }
    }
}
