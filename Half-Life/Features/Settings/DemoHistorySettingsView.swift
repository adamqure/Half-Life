//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DemoHistorySettingsView
//

import ComposableArchitecture
import SwiftUI

/// Settings' Demo data screen: a card that says what the demo drinks are, with a button that adds 30 days of them, or
/// removes them once they're there, and an option that shows demo Health data in place of Apple Health's.
///
/// Which button shows, and whether the option is chosen, follow the repository's answers, and the button is disabled
/// while a change is under way. The text says what each demo is and where it goes, so what's seeded is clear (the
/// brief's "Say clearly what's seeded vs. live"). See the Settings and Apple Health Card articles.
@MainActor
struct DemoHistorySettingsView: View {
    /// The screen's store.
    let store: StoreOf<DemoDataFeature>

    private var history: StoreOf<DemoHistoryFeature> {
        store.scope(state: \.history, action: \.history)
    }

    private var health: StoreOf<DemoHealthDataFeature> {
        store.scope(state: \.health, action: \.health)
    }

    /// The demo drinks' card, the demo Health data option, and a message under either when its last change failed.
    var body: some View {
        SettingsScreen(title: Text("Demo data"), screenIdentifier: DemoHistorySettingsViewAccessibilityID.screen) {
            VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                SettingsCard {
                    VStack(alignment: .leading, spacing: Spacing.itemGap) {
                        Text(
                            """
                            Adds 30 days of sample drinks, up to now, so your history and caffeine curve have \
                            something to show. Each one is labeled Demo in your history. Removing them keeps the \
                            drinks you logged.
                            """
                        )
                        .font(.footnote)
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        button
                        if history.changeFailed {
                            failure(
                                Text("The demo drinks couldn't be changed. Try again."),
                                identifier: DemoHistorySettingsViewAccessibilityID.demoError)
                        }
                    }
                }
                healthOption
            }
        }
        .task { await store.send(.history(.task)).finish() }
        .task { await store.send(.health(.task)).finish() }
    }

    @ViewBuilder
    private var button: some View {
        switch history.hasDemoHistory {
        case true?:
            Button {
                history.send(.removeTapped)
            } label: {
                Text("Remove demo drinks")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.itemGap)
                    .frame(maxWidth: .infinity, minHeight: Sizing.buttonHeight)
                    .background(
                        Color.surfaceControl,
                        in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                            .strokeBorder(Color.controlBorder)
                    )
            }
            .buttonStyle(.plain)
            .disabled(history.isChanging)
            .accessibilityHint(Text("Deletes the demo drinks, and keeps the drinks you logged."))
            .accessibilityIdentifier(DemoHistorySettingsViewAccessibilityID.removeDemoButton)
        case false?:
            OnboardingPrimaryButton(
                title: Text("Add 30 days of demo drinks"),
                identifier: DemoHistorySettingsViewAccessibilityID.addDemoButton, isDisabled: history.isChanging
            ) {
                history.send(.addTapped)
            }
        case nil:
            EmptyView()
        }
    }

    /// The option that shows demo Health data on the Today screen, chosen while the switch is on. Another tap while a
    /// change is under way does nothing.
    private var healthOption: some View {
        VStack(alignment: .leading, spacing: Spacing.itemGap) {
            SettingsOption(
                title: Text("Use demo Health data"),
                detail: Text(
                    """
                    Shows made-up sleep, steps, and resting heart rate on the Today screen in place of Apple \
                    Health's. Nothing is written to Health.
                    """
                ),
                isSelected: health.usesDemoData == true,
                identifier: DemoHistorySettingsViewAccessibilityID.demoHealthDataOption
            ) {
                health.send(.toggled(health.usesDemoData != true))
            }
            if health.changeFailed {
                failure(
                    Text("The demo Health data couldn't be changed. Try again."),
                    identifier: DemoHistorySettingsViewAccessibilityID.demoHealthDataError)
            }
        }
    }

    private func failure(_ message: Text, identifier: String) -> some View {
        Label {
            message
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
        .accessibilityIdentifier(identifier)
    }
}
