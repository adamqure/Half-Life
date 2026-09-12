//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life UserProfileDependencies
//

import ComposableArchitecture

extension DependencyValues {
    /// The app's user profile repository (constitution Article I.15).
    ///
    /// Live and in previews, it's one app-scoped ``LiveUserProfileRepository``, which has nothing stored yet. In tests,
    /// using it without overriding it reports an issue.
    var userProfileRepository: any UserProfileRepository {
        get { self[UserProfileRepositoryKey.self] }
        set { self[UserProfileRepositoryKey.self] = newValue }
    }

    /// Observes the user's profile through the app-scoped ``userProfileRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeUserProfile: ObserveUserProfileUseCase {
        get { self[ObserveUserProfileUseCaseKey.self] }
        set { self[ObserveUserProfileUseCaseKey.self] = newValue }
    }
}

private enum UserProfileRepositoryKey: DependencyKey {
    static let liveValue: any UserProfileRepository = LiveUserProfileRepository(
        dataSource: EmptyUserProfileDataSource()
    )
    static let previewValue: any UserProfileRepository = liveValue
    static let testValue: any UserProfileRepository = UnimplementedUserProfileRepository()
}

// Each value is built from the repository key's value directly, not through `@Dependency`. Dependency values are
// cached, so a lookup here would capture whichever repository was current the first time, including a test's
// override.
private enum ObserveUserProfileUseCaseKey: DependencyKey {
    static let liveValue = ObserveUserProfileUseCase(repository: UserProfileRepositoryKey.liveValue)
    static let previewValue = ObserveUserProfileUseCase(repository: UserProfileRepositoryKey.previewValue)
    static let testValue = ObserveUserProfileUseCase(repository: UserProfileRepositoryKey.testValue)
}

/// The profile repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedUserProfileRepository: UserProfileRepository {
    func profile() -> AsyncStream<UserProfile> {
        reportIssue("A test observed the user profile without overriding \\.userProfileRepository.")
        return AsyncStream { $0.finish() }
    }
}
