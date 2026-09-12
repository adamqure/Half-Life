//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life PermissionsFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// Onboarding's permissions step: one row each for Apple Health, notifications, and Face ID or Touch ID.
///
/// Each row's action asks through a use case, and the step learns the outcome from the permissions it observes
/// (constitution Article I.6). Health is asked for only when the user taps (Article V.3.1). When the app becomes active
/// again, the step refreshes, because a permission can change in the Settings app. See the Onboarding article, ONB-7.
@Reducer nonisolated struct PermissionsFeature {
    private static let logger = Logger(for: PermissionsFeature.self)

    /// The step's state.
    @ObservableState
    struct State: Equatable {
        /// The permissions the repository last published, or `nil` until they arrive.
        var permissions: Permissions?
    }

    /// What can happen in the step.
    enum Action {
        /// The step appeared, so it starts observing the permissions.
        case task
        /// The repository published the permissions.
        case permissionsUpdated(Permissions)
        /// The user tapped Allow on the Apple Health row.
        case allowHealthTapped
        /// The user tapped Allow on the notifications row.
        case allowNotificationsTapped
        /// The user tapped Allow on the Face ID or Touch ID row.
        case allowBiometricsTapped
        /// The user tapped a row's button to change a permission in the Settings app.
        case openSettingsTapped
        /// The app became active again, perhaps after the Settings app.
        case appBecameActive
        /// The user tapped Continue.
        case continueTapped
        /// What the step tells onboarding.
        case delegate(Delegate)
    }

    /// What the step tells ``OnboardingFeature``.
    @CasePathable
    enum Delegate {
        /// The user continued to the next step.
        case continued
    }

    @Dependency(\.observePermissions) var observePermissions
    @Dependency(\.requestHealthAccess) var requestHealthAccess
    @Dependency(\.requestNotificationPermission) var requestNotificationPermission
    @Dependency(\.requestBiometricPermission) var requestBiometricPermission
    @Dependency(\.refreshPermissions) var refreshPermissions
    @Dependency(\.openAppSettings) var openAppSettings

    /// Asks for each permission on request, and reduces the permissions into `State`.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observePermissions] send in
                    for await permissions in observePermissions.execute(()) {
                        await send(.permissionsUpdated(permissions))
                    }
                }
            case let .permissionsUpdated(permissions):
                state.permissions = permissions
                return .none
            case .allowHealthTapped:
                return request("Health access") { [requestHealthAccess] in try await requestHealthAccess.execute(()) }
            case .allowNotificationsTapped:
                return request("notifications") { [requestNotificationPermission] in
                    try await requestNotificationPermission.execute(())
                }
            case .allowBiometricsTapped:
                return request("biometrics") { [requestBiometricPermission] in
                    try await requestBiometricPermission.execute(())
                }
            case .openSettingsTapped:
                return .run { [openAppSettings] _ in await openAppSettings.execute(()) }
            case .appBecameActive:
                return .run { [refreshPermissions] _ in await refreshPermissions.execute(()) }
            case .continueTapped:
                return .send(.delegate(.continued))
            case .delegate:
                return .none
            }
        }
    }

    /// Runs a permission request. A failure is logged, and the row keeps its status.
    private func request(
        _ permission: String, _ operation: @escaping @Sendable () async throws -> Void
    ) -> Effect<Action> {
        .run { _ in
            try await operation()
        } catch: { error, _ in
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't ask: \(permission, privacy: .public) \(domain, privacy: .public) \(code, privacy: .public)"
            )
        }
    }
}
