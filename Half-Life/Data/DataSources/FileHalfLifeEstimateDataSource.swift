//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FileHalfLifeEstimateDataSource
//

import Foundation
import OSLog

/// Stores the user's personal half-life estimate in one JSON file, on the device only.
///
/// The estimate is derived from Health data, so it's protected with `NSFileProtectionComplete`, left out of iCloud
/// backups, and never synced (constitution Articles V.3.4 and V.4), and nothing in it is logged. It's the estimate data
/// source for ``HalfLifeEstimateRepository``, and ``EstimatedHalfLifeDataSource`` reads the same instance for the
/// decay model, so a store signals the curve. The Half-Life Estimator article lists its requirements, ESTFILE-1 to
/// ESTFILE-4.
actor FileHalfLifeEstimateDataSource: HalfLifeEstimateDataSource {
    private static let logger = Logger(for: FileHalfLifeEstimateDataSource.self)

    /// The file the estimate is stored in.
    nonisolated let fileURL: URL
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    /// Creates a data source over `fileURL`. Nothing is read or written until it's asked.
    ///
    /// - Parameter fileURL: The file to store the estimate in. Its directory is created on the first store.
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// The app's estimate file: `HalfLifeEstimate.json` in Application Support.
    ///
    /// - Throws: The file manager's error if Application Support can't be located.
    static func defaultFileURL() throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appending(path: "HalfLifeEstimate.json")
    }

    /// How the file is written: atomically, and with `NSFileProtectionComplete`, so it can't be read while the device
    /// is locked (constitution Article V.4, ESTFILE-3).
    static let writingOptions: Data.WritingOptions = [.atomic, .completeFileProtection]

    /// Returns the stored estimate, or `nil` if there's no file yet.
    ///
    /// - Throws: The file system's error if the file couldn't be read, or a decoding error if it's damaged. Either is
    ///   logged with its domain and code only.
    func storedEstimate() throws -> HalfLifeEstimate? {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(StoredEstimate.self, from: data).estimate()
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the estimate: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            throw error
        }
    }

    /// Stores `estimate` in place of the file's contents, leaves the file out of iCloud backups, then signals every
    /// subscriber.
    ///
    /// - Parameter estimate: The estimate to store.
    /// - Throws: The encoder's or the file system's error, logged with its domain and code only. Nothing is signalled.
    func store(_ estimate: HalfLifeEstimate) throws {
        do {
            let data = try JSONEncoder().encode(StoredEstimate(estimate))
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
                "Couldn't store the estimate: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
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

/// The estimate as it's written to the file. A version field leaves room to migrate the format later.
private struct StoredEstimate: Codable {
    var version = 1
    var halfLifeSeconds: TimeInterval
    var lowerBoundSeconds: TimeInterval
    var upperBoundSeconds: TimeInterval
    var priorSeconds: TimeInterval
    var nightsUsed: Int
    /// When it was calculated, in seconds since the reference date, so it reads back exactly.
    var calculatedAt: TimeInterval

    init(_ estimate: HalfLifeEstimate) {
        halfLifeSeconds = estimate.halfLife.seconds
        lowerBoundSeconds = estimate.lowerBound.seconds
        upperBoundSeconds = estimate.upperBound.seconds
        priorSeconds = estimate.prior.seconds
        nightsUsed = estimate.nightsUsed
        calculatedAt = estimate.calculatedAt.timeIntervalSinceReferenceDate
    }

    /// The estimate the file describes.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if a value isn't valid, such as a half-life that isn't positive.
    func estimate() throws -> HalfLifeEstimate {
        guard let halfLife = CaffeineHalfLife(seconds: halfLifeSeconds),
            let lowerBound = CaffeineHalfLife(seconds: lowerBoundSeconds),
            let upperBound = CaffeineHalfLife(seconds: upperBoundSeconds),
            let prior = CaffeineHalfLife(seconds: priorSeconds),
            nightsUsed >= 0
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "The stored estimate isn't valid."))
        }
        return HalfLifeEstimate(
            halfLife: halfLife, lowerBound: lowerBound, upperBound: upperBound, prior: prior, nightsUsed: nightsUsed,
            calculatedAt: Date(timeIntervalSinceReferenceDate: calculatedAt))
    }
}
