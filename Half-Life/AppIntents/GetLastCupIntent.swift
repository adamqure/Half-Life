//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life GetLastCupIntent
//

import AppIntents
import ComposableArchitecture

/// Tells the user the latest time to have their usual drink and still be at or under the sleep threshold at bedtime.
///
/// It answers from the first cutoff ``ObserveCaffeineCutoffUseCase`` publishes, the "Last cup" tile's figure, and
/// returns the cutoff as a value. See INTENT-QUERY-2 in the App Intents article.
struct GetLastCupIntent: AppIntent {
    /// The intent's name in Shortcuts.
    static let title: LocalizedStringResource = "Get Last Cup"
    /// What the intent does, for Shortcuts and Apple Intelligence.
    static let description: IntentDescription? = IntentDescription(
        "Tells you the latest time to have your usual drink and still sleep well tonight.")
    /// It answers in the background.
    static let supportedModes: IntentModes = .background
    /// It runs only on an unlocked phone, because its answer is health data.
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    // App Intents' `Dependency` typealias shadows swift-dependencies' inside an intent, so the module is named.
    @Dependencies.Dependency(\.calendar) private var calendar
    @Dependencies.Dependency(\.observeCaffeineCutoff) private var observeCaffeineCutoff

    /// Answers with the current cutoff.
    ///
    /// - Returns: The cutoff, as a dialog and a value.
    /// - Throws: ``IntentFailure/unavailable`` when no cutoff is published.
    func perform() async throws -> some IntentResult & ReturnsValue<CaffeineCutoffEntity> & ProvidesDialog {
        guard let cutoff = await observeCaffeineCutoff.execute(calendar).firstValue() else {
            throw IntentFailure.unavailable
        }
        let dialog = IntentDialogFormat(calendar: calendar).cutoff(cutoff)
        return .result(value: CaffeineCutoffEntity(cutoff), dialog: IntentDialog(dialog))
    }
}
