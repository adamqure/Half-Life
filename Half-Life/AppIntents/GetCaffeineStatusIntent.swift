//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life GetCaffeineStatusIntent
//

import AppIntents
import ComposableArchitecture

/// Tells the user how much caffeine is in their system now, and how much will be left at bedtime.
///
/// It answers from the first status ``ObserveCaffeineStatusUseCase`` publishes, in the decay card's words, and returns
/// the status as a value. See INTENT-QUERY-1 in the App Intents article.
struct GetCaffeineStatusIntent: AppIntent {
    /// The intent's name in Shortcuts.
    static let title: LocalizedStringResource = "Get Caffeine Level"
    /// What the intent does, for Shortcuts and Apple Intelligence.
    static let description: IntentDescription? = IntentDescription(
        "Tells you how much caffeine is in your system now, and how much will be left at bedtime.")
    /// It answers in the background.
    static let supportedModes: IntentModes = .background
    /// It runs only on an unlocked phone, because its answer is health data.
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    // App Intents' `Dependency` typealias shadows swift-dependencies' inside an intent, so the module is named.
    @Dependencies.Dependency(\.calendar) private var calendar
    @Dependencies.Dependency(\.observeCaffeineStatus) private var observeCaffeineStatus

    /// Answers with the current status.
    ///
    /// - Returns: The status, as a dialog and a value.
    /// - Throws: ``IntentFailure/unavailable`` when no status is published.
    func perform() async throws -> some IntentResult & ReturnsValue<CaffeineStatusEntity> & ProvidesDialog {
        guard let status = await observeCaffeineStatus.execute(calendar).firstValue() else {
            throw IntentFailure.unavailable
        }
        let dialog = IntentDialogFormat(calendar: calendar).status(status)
        return .result(value: CaffeineStatusEntity(status), dialog: IntentDialog(dialog))
    }
}
