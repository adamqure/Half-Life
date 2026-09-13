//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AskHalfLifeIntent
//

import AppIntents
import ComposableArchitecture
import Foundation
import OSLog

/// Answers a question about the user's caffeine, in their own words, with the on-device model: Half-Life's answer to
/// the brief's "text the app".
///
/// The question goes to ``RespondToInstructionUseCase`` as an App Intent instruction, so the model's session can read
/// the user's figures, and log a drink the user says they had (see the Language Model article). When Apple
/// Intelligence is unavailable, it asks to open the app instead. See INTENT-ASK-1 to INTENT-ASK-3 in the App Intents
/// article.
struct AskHalfLifeIntent: AppIntent {
    /// The intent's name in Shortcuts.
    static let title: LocalizedStringResource = "Ask Half-Life"
    /// What the intent does, for Shortcuts and Apple Intelligence.
    static let description: IntentDescription? = IntentDescription(
        "Answers a question about your caffeine, using Apple Intelligence on your iPhone.")
    /// It answers in the background, and can bring the app forward when Apple Intelligence is unavailable.
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]
    /// It runs only on an unlocked phone, because its answers are health data.
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    /// The user's question, in their own words. Siri asks for it.
    @Parameter(title: "Question", requestValueDialog: IntentDialog("What would you like to know?"))
    var question: String

    // App Intents' `Dependency` typealias shadows swift-dependencies' inside an intent, so the module is named.
    @Dependencies.Dependency(\.calendar) private var calendar
    @Dependencies.Dependency(\.respondToInstruction) private var respondToInstruction

    private static let logger = Logger(for: AskHalfLifeIntent.self)

    /// Answers the question, or offers to open the app when Apple Intelligence is unavailable.
    ///
    /// - Returns: The answer, as a dialog.
    /// - Throws: ``IntentFailure/couldntAnswer`` when the model fails, or the system's error when the user doesn't
    ///   open the app.
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let answer = try await Self.answer(
            question, respondToInstruction: respondToInstruction, format: IntentDialogFormat(calendar: calendar)
        ) { dialog in
            try await continueInForeground(dialog, alwaysConfirm: true)
        }
        return .result(dialog: IntentDialog(answer))
    }

    /// Asks the model, and falls back to opening the app when it's unavailable.
    ///
    /// It's separate from ``perform()`` so tests can stand in for opening the app.
    ///
    /// - Parameters:
    ///   - question: The user's question.
    ///   - respondToInstruction: The use case that asks the model.
    ///   - format: The format for the fallback's words.
    ///   - openApp: Asks the user to open the app, with a prompt.
    /// - Returns: The model's answer, or what to say as the app opens.
    /// - Throws: ``IntentFailure/couldntAnswer`` when the model fails for another reason, or `openApp`'s error.
    static func answer(
        _ question: String, respondToInstruction: RespondToInstructionUseCase, format: IntentDialogFormat,
        openApp: (IntentDialog) async throws -> Void
    ) async throws -> LocalizedStringResource {
        do {
            let response = try await respondToInstruction.execute(
                LanguageModelInstruction(prompt: question, origin: .appIntent))
            // The model already answers in the user's language, so its words are shown as they are.
            return LocalizedStringResource(String.LocalizationValue(response))
        } catch LanguageModelError.unavailable {
            try await openApp(IntentDialog(format.needsApp))
            return format.openingApp
        } catch {
            let error = error as NSError
            logger.error(
                """
                Couldn't answer a question: \(error.domain, privacy: .public) \(error.code, privacy: .public) \
                \(error.localizedDescription, privacy: .private)
                """)
            throw IntentFailure.couldntAnswer
        }
    }
}
