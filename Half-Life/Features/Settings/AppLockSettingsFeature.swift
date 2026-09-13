//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppLockSettingsFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// Settings' App lock section: an option that turns the lock on or off, named for the device's Face ID or Touch ID.
///
/// The option shows what the repository last published, so it changes once the change is stored (constitution Article
/// I.5). Turning it on asks for biometrics first if they haven't been asked for. While a change is under way, another
/// tap does nothing. A failed change says so until the next try. See the App Lock article, SETLOCK-1 to SETLOCK-3.
@Reducer nonisolated struct AppLockSettingsFeature {
    private static let logger = Logger(for: AppLockSettingsFeature.self)

    /// The section's state.
    @ObservableState
    struct State: Equatable {
        /// The lock the repository last published, or `nil` until it arrives.
        var appLock: AppLock?
        /// The biometric permission, which names the switch and says whether it can turn on, or `nil` until it
        /// arrives.
        var biometrics: BiometricPermission?
        /// Whether a change is under way.
        var isChanging = false
        /// Whether the last change failed.
        var changeFailed = false
    }

    /// What can happen in the section.
    enum Action {
        /// The section appeared, so it starts observing the lock and the permissions.
        case task
        /// The repository published the lock.
        case appLockUpdated(AppLock)
        /// The repository published the permissions.
        case permissionsUpdated(Permissions)
        /// The user switched the lock on or off.
        case lockSwitched(Bool)
        /// The change finished. `failed` is whether it failed.
        case changeFinished(failed: Bool)
    }

    @Dependency(\.observeAppLock) var observeAppLock
    @Dependency(\.observePermissions) var observePermissions
    @Dependency(\.turnOnAppLock) var turnOnAppLock
    @Dependency(\.turnOffAppLock) var turnOffAppLock

    /// Observes the lock and the permissions, and turns the lock on or off on request.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .merge(
                    .run { [observeAppLock] send in
                        for await lock in observeAppLock.execute(()) {
                            await send(.appLockUpdated(lock))
                        }
                    },
                    .run { [observePermissions] send in
                        for await permissions in observePermissions.execute(()) {
                            await send(.permissionsUpdated(permissions))
                        }
                    }
                )
            case let .appLockUpdated(lock):
                state.appLock = lock
                return .none
            case let .permissionsUpdated(permissions):
                state.biometrics = permissions.biometrics
                return .none
            case let .lockSwitched(isOn):
                guard !state.isChanging else { return .none }
                state.isChanging = true
                state.changeFailed = false
                return .run { [turnOnAppLock, turnOffAppLock] send in
                    if isOn {
                        try await turnOnAppLock.execute(())
                    } else {
                        try await turnOffAppLock.execute(())
                    }
                    await send(.changeFinished(failed: false))
                } catch: { error, send in
                    let domain = (error as NSError).domain
                    let code = (error as NSError).code
                    Self.logger.error(
                        "Couldn't change the app lock: \(domain, privacy: .public) \(code, privacy: .public)")
                    await send(.changeFinished(failed: true))
                }
            case let .changeFinished(failed):
                state.isChanging = false
                state.changeFailed = failed
                return .none
            }
        }
    }
}
