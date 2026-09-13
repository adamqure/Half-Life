//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life PermissionsDependencies
//

import ComposableArchitecture

extension DependencyValues {
    /// The app's permissions repository (constitution Article I.15).
    ///
    /// Live, it's one app-scoped ``LivePermissionsRepository`` over HealthKit, UserNotifications, Local
    /// Authentication, and UIKit, or over simulated data sources when a UI test launched the app, so no test faces a
    /// system prompt. Previews use the simulated data sources too. In tests, using it without overriding it reports an
    /// issue.
    var permissionsRepository: any PermissionsRepository {
        get { self[PermissionsRepositoryKey.self] }
        set { self[PermissionsRepositoryKey.self] = newValue }
    }

    /// Observes the permissions through the app-scoped ``permissionsRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observePermissions: ObservePermissionsUseCase {
        get { self[ObservePermissionsUseCaseKey.self] }
        set { self[ObservePermissionsUseCaseKey.self] = newValue }
    }

    /// Requests Health access through the app-scoped ``permissionsRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var requestHealthAccess: RequestHealthAccessUseCase {
        get { self[RequestHealthAccessUseCaseKey.self] }
        set { self[RequestHealthAccessUseCaseKey.self] = newValue }
    }

    /// Requests notification permission through the app-scoped ``permissionsRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var requestNotificationPermission: RequestNotificationPermissionUseCase {
        get { self[RequestNotificationPermissionUseCaseKey.self] }
        set { self[RequestNotificationPermissionUseCaseKey.self] = newValue }
    }

    /// Requests biometric permission through the app-scoped ``permissionsRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var requestBiometricPermission: RequestBiometricPermissionUseCase {
        get { self[RequestBiometricPermissionUseCaseKey.self] }
        set { self[RequestBiometricPermissionUseCaseKey.self] = newValue }
    }

    /// Refreshes the permissions through the app-scoped ``permissionsRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var refreshPermissions: RefreshPermissionsUseCase {
        get { self[RefreshPermissionsUseCaseKey.self] }
        set { self[RefreshPermissionsUseCaseKey.self] = newValue }
    }

    /// Opens the Settings app through the app-scoped ``permissionsRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var openAppSettings: OpenAppSettingsUseCase {
        get { self[OpenAppSettingsUseCaseKey.self] }
        set { self[OpenAppSettingsUseCaseKey.self] = newValue }
    }
}

/// Registers the app-scoped permissions repository. The use cases in this file are built from it, and so is
/// ``TurnOnAppLockUseCase`` in `AppLockDependencies.swift`, which is why it isn't private.
enum PermissionsRepositoryKey: DependencyKey {
    static let liveValue: any PermissionsRepository =
        UITestLaunchConfiguration.current.isUITest
        ? LivePermissionsRepository.simulated()
        : LivePermissionsRepository(
            health: HealthKitAuthorizationDataSource(), notifications: UserNotificationsAuthorizationDataSource(),
            biometrics: LocalAuthenticationDataSource(), history: FilePermissionHistoryDataSource(),
            settings: UIKitSystemSettingsDataSource())
    static let previewValue: any PermissionsRepository = LivePermissionsRepository.simulated()
    static let testValue: any PermissionsRepository = UnimplementedPermissionsRepository()
}

// Each use case's values are built from the repository key's values directly, not through `@Dependency`, following
// the Architecture article's "Registering a repository and its use cases".
private enum ObservePermissionsUseCaseKey: DependencyKey {
    static let liveValue = ObservePermissionsUseCase(repository: PermissionsRepositoryKey.liveValue)
    static let previewValue = ObservePermissionsUseCase(repository: PermissionsRepositoryKey.previewValue)
    static let testValue = ObservePermissionsUseCase(repository: PermissionsRepositoryKey.testValue)
}

private enum RequestHealthAccessUseCaseKey: DependencyKey {
    static let liveValue = RequestHealthAccessUseCase(repository: PermissionsRepositoryKey.liveValue)
    static let previewValue = RequestHealthAccessUseCase(repository: PermissionsRepositoryKey.previewValue)
    static let testValue = RequestHealthAccessUseCase(repository: PermissionsRepositoryKey.testValue)
}

private enum RequestNotificationPermissionUseCaseKey: DependencyKey {
    static let liveValue = RequestNotificationPermissionUseCase(repository: PermissionsRepositoryKey.liveValue)
    static let previewValue = RequestNotificationPermissionUseCase(repository: PermissionsRepositoryKey.previewValue)
    static let testValue = RequestNotificationPermissionUseCase(repository: PermissionsRepositoryKey.testValue)
}

private enum RequestBiometricPermissionUseCaseKey: DependencyKey {
    static let liveValue = RequestBiometricPermissionUseCase(repository: PermissionsRepositoryKey.liveValue)
    static let previewValue = RequestBiometricPermissionUseCase(repository: PermissionsRepositoryKey.previewValue)
    static let testValue = RequestBiometricPermissionUseCase(repository: PermissionsRepositoryKey.testValue)
}

private enum RefreshPermissionsUseCaseKey: DependencyKey {
    static let liveValue = RefreshPermissionsUseCase(repository: PermissionsRepositoryKey.liveValue)
    static let previewValue = RefreshPermissionsUseCase(repository: PermissionsRepositoryKey.previewValue)
    static let testValue = RefreshPermissionsUseCase(repository: PermissionsRepositoryKey.testValue)
}

private enum OpenAppSettingsUseCaseKey: DependencyKey {
    static let liveValue = OpenAppSettingsUseCase(repository: PermissionsRepositoryKey.liveValue)
    static let previewValue = OpenAppSettingsUseCase(repository: PermissionsRepositoryKey.previewValue)
    static let testValue = OpenAppSettingsUseCase(repository: PermissionsRepositoryKey.testValue)
}

/// The permissions repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedPermissionsRepository: PermissionsRepository {
    func permissions() -> AsyncStream<Permissions> {
        reportIssue("A test observed the permissions without overriding \\.permissionsRepository.")
        return AsyncStream { $0.finish() }
    }

    func requestHealthAccess() async throws {
        reportIssue("A test requested Health access without overriding \\.permissionsRepository.")
    }

    func requestNotifications() async throws {
        reportIssue("A test requested notification permission without overriding \\.permissionsRepository.")
    }

    func requestBiometrics() async throws {
        reportIssue("A test requested biometric permission without overriding \\.permissionsRepository.")
    }

    func refresh() async {
        reportIssue("A test refreshed the permissions without overriding \\.permissionsRepository.")
    }

    func openSettings() async {
        reportIssue("A test opened the Settings app without overriding \\.permissionsRepository.")
    }
}
