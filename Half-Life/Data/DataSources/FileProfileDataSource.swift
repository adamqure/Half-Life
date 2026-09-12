//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FileProfileDataSource
//

import Foundation
import OSLog

/// Stores the user's profile in one JSON file, protected with `NSFileProtectionComplete`, on the device only.
///
/// It's the profile data source for ``UserProfileRepository``, and serves the bedtime and the half-life from the
/// same file to ``CaffeineDecayRepository``. One instance sits behind both, so a store through one repository signals
/// the other (the shared-data-source pattern in the Architecture article). The file holds health data, such as a
/// pregnancy, so it never syncs and nothing in it is logged. The Onboarding article lists its requirements,
/// PROFFILE-1 to PROFFILE-4.
actor FileProfileDataSource: ProfileDataSource {
    private static let logger = Logger(for: FileProfileDataSource.self)

    /// The file the profile is stored in.
    let fileURL: URL
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    /// Creates a data source over `fileURL`. Nothing is read or written until it's asked.
    ///
    /// - Parameter fileURL: The file to store the profile in. Its directory is created on the first store.
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// The app's profile file: `Profile.json` in Application Support.
    ///
    /// - Throws: The file manager's error if Application Support can't be located.
    static func defaultFileURL() throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appending(path: "Profile.json")
    }

    /// How the file is written: atomically, and with `NSFileProtectionComplete`, so it can't be read while the device
    /// is locked (constitution Article V.4, PROFFILE-1).
    static let writingOptions: Data.WritingOptions = [.atomic, .completeFileProtection]

    /// Writes `profile` to `url` with ``writingOptions``, creating its directory if needed.
    ///
    /// ``store(_:)`` writes through it. It's also how a UI test's or a preview's temporary file is seeded before the
    /// data source exists.
    ///
    /// - Parameters:
    ///   - profile: The profile to write.
    ///   - url: The file to write it to.
    /// - Throws: The encoder's or the file system's error.
    static func write(_ profile: UserProfile, to url: URL) throws {
        let data = try JSONEncoder().encode(StoredProfile(profile))
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: writingOptions)
    }

    /// Returns the stored profile, or `nil` if there's no file yet.
    ///
    /// - Throws: The file system's error if the file couldn't be read, or a decoding error if it's damaged. Either is
    ///   logged with its domain and code only.
    func storedProfile() throws -> UserProfile? {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(StoredProfile.self, from: data).profile()
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the profile: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            throw error
        }
    }

    /// Returns the stored bedtime, or ``Bedtime/standard`` if there's no file yet.
    ///
    /// - Throws: The same errors as ``storedProfile()``.
    func bedtime() throws -> Bedtime {
        try storedProfile()?.bedtime ?? .standard
    }

    /// Returns the stored half-life, or ``CaffeineHalfLife/standard`` if there's no file yet.
    ///
    /// - Throws: The same errors as ``storedProfile()``.
    func halfLife() throws -> CaffeineHalfLife {
        try storedProfile()?.halfLife ?? .standard
    }

    /// Stores `profile` in place of the file's contents, then signals every subscriber.
    ///
    /// - Parameter profile: The profile to store.
    /// - Throws: The encoder's or the file system's error, logged with its domain and code only. Nothing is signalled.
    func store(_ profile: UserProfile) throws {
        do {
            try Self.write(profile, to: fileURL)
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't store the profile: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
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

/// The profile as it's written to the file. A version field leaves room to migrate the format later.
private struct StoredProfile: Codable {
    var version = 1
    var name: String?
    var birthYear: Int?
    var halfLifeFactors: [String]
    var bedtimeHour: Int
    var bedtimeMinute: Int
    var halfLifeSeconds: TimeInterval
    var hasCompletedOnboarding: Bool

    init(_ profile: UserProfile) {
        name = profile.name
        birthYear = profile.birthYear
        halfLifeFactors = profile.halfLifeFactors.map(\.storedCode).sorted()
        bedtimeHour = profile.bedtime.hour
        bedtimeMinute = profile.bedtime.minute
        halfLifeSeconds = profile.halfLife.seconds
        hasCompletedOnboarding = profile.hasCompletedOnboarding
    }

    /// The profile the file describes.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if a value isn't valid, such as an unknown factor or a bedtime that
    ///   isn't a time of day.
    func profile() throws -> UserProfile {
        guard let bedtime = Bedtime(hour: bedtimeHour, minute: bedtimeMinute),
            let halfLife = CaffeineHalfLife(seconds: halfLifeSeconds)
        else {
            throw Self.damaged("The stored bedtime or half-life isn't valid.")
        }
        let factors = try halfLifeFactors.map { code in
            guard let factor = HalfLifeFactor(storedCode: code) else { throw Self.damaged("Unknown factor.") }
            return factor
        }
        return UserProfile(
            name: name, birthYear: birthYear, halfLifeFactors: Set(factors), bedtime: bedtime, halfLife: halfLife,
            hasCompletedOnboarding: hasCompletedOnboarding)
    }

    private static func damaged(_ description: String) -> DecodingError {
        .dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: description))
    }
}

extension HalfLifeFactor {
    /// The factor's code in the profile file. Codes never change, so older files still read.
    fileprivate var storedCode: String {
        switch self {
        case .pregnant(.first): "pregnant.first"
        case .pregnant(.second): "pregnant.second"
        case .pregnant(.third): "pregnant.third"
        case .estrogen: "estrogen"
        case .smokes: "smokes"
        case .cirrhosis: "cirrhosis"
        case .fluvoxamine: "fluvoxamine"
        }
    }

    /// The factor with the given code, or `nil` for a code this version doesn't know.
    fileprivate init?(storedCode: String) {
        let all: [HalfLifeFactor] =
            Trimester.allCases.map { .pregnant($0) } + [.estrogen, .smokes, .cirrhosis, .fluvoxamine]
        guard let factor = all.first(where: { $0.storedCode == storedCode }) else { return nil }
        self = factor
    }
}
