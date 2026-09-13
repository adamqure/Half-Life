//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FileAppLockSettingDataSource
//

import Foundation
import OSLog

/// Whether the app lock is on, in a small JSON file on the device.
///
/// The file is written atomically with `NSFileProtectionComplete` (constitution Article V.4), and never syncs, so the
/// lock is set per device. With no file, the lock is off. See the App Lock article.
struct FileAppLockSettingDataSource: AppLockSettingDataSource {
    /// What the file holds.
    private struct Setting: Codable {
        var isEnabled: Bool
    }

    private static let logger = Logger(for: FileAppLockSettingDataSource.self)

    /// `AppLock.json` in the app's Application Support directory.
    static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(path: "AppLock.json")
    }

    /// The file the setting is kept in.
    let fileURL: URL
    /// Writes data to a file with the given options.
    let write: @Sendable (Data, URL, Data.WritingOptions) throws -> Void

    /// Creates a setting kept in `fileURL`.
    ///
    /// - Parameters:
    ///   - fileURL: The file the setting is kept in. Defaults to ``defaultFileURL``.
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

    /// Returns whether the lock is on. With no file, it's off.
    ///
    /// - Throws: An error if the file exists but couldn't be read. It's logged with its domain and code only.
    func isEnabled() async throws -> Bool {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return false }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(Setting.self, from: data).isEnabled
        } catch {
            Self.logError("read the app lock setting", error)
            throw error
        }
    }

    /// Stores whether the lock is on, creating the file's directory if needed.
    ///
    /// - Parameter isEnabled: Whether the lock is on.
    /// - Throws: An error if the file couldn't be written. It's logged with its domain and code only.
    func setEnabled(_ isEnabled: Bool) async throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Setting(isEnabled: isEnabled))
            try write(data, fileURL, [.atomic, .completeFileProtection])
        } catch {
            Self.logError("write the app lock setting", error)
            throw error
        }
    }

    /// Logs a failure with the error's domain and code only (constitution Article XI.6.4).
    private static func logError(_ what: String, _ error: any Error) {
        let domain = (error as NSError).domain
        let code = (error as NSError).code
        logger.error("Couldn't \(what, privacy: .public): \(domain, privacy: .public) \(code, privacy: .public)")
    }
}
