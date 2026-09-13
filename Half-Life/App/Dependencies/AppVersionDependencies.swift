//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppVersionDependencies
//

import ComposableArchitecture

extension DependencyValues {
    /// Observes the app's version and build through the one app-scoped app version repository (constitution Article
    /// I.15).
    ///
    /// Live and in previews, the repository reads the app bundle's Info.plist. In tests, using it without overriding
    /// it reports an issue.
    var observeAppVersion: ObserveAppVersionUseCase {
        get { self[ObserveAppVersionUseCaseKey.self] }
        set { self[ObserveAppVersionUseCaseKey.self] = newValue }
    }
}

/// Registers the app-scoped app version repository. It's private, because only this file's use case is built from it.
private enum AppVersionRepositoryKey: DependencyKey {
    static let liveValue: any AppVersionRepository = LiveAppVersionRepository(dataSource: BundleAppVersionDataSource())
    static let previewValue: any AppVersionRepository = liveValue
    static let testValue: any AppVersionRepository = UnimplementedAppVersionRepository()
}

private enum ObserveAppVersionUseCaseKey: DependencyKey {
    static let liveValue = ObserveAppVersionUseCase(repository: AppVersionRepositoryKey.liveValue)
    static let previewValue = ObserveAppVersionUseCase(repository: AppVersionRepositoryKey.previewValue)
    static let testValue = ObserveAppVersionUseCase(repository: AppVersionRepositoryKey.testValue)
}

/// The app version repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedAppVersionRepository: AppVersionRepository {
    func appVersion() -> AsyncStream<AppVersion> {
        reportIssue("A test observed the app version without overriding \\.observeAppVersion.")
        return AsyncStream { $0.finish() }
    }
}
