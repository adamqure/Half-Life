//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveAppVersionUseCase
//

/// Streams the app's version and build.
///
/// Settings' root observes it, for its last line. The Settings article lists its requirement, VERUSE-1.
struct ObserveAppVersionUseCase: UseCase {
    /// The repository that holds the version.
    let repository: any AppVersionRepository

    /// Returns a stream of the app's version and build: once, then it finishes.
    func execute(_: Void) -> AsyncStream<AppVersion> {
        repository.appVersion()
    }
}
