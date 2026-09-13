//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveAppVersionRepository
//

/// The live app version repository. It reads the version from its injected ``AppVersionDataSource`` once, when it's
/// created, and holds it.
///
/// It's an actor off the main actor, like every repository (constitution Article I.13). The version never changes
/// while the app runs, so its stream sends it once, then finishes. The Settings article lists its requirement,
/// VERREPO-1.
actor LiveAppVersionRepository: AppVersionRepository {
    private let version: AppVersion?

    /// Creates the repository, reading the version from `dataSource`.
    ///
    /// - Parameter dataSource: Where the version comes from.
    init(dataSource: any AppVersionDataSource) {
        version = dataSource.appVersion()
    }

    /// Streams the version once, then finishes. Without a version, it finishes without sending one.
    nonisolated func appVersion() -> AsyncStream<AppVersion> {
        let version = version
        return AsyncStream { continuation in
            if let version {
                continuation.yield(version)
            }
            continuation.finish()
        }
    }
}
