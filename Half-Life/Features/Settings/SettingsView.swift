//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SettingsView
//

import ComposableArchitecture
import SwiftUI

/// The Settings tab: a root list of rows on a navigation stack, each opening its own screen.
///
/// It's in the app's own style, like onboarding: a large title on the canvas's solid top color, and the rows on cards.
/// Each row shows its current value where it has one, such as the name or the bedtime, from the sections
/// the root observes. Tapping a row pushes its screen, which ``SettingsFeature`` holds in its path (constitution
/// Article I.6). Under the rows are the app's version and build, and a link to the privacy policy
/// (``PrivacyPolicy``). The root's `screen` identifier is on its scroll view, which is also what its robot swipes. See
/// the Settings article.
@MainActor
struct SettingsView: View {
    /// The tab's store.
    @Bindable var store: StoreOf<SettingsFeature>

    @Environment(\.calendar) private var calendar

    /// The root list, with the pushed screens on its navigation stack.
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            root
        } destination: { screen in
            switch screen.case {
            case let .aboutYou(store): AboutYouSettingsView(store: store)
            case let .halfLifeFactors(store): FactorsSettingsView(store: store)
            case let .bedtime(store): BedtimeSettingsView(store: store)
            case let .permissions(store): PermissionSettingsView(store: store)
            case let .appLock(store): AppLockSettingsView(store: store)
            case let .demoData(store): DemoHistorySettingsView(store: store)
            }
        }
        .task { await store.send(.profile(.task)).finish() }
        .task { await store.send(.appLock(.task)).finish() }
        .task { await store.send(.demoHistory(.task)).finish() }
        .task { await store.send(.task).finish() }
    }

    private var root: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                Text("Settings")
                    .font(.titleLarge)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                SettingsCard {
                    VStack(alignment: .leading, spacing: 0) {
                        row(
                            .aboutYou, title: Text("About you"), value: aboutYouValue,
                            identifier: SettingsViewAccessibilityID.aboutYouRow)
                        SettingsRowDivider()
                        row(
                            .halfLifeFactors, title: Text("Caffeine and your body"), value: nil,
                            identifier: SettingsViewAccessibilityID.halfLifeFactorsRow)
                        SettingsRowDivider()
                        row(
                            .bedtime, title: Text("Bedtime"), value: bedtimeValue,
                            identifier: SettingsViewAccessibilityID.bedtimeRow)
                    }
                }
                SettingsCard {
                    VStack(alignment: .leading, spacing: 0) {
                        row(
                            .permissions, title: Text("Permissions"), value: nil,
                            identifier: SettingsViewAccessibilityID.permissionsRow)
                        if showsAppLock {
                            SettingsRowDivider()
                            row(
                                .appLock, title: Text("App lock"), value: appLockValue,
                                identifier: SettingsViewAccessibilityID.appLockRow)
                        }
                        SettingsRowDivider()
                        row(
                            .demoData, title: Text("Demo data"), value: demoValue,
                            identifier: SettingsViewAccessibilityID.demoDataRow)
                    }
                }
                VStack(spacing: 0) {
                    if let appVersion = store.appVersion {
                        // The version and build are identifiers, not quantities, so they're shown as they are.
                        Text("Version \(appVersion.version) (\(appVersion.build))")
                            .font(.footnote)
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier(SettingsViewAccessibilityID.appVersion)
                    }
                    privacyPolicyLink
                }
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.itemGap)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background { OnboardingStepBackground() }
        .navigationTitle(Text("Settings"))
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SettingsViewAccessibilityID.screen)
    }

    /// One row: its title, its value, and a chevron, as one button that opens the row's screen.
    private func row(_ row: SettingsFeature.Row, title: Text, value: Text?, identifier: String) -> some View {
        Button {
            store.send(.rowTapped(row))
        } label: {
            HStack(spacing: Spacing.itemGap) {
                title
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.itemGap)
                if let value {
                    value
                        .font(.body)
                        .foregroundStyle(Color.textAccent)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Spacing.itemGap)
            .frame(maxWidth: .infinity, minHeight: Sizing.minimumHitTarget, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    /// The name, when there is one. It's the user's own text, so it isn't looked up in the String Catalog.
    private var aboutYouValue: Text? {
        store.profile.savedProfile?.name.map { Text(verbatim: $0) }
    }

    private var bedtimeValue: Text? {
        store.profile.savedProfile.map { Text(OnboardingFormat.time($0.bedtime, in: calendar)) }
    }

    private var appLockValue: Text? {
        store.appLock.appLock.map { $0.isEnabled ? Text("On") : Text("Off") }
    }

    private var demoValue: Text? {
        store.demoHistory.hasDemoHistory == true ? Text("Added") : nil
    }

    /// The link to the privacy policy, which iOS opens outside the app. Its text is underlined and followed by an
    /// arrow, so it reads as a link without relying on color (Article VI.3). The arrow is decorative, so VoiceOver
    /// reads only the text, with the link's trait. See the Settings article's "The privacy policy".
    private var privacyPolicyLink: some View {
        Link(destination: PrivacyPolicy.url) {
            HStack(alignment: .firstTextBaseline) {
                Text("Privacy policy")
                    .underline()
                Image(systemName: "arrow.up.right")
                    .accessibilityHidden(true)
            }
            .font(.footnote)
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: Sizing.minimumHitTarget)
            .contentShape(Rectangle())
        }
        .accessibilityHint(Text("Opens the privacy policy on GitHub."))
        .accessibilityIdentifier(SettingsViewAccessibilityID.privacyPolicyLink)
    }

    /// Whether the App lock row shows. Like its screen's section, it's hidden on a device with no Face ID or Touch ID,
    /// unless the lock is already on, so it can always be turned off.
    private var showsAppLock: Bool {
        guard let appLock = store.appLock.appLock, let biometrics = store.appLock.biometrics else { return false }
        if case .unavailable = biometrics {
            return appLock.isEnabled
        }
        return true
    }
}

/// The layout Settings' pushed screens share: a large title on the canvas's solid top color, the screen's content,
/// and the navigation stack's own back button.
///
/// It's laid out like onboarding's steps. The screen's identifier is on its scroll view, which is also what its robot
/// swipes: a container's identifier given to its only child replaced the child's own.
@MainActor
struct SettingsScreen<Content: View>: View {
    /// The screen's title.
    let title: Text
    /// The screen's `screen` accessibility identifier.
    let screenIdentifier: String
    /// The screen's content.
    @ViewBuilder let content: Content

    /// The title and the content, scrolling on the solid page.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                title
                    .font(.titleLarge)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                content
            }
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.vertical, Spacing.itemGap)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background { OnboardingStepBackground() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(screenIdentifier)
    }
}

