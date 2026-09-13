//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life BedtimeSettingsView
//

import ComposableArchitecture
import SwiftUI

/// Settings' Bedtime screen: when the user wants to be asleep, on the system's compact time picker, as onboarding's
/// bedtime step has it.
///
/// A new bedtime saves as soon as it's chosen. See the Settings article.
@MainActor
struct BedtimeSettingsView: View {
    /// The screen's store.
    @Bindable var store: StoreOf<ProfileSettingsFeature>

    @Environment(\.calendar) private var calendar

    /// The time picker, and the note under it.
    var body: some View {
        SettingsScreen(title: Text("Bedtime"), screenIdentifier: BedtimeSettingsViewAccessibilityID.screen) {
            VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
                DatePicker(selection: time, displayedComponents: .hourAndMinute) {
                    Text("Bedtime")
                        .foregroundStyle(Color.textPrimary)
                }
                .datePickerStyle(.compact)
                .environment(\.timeZone, calendar.timeZone)
                .accessibilityIdentifier(BedtimeSettingsViewAccessibilityID.picker)
                .padding(Spacing.cardPaddingCompact)
                .background(
                    Color.surfaceCard, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
                Text("When you want to be asleep. Half-Life works out how much caffeine will be left in you then.")
                    .font(.footnote)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .task { await store.send(.task).finish() }
    }

    /// The bedtime, as the date the time picker works with. A new time keeps only its hour and minute.
    private var time: Binding<Date> {
        Binding {
            OnboardingFormat.date(for: store.bedtime, in: calendar)
        } set: { date in
            if let bedtime = OnboardingFormat.bedtime(at: date, in: calendar) {
                store.bedtime = bedtime
            }
        }
    }
}
