//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AppLockSettingsSection
//

import ComposableArchitecture
import SwiftUI

/// Settings' App lock section: one option that turns the lock on or off, named for the device's Face ID or Touch ID.
///
/// The option is selected while the lock is on, which it shows with a check and the selected trait, never by color
/// alone (constitution Article VI.3). It's a ``SettingsOption`` rather than a switch, because the accessibility audit
/// failed every native switch row in Settings for Dynamic Type. The note under it says what the lock does, or why it
/// can't be turned on. The section waits for the lock and the permissions, and is hidden on a device with no
/// biometrics unless the lock is already on, so it can always be turned off. See the App Lock article.
@MainActor
struct AppLockSettingsSection: View {
    /// The section's store.
    let store: StoreOf<AppLockSettingsFeature>

    /// The option, its note, and a message when the last change failed.
    var body: some View {
        if let appLock = store.appLock, let biometrics = store.biometrics,
            Self.biometry(of: biometrics) != nil || appLock.isEnabled
        {
            SettingsSection(title: Text("App lock"), note: Self.note(appLock, biometrics)) {
                VStack(alignment: .leading, spacing: Spacing.itemGap) {
                    SettingsOption(
                        title: Self.title(Self.biometry(of: biometrics)), detail: nil, isSelected: appLock.isEnabled,
                        identifier: AppLockSettingsViewAccessibilityID.appLockOption
                    ) {
                        store.send(.lockSwitched(!appLock.isEnabled))
                    }
                    .disabled(store.isChanging || !(appLock.isEnabled || Self.canTurnOn(biometrics)))
                    .accessibilityHint(
                        appLock.isEnabled ? Text("Turns the app lock off.") : Text("Turns the app lock on."))
                    if store.changeFailed {
                        failure
                    }
                }
            }
        }
    }

    private var failure: some View {
        Label {
            Text("The app lock couldn't be changed. Try again.")
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
        }
        .font(.footnote)
        .foregroundStyle(Color.feedbackCaution)
        .padding(Spacing.itemGap)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.feedbackCautionBackground, in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
        )
        .accessibilityIdentifier(AppLockSettingsViewAccessibilityID.appLockError)
    }

    /// The device's biometry, or `nil` on a device with none.
    private static func biometry(of permission: BiometricPermission) -> Biometry? {
        switch permission {
        case .notRequested(let biometry), .allowed(let biometry), .denied(let biometry), .notEnrolled(let biometry):
            biometry
        case .unavailable:
            nil
        }
    }

    /// Whether the lock can be turned on: biometrics are allowed, or haven't been asked for yet.
    private static func canTurnOn(_ permission: BiometricPermission) -> Bool {
        switch permission {
        case .notRequested, .allowed: true
        case .denied, .notEnrolled, .unavailable: false
        }
    }

    private static func title(_ biometry: Biometry?) -> Text {
        guard let biometry else { return Text("Lock Half-Life") }
        return Text("Lock with \(name(of: biometry))")
    }

    /// What the lock does, or, while it's off and can't turn on, what to change in the Settings app.
    private static func note(_ appLock: AppLock, _ permission: BiometricPermission) -> Text {
        switch permission {
        case .denied(let biometry) where !appLock.isEnabled:
            Text("Allow \(name(of: biometry)) for Half-Life in the Settings app to turn the lock on.")
        case .notEnrolled(let biometry) where !appLock.isEnabled:
            Text("Set up \(name(of: biometry)) in the Settings app to turn the lock on.")
        default:
            Text(
                """
                Half-Life locks each time you leave it, and asks for Face ID, Touch ID, or your passcode to open it \
                again.
                """
            )
        }
    }

    private static func name(of biometry: Biometry) -> Text {
        switch biometry {
        case .faceID: Text("Face ID")
        case .touchID: Text("Touch ID")
        case .opticID: Text("Optic ID")
        }
    }
}
