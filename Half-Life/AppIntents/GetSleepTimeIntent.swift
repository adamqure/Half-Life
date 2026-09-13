//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life GetSleepTimeIntent
//

import AppIntents
import ComposableArchitecture
import SwiftUI

/// Tells the user when to go to sleep tonight: the brief's "when the optimal time to sleep would be".
///
/// It answers from the first window ``ObserveSleepWindowUseCase`` publishes, in the Insights card's words, and shows
/// the card's decay chart in a snippet. It's the only intent with a snippet. See INTENT-QUERY-4 in the App Intents
/// article.
struct GetSleepTimeIntent: AppIntent {
    /// The intent's name in Shortcuts.
    static let title: LocalizedStringResource = "Get Sleep Time"
    /// What the intent does, for Shortcuts and Apple Intelligence.
    static let description: IntentDescription? = IntentDescription(
        "Tells you the best time to fall asleep tonight, once your caffeine is low enough.")
    /// It answers in the background.
    static let supportedModes: IntentModes = .background
    /// It runs only on an unlocked phone, because its answer is health data.
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    // App Intents' `Dependency` typealias shadows swift-dependencies' inside an intent, so the module is named.
    @Dependencies.Dependency(\.calendar) private var calendar
    @Dependencies.Dependency(\.observeSleepWindow) private var observeSleepWindow

    /// Answers with tonight's window, and the decay chart.
    ///
    /// - Returns: The window, as a dialog, a value, and a snippet.
    /// - Throws: ``IntentFailure/unavailable`` when no window is published.
    func perform() async throws
        -> some IntentResult & ReturnsValue<SleepTimeEntity> & ProvidesDialog & ShowsSnippetView
    {
        guard let window = await observeSleepWindow.execute(calendar).firstValue() else {
            throw IntentFailure.unavailable
        }
        let dialog = IntentDialogFormat(calendar: calendar).sleepWindow(window)
        return .result(
            value: SleepTimeEntity(window), dialog: IntentDialog(dialog), view: SleepTimeSnippetView(window: window))
    }
}
