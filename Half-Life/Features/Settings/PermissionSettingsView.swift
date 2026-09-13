//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life PermissionSettingsView
//

import ComposableArchitecture
import SwiftUI

/// Settings' Permissions screen: Apple Health, notifications, and Face ID or Touch ID, each on its own card.
///
/// The cards look and read like onboarding's permissions step. A status is written out with a symbol, never shown by
/// color alone (constitution Article VI.3). Apple Health can only say it has been asked, because HealthKit doesn't
/// tell an app what the user allowed. The Face ID or Touch ID card is hidden on a device with neither. When the app
/// becomes active again, the permissions refresh, because one can change in the Settings app. See the Settings and
/// Onboarding articles.
@MainActor
struct PermissionSettingsView: View {
    /// The permissions' store, the feature onboarding's step uses too.
    let store: StoreOf<PermissionsFeature>

    @Environment(\.scenePhase) private var scenePhase

    /// One card per permission, once the permissions have arrived, and the note under them.
    var body: some View {
        SettingsScreen(title: Text("Permissions"), screenIdentifier: PermissionSettingsViewAccessibilityID.screen) {
            VStack(alignment: .leading, spacing: Spacing.itemGap) {
                if let permissions = store.permissions {
                    healthRow(permissions.health)
                    notificationsRow(permissions.notifications)
                    biometricsRow(permissions.biometrics)
                }
                Text("Each one is optional. Half-Life works without any of them.")
                    .font(.footnote)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .task { await store.send(.task).finish() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.send(.appBecameActive)
            }
        }
    }

    private func healthRow(_ access: HealthAccessStatus) -> some View {
        PermissionCard(
            symbol: "heart.text.square", title: Text("Apple Health"),
            detail: Text(
                """
                Reads your sleep, steps, and resting heart rate. Nothing is written back, and your Health data never \
                leaves this iPhone.
                """
            )
        ) {
            switch access {
            case .notRequested:
                AllowButton(
                    label: Text("Allow Apple Health"),
                    identifier: PermissionSettingsViewAccessibilityID.healthAllowButton
                ) {
                    store.send(.allowHealthTapped)
                }
            case .requested:
                StatusLabel(
                    text: Text("Asked"), symbol: "checkmark.circle",
                    identifier: PermissionSettingsViewAccessibilityID.healthStatus)
                Text("Change what Half-Life reads in the Health app.")
                    .font(.footnote)
                    .foregroundStyle(Color.textPrimary)
            case .unavailable:
                StatusLabel(
                    text: Text("Not available on this device"), symbol: "minus.circle",
                    identifier: PermissionSettingsViewAccessibilityID.healthStatus)
            }
        }
    }

    private func notificationsRow(_ permission: NotificationPermission) -> some View {
        PermissionCard(
            symbol: "bell", title: Text("Notifications"),
            detail: Text("So Half-Life can remind you about your caffeine.")
        ) {
            switch permission {
            case .notRequested:
                AllowButton(
                    label: Text("Allow notifications"),
                    identifier: PermissionSettingsViewAccessibilityID.notificationsAllowButton
                ) {
                    store.send(.allowNotificationsTapped)
                }
            case .allowed:
                StatusLabel(
                    text: Text("On"), symbol: "checkmark.circle",
                    identifier: PermissionSettingsViewAccessibilityID.notificationsStatus)
            case .denied:
                StatusLabel(
                    text: Text("Off"), symbol: "xmark.circle",
                    identifier: PermissionSettingsViewAccessibilityID.notificationsStatus)
                OpenSettingsButton(
                    label: Text("Change notifications in Settings"),
                    identifier: PermissionSettingsViewAccessibilityID.notificationsSettingsButton
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
                    identifier: PermissionSettingsViewAccessibilityID.biometricsAllowButton
                ) {
                    store.send(.allowBiometricsTapped)
                }
            }
        case .allowed(let biometry):
            biometricsRow(biometry) {
                StatusLabel(
                    text: Text("On"), symbol: "checkmark.circle",
                    identifier: PermissionSettingsViewAccessibilityID.biometricsStatus)
            }
        case .denied(let biometry):
            biometricsRow(biometry) {
                StatusLabel(
                    text: Text("Off"), symbol: "xmark.circle",
                    identifier: PermissionSettingsViewAccessibilityID.biometricsStatus)
                OpenSettingsButton(
                    label: Text("Change \(Self.name(of: biometry)) in Settings"),
                    identifier: PermissionSettingsViewAccessibilityID.biometricsSettingsButton
                ) {
                    store.send(.openSettingsTapped)
                }
            }
        case .notEnrolled(let biometry):
            biometricsRow(biometry) {
                StatusLabel(
                    text: Text("Not set up"), symbol: "minus.circle",
                    identifier: PermissionSettingsViewAccessibilityID.biometricsStatus)
                Text("Set up \(Self.name(of: biometry)) in the Settings app.")
                    .font(.footnote)
                    .foregroundStyle(Color.textPrimary)
            }
        case .unavailable:
            EmptyView()
        }
    }

    private func biometricsRow(_ biometry: Biometry, @ViewBuilder status: () -> some View) -> some View {
        PermissionCard(
            symbol: Self.symbol(of: biometry), title: Self.name(of: biometry),
            detail: Text("Lets Half-Life check that it's you."), status: status)
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

/// One permission's card: an icon, a name, what it's for, and its status or action, as on onboarding's step.
@MainActor
private struct PermissionCard<Status: View>: View {
    let symbol: String
    let title: Text
    let detail: Text
    @ViewBuilder let status: Status

    var body: some View {
        SettingsCard {
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
                        // textPrimary, like the option rows' lines: the audit failed textSecondary footnotes on cards.
                        detail
                            .font(.footnote)
                            .foregroundStyle(Color.textPrimary)
                    }
                    Spacer(minLength: 0)
                }
                status
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// A card's Allow button. Its visible title is "Allow", and VoiceOver hears which permission it's for.
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

/// A card's button to the Settings app, for a permission that's off.
@MainActor
private struct OpenSettingsButton: View {
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

/// A card's status, written out beside a symbol, as one element for VoiceOver.
@MainActor
private struct StatusLabel: View {
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
