//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life OnboardingSummaryView
//

import ComposableArchitecture
import SwiftUI

/// Onboarding's summary: what Half-Life starts from, and the two ways out.
///
/// It calls the half-life an estimate, and makes no promise about when it gets better, because the estimator that
/// would refine it isn't built (the brief's *Honesty* criterion). See the Onboarding article.
@MainActor
struct OnboardingSummaryView: View {
    /// The step's store.
    let store: StoreOf<OnboardingSummaryFeature>

    @Environment(\.calendar) private var calendar
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The step's content.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
                    title
                        .font(.titleLarge)
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier(OnboardingSummaryViewAccessibilityID.title)
                    Text("Here's what Half-Life starts from. Your half-life is an estimate from what you told it.")
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                }
                if let profile = store.profile {
                    summary(of: profile)
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.itemGap)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier(OnboardingSummaryViewAccessibilityID.content)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Spacing.itemGap) {
                OnboardingPrimaryButton(
                    title: Text("Log my first cup"), identifier: OnboardingSummaryViewAccessibilityID.logFirstCupButton
                ) {
                    store.send(.logFirstCupTapped)
                }
                Button {
                    store.send(.takeMeToTodayTapped)
                } label: {
                    Text("Take me to Today")
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: Sizing.minimumHitTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(OnboardingSummaryViewAccessibilityID.takeMeToTodayButton)
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.itemGap)
            // The buttons get the page behind them, so the summary never scrolls under "Take me to Today", which
            // the accessibility audit failed for contrast.
            .background { OnboardingStepBackground() }
        }
        .background { OnboardingStepBackground() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(OnboardingSummaryViewAccessibilityID.screen)
        .task { await store.send(.task).finish() }
    }

    private var title: Text {
        if let name = store.profile?.name {
            return Text("You're set, \(name).")
        }
        return Text("You're set.")
    }

    private func summary(of profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            SummaryRow(
                label: Text("Starting half-life"), value: Text(OnboardingFormat.hours(profile.halfLife)),
                identifier: OnboardingSummaryViewAccessibilityID.halfLife, isStacked: isStacked)
            Divider().overlay(Color.separatorOnCard)
            SummaryRow(
                label: Text("Asleep by"), value: Text(OnboardingFormat.time(profile.bedtime, in: calendar)),
                identifier: OnboardingSummaryViewAccessibilityID.bedtime, isStacked: isStacked)
            if let range = store.recommendedSleep {
                let hours = OnboardingFormat.hourRange(range)
                Divider().overlay(Color.separatorOnCard)
                SummaryRow(
                    label: Text("Recommended sleep"), value: Text("\(hours.minimum)–\(hours.maximum) hours"),
                    identifier: OnboardingSummaryViewAccessibilityID.recommendedSleep, isStacked: isStacked)
            }
            if let permissions = store.permissions {
                Divider().overlay(Color.separatorOnCard)
                SummaryRow(
                    label: Text("Apple Health"), value: Self.status(of: permissions.health), isStacked: isStacked)
                Divider().overlay(Color.separatorOnCard)
                SummaryRow(
                    label: Text("Notifications"), value: Self.status(of: permissions.notifications),
                    isStacked: isStacked)
                if let biometrics = Self.status(of: permissions.biometrics) {
                    Divider().overlay(Color.separatorOnCard)
                    SummaryRow(label: biometrics.name, value: biometrics.status, isStacked: isStacked)
                }
            }
        }
        .padding(.horizontal, Spacing.cardPadding)
        .background(Color.surfaceCard, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
    }

    /// Whether each row stacks its value under its label, at accessibility text sizes.
    private var isStacked: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private static func status(of health: HealthAccessStatus) -> Text {
        switch health {
        case .notRequested: Text("Not asked")
        case .requested: Text("Asked")
        case .unavailable: Text("Not available")
        }
    }

    private static func status(of notifications: NotificationPermission) -> Text {
        switch notifications {
        case .notRequested: Text("Not asked")
        case .allowed: Text("On")
        case .denied: Text("Off")
        }
    }

    /// The biometrics row's name and status, or `nil` on a device with no biometrics, where the row is hidden.
    private static func status(of biometrics: BiometricPermission) -> (name: Text, status: Text)? {
        switch biometrics {
        case .notRequested(let biometry): (name(of: biometry), Text("Not asked"))
        case .allowed(let biometry): (name(of: biometry), Text("On"))
        case .denied(let biometry): (name(of: biometry), Text("Off"))
        case .notEnrolled(let biometry): (name(of: biometry), Text("Not set up"))
        case .unavailable: nil
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

/// One line of the summary: a label and its value, read by VoiceOver as one element.
@MainActor
private struct SummaryRow: View {
    let label: Text
    let value: Text
    var identifier: String?
    let isStacked: Bool

    var body: some View {
        let layout =
            isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.itemGap / 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Spacing.itemGap))
        layout {
            label
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            if !isStacked {
                Spacer(minLength: Spacing.itemGap)
            }
            value
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(isStacked ? .leading : .trailing)
        }
        .padding(.vertical, Spacing.cardPaddingCompact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier ?? "")
    }
}
