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
import Foundation

extension DependencyValues {
    /// The app's user profile repository (constitution Article I.15).
    ///
    /// Live and in previews, it's one app-scoped ``LiveUserProfileRepository``, over the shared
    /// ``ProfileDataSourceKey`` data source and ``SystemClockDataSource``. In tests, using it without overriding it
    /// reports an issue.
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

    /// Observes the recommended sleep through the app-scoped ``userProfileRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeRecommendedSleep: ObserveRecommendedSleepUseCase {
        get { self[ObserveRecommendedSleepUseCaseKey.self] }
        set { self[ObserveRecommendedSleepUseCaseKey.self] = newValue }
    }

    /// Saves the name and age through the app-scoped ``userProfileRepository``, with the current year from the
    /// app-scoped ``currentTimeRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var saveAboutYou: SaveAboutYouUseCase {
        get { self[SaveAboutYouUseCaseKey.self] }
        set { self[SaveAboutYouUseCaseKey.self] = newValue }
    }

    /// Saves the factors that change the half-life through the app-scoped ``userProfileRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var saveHalfLifeFactors: SaveHalfLifeFactorsUseCase {
        get { self[SaveHalfLifeFactorsUseCaseKey.self] }
        set { self[SaveHalfLifeFactorsUseCaseKey.self] = newValue }
    }

    /// Saves the bedtime through the app-scoped ``userProfileRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var saveBedtime: SaveBedtimeUseCase {
        get { self[SaveBedtimeUseCaseKey.self] }
        set { self[SaveBedtimeUseCaseKey.self] = newValue }
    }

    /// Records the end of onboarding through the app-scoped ``userProfileRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var completeOnboarding: CompleteOnboardingUseCase {
        get { self[CompleteOnboardingUseCaseKey.self] }
        set { self[CompleteOnboardingUseCaseKey.self] = newValue }
    }
}

private enum UserProfileRepositoryKey: DependencyKey {
    static let liveValue: any UserProfileRepository = LiveUserProfileRepository(
        dataSource: ProfileDataSourceKey.liveValue, clock: SystemClockDataSource())
    static let previewValue: any UserProfileRepository = LiveUserProfileRepository(
        dataSource: ProfileDataSourceKey.previewValue, clock: SystemClockDataSource())
    static let testValue: any UserProfileRepository = UnimplementedUserProfileRepository()
}

// Each value below is built from the repository key's value directly, not through `@Dependency`. Dependency values
// are cached, so a lookup here would capture whichever repository was current the first time, including a test's
// override.

private enum ObserveUserProfileUseCaseKey: DependencyKey {
    static let liveValue = ObserveUserProfileUseCase(repository: UserProfileRepositoryKey.liveValue)
    static let previewValue = ObserveUserProfileUseCase(repository: UserProfileRepositoryKey.previewValue)
    static let testValue = ObserveUserProfileUseCase(repository: UserProfileRepositoryKey.testValue)
}

private enum ObserveRecommendedSleepUseCaseKey: DependencyKey {
    static let liveValue = ObserveRecommendedSleepUseCase(repository: UserProfileRepositoryKey.liveValue)
    static let previewValue = ObserveRecommendedSleepUseCase(repository: UserProfileRepositoryKey.previewValue)
    static let testValue = ObserveRecommendedSleepUseCase(repository: UserProfileRepositoryKey.testValue)
}

private enum SaveAboutYouUseCaseKey: DependencyKey {
    static let liveValue = SaveAboutYouUseCase(
        currentTime: CurrentTimeRepositoryKey.liveValue, profile: UserProfileRepositoryKey.liveValue)
    static let previewValue = SaveAboutYouUseCase(
        currentTime: CurrentTimeRepositoryKey.previewValue, profile: UserProfileRepositoryKey.previewValue)
    static let testValue = SaveAboutYouUseCase(
        currentTime: CurrentTimeRepositoryKey.testValue, profile: UserProfileRepositoryKey.testValue)
}

private enum SaveHalfLifeFactorsUseCaseKey: DependencyKey {
    static let liveValue = SaveHalfLifeFactorsUseCase(repository: UserProfileRepositoryKey.liveValue)
    static let previewValue = SaveHalfLifeFactorsUseCase(repository: UserProfileRepositoryKey.previewValue)
    static let testValue = SaveHalfLifeFactorsUseCase(repository: UserProfileRepositoryKey.testValue)
}

private enum SaveBedtimeUseCaseKey: DependencyKey {
    static let liveValue = SaveBedtimeUseCase(repository: UserProfileRepositoryKey.liveValue)
    static let previewValue = SaveBedtimeUseCase(repository: UserProfileRepositoryKey.previewValue)
    static let testValue = SaveBedtimeUseCase(repository: UserProfileRepositoryKey.testValue)
}

private enum CompleteOnboardingUseCaseKey: DependencyKey {
    static let liveValue = CompleteOnboardingUseCase(repository: UserProfileRepositoryKey.liveValue)
    static let previewValue = CompleteOnboardingUseCase(repository: UserProfileRepositoryKey.previewValue)
    static let testValue = CompleteOnboardingUseCase(repository: UserProfileRepositoryKey.testValue)
}

private struct UnimplementedUserProfileRepositoryError: Error {}

/// The profile repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedUserProfileRepository: UserProfileRepository {
    func profile() -> AsyncStream<UserProfile> {
        reportIssue("A test observed the user profile without overriding \\.userProfileRepository.")
        return AsyncStream { $0.finish() }
    }

    func recommendedSleep(in calendar: Calendar) -> AsyncStream<RecommendedSleep> {
        reportIssue("A test observed the recommended sleep without overriding \\.userProfileRepository.")
        return AsyncStream { $0.finish() }
    }

    func saveAboutYou(name: String?, birthYear: Int?) async throws {
        throw unimplemented("saved the name and age")
    }

    func saveHalfLifeFactors(_ factors: Set<HalfLifeFactor>) async throws {
        throw unimplemented("saved the half-life factors")
    }

    func saveBedtime(_ bedtime: Bedtime) async throws {
        throw unimplemented("saved the bedtime")
    }

    func completeOnboarding() async throws {
        throw unimplemented("completed onboarding")
    }

    private func unimplemented(_ action: String) -> UnimplementedUserProfileRepositoryError {
        reportIssue("A test \(action) without overriding \\.userProfileRepository.")
        return UnimplementedUserProfileRepositoryError()
    }
}
