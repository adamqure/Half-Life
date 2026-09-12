//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SimulatedPermissionDataSources
//

// Simulated permission data sources, for UI tests and previews.
//
// A UI test can't reliably answer Health's sheet, the notification alert, or the Face ID prompt, and the simulator's
// Face ID enrollment can't be set from a test. So when a UI test launches the app, and in previews, the permissions
// repository uses these instead: every request is allowed at once, and nothing touches a system framework. The real
// prompts are a manual check on a device. See the Onboarding article's "UI tests" section.

/// Health access that starts not requested and becomes requested once asked, with no sheet.
actor SimulatedHealthAccessDataSource: HealthAuthorizationDataSource {
    private var hasRequested = false

    /// Returns `requested` once access has been asked for, and `notRequested` before.
    func status() -> HealthAccessStatus {
        hasRequested ? .requested : .notRequested
    }

    /// Records the request, as if the user had answered Health's sheet.
    func requestAccess() {
        hasRequested = true
    }
}

/// Notification permission that starts not requested and becomes allowed once asked, with no alert.
actor SimulatedNotificationsDataSource: NotificationAuthorizationDataSource {
    private var permission = NotificationPermission.notRequested

    /// Returns the simulated permission.
    func status() -> NotificationPermission {
        permission
    }

    /// Allows notifications, as if the user had tapped Allow.
    func requestAuthorization() {
        permission = .allowed
    }
}

/// Face ID that's always available, and always authenticates, with no prompt.
struct SimulatedBiometricsDataSource: BiometricAuthenticationDataSource {
    /// Returns `available(.faceID)`.
    func availability() -> BiometricAvailability {
        .available(.faceID)
    }

    /// Returns at once, as if the user had allowed Face ID and passed the scan.
    func authenticate() async throws {}
}

/// A permission history held in memory, for the life of the app.
actor InMemoryPermissionHistoryDataSource: PermissionHistoryDataSource {
    private var requested = false

    /// Returns whether biometrics have been asked for since the app launched.
    func hasRequestedBiometrics() -> Bool {
        requested
    }

    /// Records that biometrics have been asked for.
    func recordBiometricsRequested() {
        requested = true
    }
}

/// A Settings opener that does nothing, so a UI test never leaves the app.
struct SimulatedSystemSettingsDataSource: SystemSettingsDataSource {
    /// Does nothing.
    @MainActor func openSettings() async {}
}

extension LivePermissionsRepository {
    /// A repository over the simulated data sources, for UI tests and previews.
    static func simulated() -> LivePermissionsRepository {
        LivePermissionsRepository(
            health: SimulatedHealthAccessDataSource(),
            notifications: SimulatedNotificationsDataSource(),
            biometrics: SimulatedBiometricsDataSource(), history: InMemoryPermissionHistoryDataSource(),
            settings: SimulatedSystemSettingsDataSource())
    }
}
