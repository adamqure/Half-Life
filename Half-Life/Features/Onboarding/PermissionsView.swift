//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life PermissionsView
//

import ComposableArchitecture
import SwiftUI

/// Onboarding's permissions step: Apple Health, notifications, and Face ID or Touch ID, each with its status.
///
/// A status is written out with a symbol, never shown by color alone (constitution Article VI.3). Apple Health can
/// only say it has been asked, because HealthKit doesn't tell an app what the user allowed. The row for Face ID or
/// Touch ID is hidden on a device with neither. See the Onboarding article.
@MainActor
struct PermissionsView: View {
    /// The step's store.
    let store: StoreOf<PermissionsFeature>

    @Environment(\.scenePhase) private var scenePhase

    /// Tells the step the user tapped Continue.
    private func continueTapped() {
        store.send(.continueTapped)
    }

    /// The step's content.
    var body: some View {
        OnboardingStepLayout(
            step: 4, title: Text("Permissions"),
            lead: Text("Each one is optional. Half-Life works without any of them."),
            screenIdentifier: PermissionsViewAccessibilityID.screen,
            contentIdentifier: PermissionsViewAccessibilityID.content, buttonTitle: Text("Continue"),
            buttonIdentifier: PermissionsViewAccessibilityID.continueButton,
            action: continueTapped
        ) {
            if let permissions = store.permissions {
                VStack(spacing: Spacing.itemGap) {
                    healthRow(permissions.health)
                    notificationsRow(permissions.notifications)
                    biometricsRow(permissions.biometrics)
                }
            }
        }
        .task { await store.send(.task).finish() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.send(.appBecameActive)
            }
        }
    }

    private func healthRow(_ status: HealthAccessStatus) -> some View {
        PermissionRow(
            symbol: "heart.text.square", title: Text("Apple Health"),
            detail: Text(
                """
                Reads your sleep, steps, and resting heart rate. Nothing is written back, and your Health data never \
                leaves this iPhone.
                """
            )
        ) {
            switch status {
            case .notRequested:
                AllowButton(
                    label: Text("Allow Apple Health"), identifier: PermissionsViewAccessibilityID.healthAllowButton
                ) {
                    store.send(.allowHealthTapped)
                }
            case .requested:
                PermissionStatus(
                    text: Text("Asked"), symbol: "checkmark.circle",
                    identifier: PermissionsViewAccessibilityID.healthStatus)
                Text("Change what Half-Life reads in the Health app.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            case .unavailable:
                PermissionStatus(
                    text: Text("Not available on this device"), symbol: "minus.circle",
                    identifier: PermissionsViewAccessibilityID.healthStatus)
            }
        }
    }

    private func notificationsRow(_ status: NotificationPermission) -> some View {
        PermissionRow(
            symbol: "bell", title: Text("Notifications"),
            detail: Text("So Half-Life can remind you about your caffeine.")
        ) {
            switch status {
            case .notRequested:
                AllowButton(
                    label: Text("Allow notifications"),
                    identifier: PermissionsViewAccessibilityID.notificationsAllowButton
                ) {
                    store.send(.allowNotificationsTapped)
                }
            case .allowed:
                PermissionStatus(
                    text: Text("On"), symbol: "checkmark.circle",
                    identifier: PermissionsViewAccessibilityID.notificationsStatus)
            case .denied:
                PermissionStatus(
                    text: Text("Off"), symbol: "xmark.circle",
                    identifier: PermissionsViewAccessibilityID.notificationsStatus)
                SettingsButton(
                    label: Text("Change notifications in Settings"),
                    identifier: PermissionsViewAccessibilityID.notificationsSettingsButton
                ) {
                    store.send(.openSettingsTapped)
                }
            }
        }
    }

    @ViewBuilder
    private func biometricsRow(_ permission: BiometricPermission) -> some View {
        switch permission {
        case .notRequested(let biometry):
            biometricsRow(biometry) {
                AllowButton(
                    label: Text("Allow \(Self.name(of: biometry))"),
                    identifier: PermissionsViewAccessibilityID.biometricsAllowButton
                ) {
                    store.send(.allowBiometricsTapped)
                }
            }
        case .allowed(let biometry):
            biometricsRow(biometry) {
                PermissionStatus(
                    text: Text("On"), symbol: "checkmark.circle",
                    identifier: PermissionsViewAccessibilityID.biometricsStatus)
            }
        case .denied(let biometry):
            biometricsRow(biometry) {
                PermissionStatus(
                    text: Text("Off"), symbol: "xmark.circle",
                    identifier: PermissionsViewAccessibilityID.biometricsStatus)
                SettingsButton(
                    label: Text("Change \(Self.name(of: biometry)) in Settings"),
                    identifier: PermissionsViewAccessibilityID.biometricsSettingsButton
                ) {
                    store.send(.openSettingsTapped)
                }
            }
        case .notEnrolled(let biometry):
            biometricsRow(biometry) {
                PermissionStatus(
                    text: Text("Not set up"), symbol: "minus.circle",
                    identifier: PermissionsViewAccessibilityID.biometricsStatus)
                Text("Set up \(Self.name(of: biometry)) in the Settings app.")
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
        case .unavailable:
            EmptyView()
        }
    }

    private func biometricsRow(_ biometry: Biometry, @ViewBuilder status: () -> some View) -> some View {
        PermissionRow(
            symbol: Self.symbol(of: biometry), title: Self.name(of: biometry),
            detail: Text(
                """
                Locks Half-Life each time you leave it, so only you can see your caffeine and health data. You can \
                turn the lock off in Settings.
                """
            ), status: status)
    }

    private static func name(of biometry: Biometry) -> Text {
        switch biometry {
        case .faceID: Text("Face ID")
        case .touchID: Text("Touch ID")
        case .opticID: Text("Optic ID")
        }
    }

    private static func symbol(of biometry: Biometry) -> String {
        switch biometry {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        }
    }
}

/// One permission: an icon, a name, what it's for, and its status or action.
@MainActor
private struct PermissionRow<Status: View>: View {
    let symbol: String
    let title: Text
    let detail: Text
    @ViewBuilder let status: Status

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            HStack(alignment: .top, spacing: Spacing.itemGap) {
                Image(systemName: symbol)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: Sizing.iconTile, height: Sizing.iconTile)
                    .background(
                        Color.surfaceMuted,
                        in: RoundedRectangle(cornerRadius: CornerRadius.extraSmall, style: .continuous)
                    )
                    .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    title
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    detail
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer(minLength: 0)
            }
            status
        }
        .padding(Spacing.cardPaddingCompact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceCard, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

/// A row's Allow button. Its visible title is "Allow", and VoiceOver hears which permission it's for.
@MainActor
private struct AllowButton: View {
    let label: Text
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Allow")
                .font(.headline)
                .foregroundStyle(Color.textOnEmphasis)
                .padding(.horizontal, Spacing.cardPaddingCompact)
                .frame(minWidth: Sizing.minimumHitTarget, minHeight: Sizing.chipHeight)
                .background(
                    Color.actionPrimary, in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
    }
}

/// A row's button to the Settings app, for a permission that's off.
@MainActor
private struct SettingsButton: View {
    let label: Text
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Open Settings")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textAccent)
                .frame(minWidth: Sizing.minimumHitTarget, minHeight: Sizing.minimumHitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
    }
}

/// A row's status, written out beside a symbol, as one element for VoiceOver.
@MainActor
private struct PermissionStatus: View {
    let text: Text
    let symbol: String
    let identifier: String

    var body: some View {
        HStack(spacing: Spacing.itemGap / 2) {
            Image(systemName: symbol)
                .accessibilityHidden(true)
            text
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.textPrimary)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}