/// One of Settings' sections: an eyebrow over its content, and an optional note under it.
///
/// The eyebrow and the note sit directly on the solid page, so they use `textPrimary`, as onboarding's do: the
/// accessibility audit failed small `textSecondary` text on the page (see the Onboarding article).
@MainActor
struct SettingsSection<Content: View>: View {
    /// The section's title.
    let title: Text
    /// A note under the section, if it has one.
    var note: Text?
    /// The section's content, usually one or more ``SettingsCard``s.
    @ViewBuilder let content: Content

    /// The eyebrow, the content, and the note.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
            OnboardingEyebrow(text: title)
                .accessibilityAddTraits(.isHeader)
            content
            if let note {
                note
                    .font(.footnote)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A card for Settings' rows: the card surface, rounded, with compact padding.
@MainActor
struct SettingsCard<Content: View>: View {
    /// The card's content.
    @ViewBuilder let content: Content

    /// The content on the card.
    var body: some View {
        content
            .padding(Spacing.cardPaddingCompact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfaceCard, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
    }
}

/// An option that's chosen or not, in the style of onboarding's factor options: a check circle, a title, and a line
/// about it. A chosen option has the selected trait, so VoiceOver doesn't depend on its fill (Article VI.3).
///
/// Settings uses it where iOS would use a switch, because the accessibility audit failed the system switch's rows.
@MainActor
struct SettingsOption: View {
    /// The option's title.
    let title: Text
    /// A line about the option, if it has one.
    let detail: Text?
    /// Whether the option is chosen.
    let isSelected: Bool
    /// The option's accessibility identifier.
    let identifier: String
    /// What tapping the option does.
    let action: () -> Void

    /// The option's row.
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.itemGap) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentOnEmphasis : Color.controlBorder)
                    .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    title
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.textOnEmphasis : Color.textPrimary)
                    // The line is in textPrimary, not onboarding's textSecondary: the accessibility audit failed
                    // textSecondary footnotes on these cards, at about 5.9:1 by the tokens. The owner chose this on
                    // 2026-09-13.
                    if let detail {
                        detail
                            .font(.footnote)
                            .foregroundStyle(isSelected ? Color.textOnEmphasisSecondary : Color.textPrimary)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(Spacing.cardPaddingCompact)
            .frame(maxWidth: .infinity, minHeight: Sizing.minimumHitTarget, alignment: .leading)
            .background(
                isSelected ? Color.surfaceSelected : Color.surfaceCard,
                in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }
}

/// The hairline between two rows on a card. It's decorative, so VoiceOver skips it.
@MainActor
private struct SettingsRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.separatorOnCard)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

#Preview {
    SettingsView(store: Store(initialState: SettingsFeature.State()) { SettingsFeature() })
}
