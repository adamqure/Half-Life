//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life GetCaffeineIntakeIntent
//

import AppIntents
import ComposableArchitecture
import Foundation

/// Tells the user what they drank on a day, and the day's total caffeine: today, unless they name another day.
///
/// It reads the current time from ``ObserveTimeOfDayUseCase``, because only the clock data source reads the clock, and
/// answers from the first day ``ObserveDrinkLogDayUseCase`` publishes. Demo drinks are marked as demo data. See
/// INTENT-QUERY-3 in the App Intents article.
struct GetCaffeineIntakeIntent: AppIntent {
    /// The intent's name in Shortcuts.
    static let title: LocalizedStringResource = "Get Caffeine Intake"
    /// What the intent does, for Shortcuts and Apple Intelligence.
    static let description: IntentDescription? = IntentDescription(
        "Tells you what you drank on a day, and how much caffeine it came to.")
    /// It answers in the background.
    static let supportedModes: IntentModes = .background
    /// It runs only on an unlocked phone, because its answer is health data.
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    /// The day to answer for. Without one, it's today.
    @Parameter(title: "Day") var day: Date?

    // App Intents' `Dependency` typealias shadows swift-dependencies' inside an intent, so the module is named.
    @Dependencies.Dependency(\.calendar) private var calendar
    @Dependencies.Dependency(\.observeTimeOfDay) private var observeTimeOfDay
    @Dependencies.Dependency(\.observeDrinkLogDay) private var observeDrinkLogDay

    /// Answers with the day's drinks and total.
    ///
    /// - Returns: The day, as a dialog and a value.
    /// - Throws: ``IntentFailure/unavailable`` when the current time or the day isn't published.
    func perform() async throws -> some IntentResult & ReturnsValue<CaffeineIntakeEntity> & ProvidesDialog {
        guard let now = await observeTimeOfDay.execute(calendar).firstValue()?.date else {
            throw IntentFailure.unavailable
        }
        let input = ObserveDrinkLogDayUseCase.Input(date: day ?? now, calendar: calendar)
        guard let logDay = await observeDrinkLogDay.execute(input).firstValue() else {
            throw IntentFailure.unavailable
        }
        let dialog = IntentDialogFormat(calendar: calendar).day(logDay, today: now)
        return .result(value: CaffeineIntakeEntity(logDay), dialog: IntentDialog(dialog))
    }
}
