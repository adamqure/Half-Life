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

/// Onboarding's bedtime step: one time picker for any time of day.
///
/// The owner chose a picker over the prototype's chips on 2026-09-12, so a shift worker's bedtime fits too. See the
/// Onboarding article.
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
            HStack(spacing: 0) {
                Picker(selection: hour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(OnboardingFormat.hour(hour, in: calendar)).tag(hour)
                    }
                } label: {
                    Text("Hour")
                }
                .pickerStyle(.wheel)
                .accessibilityIdentifier(BedtimeViewAccessibilityID.hourPicker)
                Picker(selection: minute) {
                    ForEach(0..<60, id: \.self) { minute in
                        Text(OnboardingFormat.minute(minute)).tag(minute)
                    }
                } label: {
                    Text("Minute")
                }
                .pickerStyle(.wheel)
                .accessibilityIdentifier(BedtimeViewAccessibilityID.minutePicker)
            }
            .frame(maxWidth: .infinity)
            .background(Color.surfaceCard, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(BedtimeViewAccessibilityID.picker)
        }
        .task { await store.send(.task).finish() }
    }

    /// The bedtime's hour, on its own wheel. Changing it keeps the minute.
    private var hour: Binding<Int> {
        Binding {
            store.bedtime.hour
        } set: { hour in
            if let bedtime = Bedtime(hour: hour, minute: store.bedtime.minute) {
                store.send(.bedtimeChanged(bedtime))
            }
        }
    }

    /// The bedtime's minute, on its own wheel. Changing it keeps the hour.
    private var minute: Binding<Int> {
        Binding {
            store.bedtime.minute
        } set: { minute in
            if let bedtime = Bedtime(hour: store.bedtime.hour, minute: minute) {
                store.send(.bedtimeChanged(bedtime))
            }
        }
    }
}
