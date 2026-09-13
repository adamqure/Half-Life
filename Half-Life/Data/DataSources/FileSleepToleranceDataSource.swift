//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FileSleepToleranceDataSource
//

import Foundation
import OSLog

/// Stores the user's caffeine tolerance in one JSON file, on the device only.
///
/// The tolerance is derived from sleep, so it's protected with `NSFileProtectionComplete`, left out of iCloud backups,
/// and never synced (constitution Articles V.3.4 and V.4), and nothing in it is logged. It's the tolerance data source
/// for ``SleepToleranceRepository``, and ``PersonalSleepThresholdDataSource`` reads the same instance for the decay
/// model, so a store signals the cutoff. The Insights article lists its requirements, TOLFILE-1 to TOLFILE-4.
actor FileSleepToleranceDataSource: SleepToleranceDataSource {
    private static let logger = Logger(for: FileSleepToleranceDataSource.self)

    /// How the file is written: atomically, and with `NSFileProtectionComplete`, so it can't be read while the device
    /// is locked (constitution Article V.4, TOLFILE-3).
    static let writingOptions: Data.WritingOptions = [.atomic, .completeFileProtection]

    /// The file the tolerance is stored in.
    nonisolated let fileURL: URL
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    /// Creates a data source over `fileURL`. Nothing is read or written until it's asked.
    ///
    /// - Parameter fileURL: The file to store the tolerance in. Its directory is created on the first store.
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// The app's tolerance file: `SleepTolerance.json` in Application Support.
    ///
    /// - Throws: The file manager's error if Application Support can't be located.
    static func defaultFileURL() throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appending(path: "SleepTolerance.json")
    }

    /// Returns the stored tolerance, or `nil` if there's no file yet, or it stores none.
    ///
    /// - Throws: The file system's error if the file couldn't be read, or a decoding error if it's damaged or its
    ///   tolerance is outside 20 to 80 mg. Either is logged with its domain and code only.
    func storedTolerance() throws -> SleepTolerance? {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(StoredTolerance.self, from: data).tolerance()
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the tolerance: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            throw error
        }
    }

    /// Stores `tolerance`, or none, in place of the file's contents, leaves the file out of iCloud backups, then
    /// signals every subscriber.
    ///
    /// - Parameter tolerance: The tolerance to store, or `nil` for none.
    /// - Throws: The encoder's or the file system's error, logged with its domain and code only. Nothing is signalled.
    func store(_ tolerance: SleepTolerance?) throws {
        do {
            let data = try JSONEncoder().encode(StoredTolerance(tolerance))
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fileURL, options: Self.writingOptions)
            // An atomic write replaces the file, so the new file is left out of backups each time.
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var url = fileURL
            try url.setResourceValues(values)
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't store the tolerance: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            throw error
        }
        for continuation in continuations.values {
            continuation.yield()
        }
    }

    /// Returns a stream that yields once after each successful store, until the subscriber stops listening.
    func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        let id = UUID()
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeContinuation(id) }
        }
        return stream
    }

    private func removeContinuation(_ id: UUID) {
        continuations[id] = nil
    }
}

/// The tolerance as it's written to the file, or none. A version field leaves room to migrate the format later.
private struct StoredTolerance: Codable {
    var version = 1
    var milligrams: Double?
    var nightsUnder: Int
    var nightsOver: Int

    init(_ tolerance: SleepTolerance?) {
        milligrams = tolerance?.milligrams
        nightsUnder = tolerance?.nightsUnder ?? 0
        nightsOver = tolerance?.nightsOver ?? 0
    }

    /// The tolerance the file describes, or `nil` for none.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if a value isn't valid, such as a tolerance outside 20 to 80 mg.
    func tolerance() throws -> SleepTolerance? {
        guard let milligrams else { return nil }
        guard (SleepToleranceRule.lowestTolerance...SleepToleranceRule.highestTolerance).contains(milligrams),
            nightsUnder >= 0, nightsOver >= 0
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "The stored tolerance isn't valid."))
        }
        return SleepTolerance(milligrams: milligrams, nightsUnder: nightsUnder, nightsOver: nightsOver)
    }
}
