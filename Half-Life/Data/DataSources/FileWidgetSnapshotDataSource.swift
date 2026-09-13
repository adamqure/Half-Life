//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FileWidgetSnapshotDataSource
//

import Foundation
import OSLog

/// Stores the widgets' snapshot in one JSON file, in the App Group container the app and the widget extension share.
///
/// The app writes it, and the widget extension only reads it. The snapshot is health data, so the file is left out of
/// iCloud backups and never synced (constitution Article V.3.4), and nothing in it is logged. It's protected with
/// `NSFileProtectionCompleteUntilFirstUserAuthentication`, an Article V.4 exception: WidgetKit asks the extension for a
/// timeline whenever it chooses, including while the phone is locked. The Widgets article lists its requirements,
/// WSDS-1 to WSDS-4.
actor FileWidgetSnapshotDataSource: WidgetSnapshotDataSource {
    private static let logger = Logger(for: FileWidgetSnapshotDataSource.self)

    /// The App Group the app and the widget extension share.
    static let appGroupIdentifier = "group.com.quillanq.Half-Life"
    /// The name of the snapshot's file.
    static let fileName = "WidgetSnapshot.json"

    /// How the file is written: atomically, and readable once the phone has been unlocked after it starts, so WidgetKit
    /// can ask for a timeline while the phone is locked (WSDS-2).
    static let writingOptions: Data.WritingOptions = [.atomic, .completeFileProtectionUntilFirstUserAuthentication]

    /// The file the snapshot is stored in.
    nonisolated let fileURL: URL

    /// Creates a data source over `fileURL`. Nothing is read or written until it's asked.
    ///
    /// - Parameter fileURL: The file to store the snapshot in. Its directory is created on the first store.
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// The snapshot's file in the App Group container, or `nil` if the container isn't available, which happens only
    /// when the process lacks the App Group entitlement.
    static func appGroupFileURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appending(path: fileName)
    }

    /// Returns the stored snapshot, or `nil` if there's no file yet.
    ///
    /// - Throws: The file system's error if the file couldn't be read, or a decoding error if it's damaged. Either is
    ///   logged with its domain and code only.
    func storedSnapshot() throws -> WidgetSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(StoredSnapshot.self, from: data).snapshot()
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the widget snapshot: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            throw error
        }
    }

    /// Stores `snapshot` in place of the file's contents, and leaves the file out of iCloud backups.
    ///
    /// - Parameter snapshot: The snapshot to store.
    /// - Throws: The encoder's or the file system's error, logged with its domain and code only.
    func store(_ snapshot: WidgetSnapshot) throws {
        do {
            let data = try JSONEncoder().encode(StoredSnapshot(snapshot))
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
                "Couldn't store the widget snapshot: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            throw error
        }
    }
}

/// The snapshot as it's written to the file. A version field leaves room to migrate the format later. Dates are
/// seconds since the reference date, so they read back exactly.
private struct StoredSnapshot: Codable {
    struct Level: Codable {
        var date: TimeInterval
        var milligrams: Double
    }

    struct Favourite: Codable {
        var drink: String
        var quantity: Int
    }

    var version = 1
    var forecast: [Level]
    var bedtimeHour: Int
    var bedtimeMinute: Int
    var favourites: [Favourite]
    var latestDrinkAt: TimeInterval?
    var isOnboardingComplete: Bool
    var writtenAt: TimeInterval

    init(_ snapshot: WidgetSnapshot) {
        forecast = snapshot.forecast.map {
            Level(date: $0.date.timeIntervalSinceReferenceDate, milligrams: $0.milligrams)
        }
        bedtimeHour = snapshot.bedtime.hour
        bedtimeMinute = snapshot.bedtime.minute
        favourites = snapshot.favourites.map { Favourite(drink: $0.type.rawValue, quantity: $0.quantity) }
        latestDrinkAt = snapshot.latestDrinkAt?.timeIntervalSinceReferenceDate
        isOnboardingComplete = snapshot.isOnboardingComplete
        writtenAt = snapshot.writtenAt.timeIntervalSinceReferenceDate
    }

    /// The snapshot the file describes.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if a value isn't valid, such as an unknown drink.
    func snapshot() throws -> WidgetSnapshot {
        guard let bedtime = Bedtime(hour: bedtimeHour, minute: bedtimeMinute) else { throw Self.invalid }
        let favourites = try favourites.map { favourite in
            guard let type = DrinkType(rawValue: favourite.drink), favourite.quantity >= 1 else { throw Self.invalid }
            return FavouriteDrink(type: type, quantity: favourite.quantity)
        }
        return WidgetSnapshot(
            forecast: forecast.map {
                CaffeineLevel(date: Date(timeIntervalSinceReferenceDate: $0.date), milligrams: $0.milligrams)
            },
            bedtime: bedtime, favourites: favourites,
            latestDrinkAt: latestDrinkAt.map { Date(timeIntervalSinceReferenceDate: $0) },
            isOnboardingComplete: isOnboardingComplete, writtenAt: Date(timeIntervalSinceReferenceDate: writtenAt))
    }

    private static let invalid = DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: [], debugDescription: "The stored widget snapshot isn't valid."))
}
