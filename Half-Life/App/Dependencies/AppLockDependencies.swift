//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppLockDependencies
//

import ComposableArchitecture

extension DependencyValues {
    /// The app's app lock repository (constitution Article I.15).
    ///
    /// Live, it's one app-scoped ``LiveAppLockRepository`` over a file and Local Authentication, or over simulated
    /// data sources when a UI test launched the app, so no test faces a prompt. Previews use the simulated data
    /// sources too. In tests, using it without overriding it reports an issue.
    var appLockRepository: any AppLockRepository {
        get { self[AppLockRepositoryKey.self] }
        set { self[AppLockRepositoryKey.self] = newValue }
    }

    /// Observes the lock through the app-scoped ``appLockRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeAppLock: ObserveAppLockUseCase {
        get { self[ObserveAppLockUseCaseKey.self] }
        set { self[ObserveAppLockUseCaseKey.self] = newValue }
    }

    /// Turns the lock on through the app-scoped ``appLockRepository`` and ``permissionsRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var turnOnAppLock: TurnOnAppLockUseCase {
        get { self[TurnOnAppLockUseCaseKey.self] }
        set { self[TurnOnAppLockUseCaseKey.self] = newValue }
    }

    /// Turns the lock off through the app-scoped ``appLockRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var turnOffAppLock: TurnOffAppLockUseCase {
        get { self[TurnOffAppLockUseCaseKey.self] }
        set { self[TurnOffAppLockUseCaseKey.self] = newValue }
    }

    /// Locks the app through the app-scoped ``appLockRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var lockApp: LockAppUseCase {
        get { self[LockAppUseCaseKey.self] }
        set { self[LockAppUseCaseKey.self] = newValue }
    }

    /// Unlocks the app through the app-scoped ``appLockRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var unlockApp: UnlockAppUseCase {
        get { self[UnlockAppUseCaseKey.self] }
        set { self[UnlockAppUseCaseKey.self] = newValue }
    }
}

/// Registers the app-scoped app lock repository. It's private, because only the use cases in this file are built
/// from it.
private enum AppLockRepositoryKey: DependencyKey {
    static let liveValue: any AppLockRepository =
        UITestLaunchConfiguration.current.isUITest
        ? LiveAppLockRepository.simulated(holdsLaunch: UITestLaunchConfiguration.current.holdsLaunch)
        : LiveAppLockRepository(
            setting: FileAppLockSettingDataSource(), authentication: LocalAuthenticationDeviceOwnerDataSource())
    static let previewValue: any AppLockRepository = LiveAppLockRepository.simulated()
    static let testValue: any AppLockRepository = UnimplementedAppLockRepository()
}

// Each use case's values are built from the repository keys' values directly, not through `@Dependency`, following
// the Architecture article's "Registering a repository and its use cases".
private enum ObserveAppLockUseCaseKey: DependencyKey {
    static let liveValue = ObserveAppLockUseCase(repository: AppLockRepositoryKey.liveValue)
    static let previewValue = ObserveAppLockUseCase(repository: AppLockRepositoryKey.previewValue)
    static let testValue = ObserveAppLockUseCase(repository: AppLockRepositoryKey.testValue)
}

private enum TurnOnAppLockUseCaseKey: DependencyKey {
    static let liveValue = TurnOnAppLockUseCase(
        permissions: PermissionsRepositoryKey.liveValue, appLock: AppLockRepositoryKey.liveValue)
    static let previewValue = TurnOnAppLockUseCase(
        permissions: PermissionsRepositoryKey.previewValue, appLock: AppLockRepositoryKey.previewValue)
    static let testValue = TurnOnAppLockUseCase(
        permissions: PermissionsRepositoryKey.testValue, appLock: AppLockRepositoryKey.testValue)
}

private enum TurnOffAppLockUseCaseKey: DependencyKey {
    static let liveValue = TurnOffAppLockUseCase(repository: AppLockRepositoryKey.liveValue)
    static let previewValue = TurnOffAppLockUseCase(repository: AppLockRepositoryKey.previewValue)
    static let testValue = TurnOffAppLockUseCase(repository: AppLockRepositoryKey.testValue)
}

private enum LockAppUseCaseKey: DependencyKey {
    static let liveValue = LockAppUseCase(repository: AppLockRepositoryKey.liveValue)
    static let previewValue = LockAppUseCase(repository: AppLockRepositoryKey.previewValue)
    static let testValue = LockAppUseCase(repository: AppLockRepositoryKey.testValue)
}

private enum UnlockAppUseCaseKey: DependencyKey {
    static let liveValue = UnlockAppUseCase(repository: AppLockRepositoryKey.liveValue)
    static let previewValue = UnlockAppUseCase(repository: AppLockRepositoryKey.previewValue)
    static let testValue = UnlockAppUseCase(repository: AppLockRepositoryKey.testValue)
}

/// The app lock repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedAppLockRepository: AppLockRepository {
    func appLock() -> AsyncStream<AppLock> {
        reportIssue("A test observed the app lock without overriding \\.appLockRepository.")
        return AsyncStream { $0.finish() }
    }

    func turnOn() async throws {
        reportIssue("A test turned the app lock on without overriding \\.appLockRepository.")
    }

    func turnOff() async throws {
        reportIssue("A test turned the app lock off without overriding \\.appLockRepository.")
    }

    func lock() async {
        reportIssue("A test locked the app without overriding \\.appLockRepository.")
    }

    func unlock() async throws {
        reportIssue("A test unlocked the app without overriding \\.appLockRepository.")
    }
}
