//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeAppVersionRepository
//

@testable import Half_Life

/// An app version repository that streams given versions, for use case and feature tests.
struct FakeAppVersionRepository: AppVersionRepository {
    /// The versions that `appVersion()` streams, in order, before it finishes.
    let versions: [AppVersion]

    func appVersion() -> AsyncStream<AppVersion> {
        AsyncStream { continuation in
            for version in versions {
                continuation.yield(version)
            }
            continuation.finish()
        }
    }
}
