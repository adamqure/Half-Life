//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FileDemoHealthDataFlagDataSource
//

import Foundation
import OSLog

/// Stores the demo Health data switch in one small JSON file, on the device only.
///
/// The switch isn't the user's data, so it isn't synced. It's off until the user turns it on. UserDefaults was ruled
/// out because it's a required-reason API, and the app has no privacy manifest yet (see the Onboarding article). The
/// Apple Health Card article lists its requirements, DEMOFLAG-1 to DEMOFLAG-3.
actor FileDemoHealthDataFlagDataSource: DemoHealthDataFlagDataSource {
    private static let logger = Logger(for: FileDemoHealthDataFlagDataSource.self)

    /// The file the switch is stored in.
    nonisolated let fileURL: URL
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    /// Creates a data source over `fileURL`. Nothing is read or written until it's asked.
    ///
    /// - Parameter fileURL: The file to store the switch in. Its directory is created on the first store.
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// The app's switch file: `DemoHealthData.json` in Application Support.
    ///
    /// - Throws: The file manager's error if Application Support can't be located.
    static func defaultFileURL() throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appending(path: "DemoHealthData.json")
    }

    /// Returns whether the switch is on, or `false` if there's no file yet.
    ///
    /// - Throws: The file system's error if the file couldn't be read, or a decoding error if it's damaged. Either is
    ///   logged with its domain and code only.
    func usesDemoData() throws -> Bool {
        do {
            return try storedValue() ?? false
        } catch {
            let error = error as NSError
            Self.logger.error(
                """
                Couldn't read the demo Health data switch: \
                \(error.domain, privacy: .public) \(error.code, privacy: .public)
                """
            )
            throw error
        }
    }

    /// Stores whether the switch is on, then signals every subscriber. Storing the value already stored does nothing.
    ///
    /// A damaged file is replaced.
    ///
    /// - Parameter isOn: Whether the switch is on.
    /// - Throws: The encoder's or the file system's error, logged with its domain and code only. Nothing is signalled.
    func setUsesDemoData(_ isOn: Bool) throws {
        guard (try? storedValue() ?? false) != isOn else { return }
        do {
            let data = try JSONEncoder().encode(StoredSwitch(usesDemoData: isOn))
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            let error = error as NSError
            Self.logger.error(
                """
                Couldn't store the demo Health data switch: \
                \(error.domain, privacy: .public) \(error.code, privacy: .public)
                """
            )
            throw error
        }
        for continuation in continuations.values {
            continuation.yield()
        }
    }

    /// Returns a stream that yields once after each change to the switch, until the subscriber stops listening.
    func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        let id = UUID()
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeContinuation(id) }
        }
        return stream
    }

    /// The stored value, or `nil` if there's no file yet.
    private func storedValue() throws -> Bool? {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return nil }
        return try JSONDecoder().decode(StoredSwitch.self, from: Data(contentsOf: fileURL)).usesDemoData
    }

    private func removeContinuation(_ id: UUID) {
        continuations[id] = nil
    }
}

/// The switch as it's written to the file. A version field leaves room to change the format later.
private struct StoredSwitch: Codable {
    var version = 1
    var usesDemoData: Bool
}
