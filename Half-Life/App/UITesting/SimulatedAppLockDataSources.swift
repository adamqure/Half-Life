//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SimulatedAppLockDataSources
//

// Simulated app lock data sources, for UI tests and previews.
//
// A UI test can't answer the Face ID or passcode prompt, so when a UI test launches the app, and in previews, the app
// lock repository uses these instead, and nothing touches Local Authentication or the file system. The real prompt is a
// manual check on a device. See the App Lock article's "UI tests" section.

/// The app lock setting, held in memory for the life of the app. It starts off.
actor InMemoryAppLockSettingDataSource: AppLockSettingDataSource {
    private var enabled = false

    /// Returns whether the lock is on.
    func isEnabled() -> Bool {
        enabled
    }

    /// Stores whether the lock is on.
    func setEnabled(_ isEnabled: Bool) {
        enabled = isEnabled
    }
}

/// A simulated user who dismisses the first unlock prompt, then passes every one after it, with no prompt shown.
///
/// The lock screen asks by itself when it appears. Declining that first prompt keeps the lock screen showing, so a UI
/// test can check it, audit it, and then unlock it with its button.
actor SimulatedDeviceOwnerDataSource: DeviceOwnerAuthenticationDataSource {
    private var prompts = 0

    /// Returns `declined` for the first prompt, and `passed` for each one after.
    func authenticate() -> DeviceOwnerAuthenticationOutcome {
        prompts += 1
        return prompts == 1 ? .declined : .passed
    }
}

/// An app lock setting that never answers, for a UI test that holds the app on its splash screen.
///
/// The app lock never arrives, so the root never finishes launching, and the splash screen stays up for the test to
/// check and audit (see the Splash Screen article).
actor HeldAppLockSettingDataSource: AppLockSettingDataSource {
    /// Waits until the caller is cancelled, then throws `CancellationError`. It never returns a setting.
    func isEnabled() async throws -> Bool {
        // A day is far longer than any UI test runs.
        try await Task.sleep(for: .seconds(86_400))
        throw CancellationError()
    }

    /// Ignores the change, because a held launch never shows anything that could make it.
    func setEnabled(_ isEnabled: Bool) {}
}

extension LiveAppLockRepository {
    /// A repository over the simulated data sources, for UI tests and previews.
    ///
    /// - Parameter holdsLaunch: Whether the setting never answers, so the app stays on its splash screen.
    static func simulated(holdsLaunch: Bool = false) -> LiveAppLockRepository {
        LiveAppLockRepository(
            setting: holdsLaunch ? HeldAppLockSettingDataSource() : InMemoryAppLockSettingDataSource(),
            authentication: SimulatedDeviceOwnerDataSource())
    }
}
