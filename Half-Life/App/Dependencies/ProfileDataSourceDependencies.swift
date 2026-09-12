//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ProfileDataSourceDependencies
//

import ComposableArchitecture
import Foundation
import OSLog

/// Registers the one profile data source that ``UserProfileRepository`` and ``CaffeineDecayRepository`` share
/// (constitution Article I.15).
///
/// It has no `DependencyValues` property, because only repositories use data sources. Each repository key builds from
/// its values, so one instance sits behind both, and a store through one repository signals the other.
enum ProfileDataSourceKey: DependencyKey {
    /// The app's profile file in Application Support. Under a UI test, a temporary file seeded as the test asked
    /// (``UITestLaunchConfiguration``), so UI tests never touch the device's profile.
    static let liveValue: any ProfileDataSource = makeLiveValue(configuration: .current)

    /// A temporary file holding a profile that has finished onboarding, so previews show the app, not onboarding.
    static let previewValue: any ProfileDataSource = temporaryDataSource(
        seededWith: UserProfile(hasCompletedOnboarding: true))

    /// A data source that reports an issue when a test uses it.
    static let testValue: any ProfileDataSource = UnimplementedProfileDataSource()

    private static let logger = Logger(for: ProfileDataSourceKey.self)

    /// The live data source for a launch with `configuration`.
    ///
    /// - Parameter configuration: How a UI test asked the app to start, if one did.
    /// - Returns: The app's profile file outside UI tests, or a temporary one seeded as the UI test asked.
    static func makeLiveValue(configuration: UITestLaunchConfiguration) -> any ProfileDataSource {
        switch configuration.profile {
        case .completed:
            return temporaryDataSource(seededWith: UserProfile(hasCompletedOnboarding: true))
        case .fresh:
            return temporaryDataSource(seededWith: nil)
        case nil:
            do {
                return FileProfileDataSource(fileURL: try FileProfileDataSource.defaultFileURL())
            } catch {
                let error = error as NSError
                logger.fault(
                    "Application Support is missing: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
                return temporaryDataSource(seededWith: nil)
            }
        }
    }

    /// A data source over a new temporary file, holding `profile` if one is given.
    ///
    /// - Parameter profile: The profile to seed the file with, or `nil` to leave it empty.
    /// - Returns: The data source.
    static func temporaryDataSource(seededWith profile: UserProfile?) -> FileProfileDataSource {
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "Profile.json")
        if let profile {
            do {
                try FileProfileDataSource.write(profile, to: url)
            } catch {
                let error = error as NSError
                logger.error(
                    "Couldn't seed a profile: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            }
        }
        return FileProfileDataSource(fileURL: url)
    }
}

private struct UnimplementedProfileDataSourceError: Error {}

/// The profile data source in tests that haven't overridden a repository. Using it reports an issue.
private struct UnimplementedProfileDataSource: ProfileDataSource {
    func storedProfile() async throws -> UserProfile? {
        throw unimplemented("read the profile")
    }

    func store(_ profile: UserProfile) async throws {
        throw unimplemented("stored the profile")
    }

    func bedtime() async throws -> Bedtime {
        throw unimplemented("read the bedtime")
    }

    func halfLife() async throws -> CaffeineHalfLife {
        throw unimplemented("read the half-life")
    }

    func changes() async -> AsyncStream<Void> {
        _ = unimplemented("observed the profile's changes")
        return AsyncStream { $0.finish() }
    }

    private func unimplemented(_ action: String) -> UnimplementedProfileDataSourceError {
        reportIssue("A test \(action) through the profile data source without overriding a repository.")
        return UnimplementedProfileDataSourceError()
    }
}
