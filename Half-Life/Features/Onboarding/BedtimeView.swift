//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life BedtimeView
//

import ComposableArchitecture
import SwiftUI

/// Onboarding's bedtime step: the system's time picker, for any time of day.
///
/// The owner chose a picker over the prototype's chips on 2026-09-12, so a shift worker's bedtime fits too, and the
/// system's compact time picker over the app's own wheels on 2026-09-13. See the Onboarding article.
@MainActor
struct BedtimeView: View {
    /// The step's store.
    let store: StoreOf<BedtimeFeature>

    @Environment(\.calendar) private var calendar

    /// Tells the step the user tapped Continue.
    private func continueTapped() {
        store.send(.continueTapped)
    }

    /// The step's content.
    var body: some View {
        OnboardingStepLayout(
            step: 3, title: Text("When do you want to be asleep?"),
            lead: Text("Half-Life shows how much caffeine will still be in you by then."),
            screenIdentifier: BedtimeViewAccessibilityID.screen, contentIdentifier: BedtimeViewAccessibilityID.content,
            buttonTitle: Text("Continue"),
            buttonIdentifier: BedtimeViewAccessibilityID.continueButton, isButtonDisabled: store.isSaving,
            action: continueTapped
        ) {
            DatePicker(selection: time, displayedComponents: .hourAndMinute) {
                Text("Bedtime")
                    .foregroundStyle(Color.textPrimary)
            }
            .datePickerStyle(.compact)
            .environment(\.timeZone, calendar.timeZone)
            .accessibilityIdentifier(BedtimeViewAccessibilityID.picker)
            .padding(Spacing.cardPaddingCompact)
            .background(Color.surfaceCard, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        }
        .task { await store.send(.task).finish() }
    }

    /// The bedtime, as the date the time picker works with. A new time keeps only its hour and minute.
    private var time: Binding<Date> {
        Binding {
            OnboardingFormat.date(for: store.bedtime, in: calendar)
        } set: { date in
            if let bedtime = OnboardingFormat.bedtime(at: date, in: calendar) {
                store.send(.bedtimeChanged(bedtime))
            }
        }
    }
}
