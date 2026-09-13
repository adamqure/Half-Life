//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LanguageModelDataSourceTests
//

import Foundation
import FoundationModels
import Testing

@testable import Half_Life

/// Checks the Foundation Models data source against LMSRC-1 to LMSRC-3 in the Language Model article.
///
/// The system model's availability and locale support are replaced, so no test needs Apple Intelligence, and no test
/// asks the model for a response.
struct LanguageModelDataSourceTests {

    /// A data source over fake repositories, with the given system availability and locale support.
    static func dataSource(
        availability: SystemLanguageModel.Availability = .available,
        supportsLocale: @escaping @Sendable (Locale) -> Bool = { _ in true }
    ) throws -> FoundationModelLanguageModelDataSource {
        FoundationModelLanguageModelDataSource(
            caffeineDecay: FakeCaffeineDecayRepository(), drinkLog: FakeDrinkLogRepository(),
            currentTime: FakeCurrentTimeRepository(date: Date(timeIntervalSinceReferenceDate: 0)),
            calendar: try LanguageModelFormatTests.calendar("America/New_York"),
            systemAvailability: { availability }, supportsLocale: supportsLocale)
    }

    static let readOnlyTools = ["getCaffeineStatus", "getCaffeineCutoff", "getCaffeineLevelAt", "getDrinksOnDay"]

    // MARK: - LMSRC-1: available only when the system model is available and supports the locale

    @Test func availableWhenTheSystemModelIsAvailableAndSupportsTheLocale() throws {
        #expect(try Self.dataSource().availability() == .available)
    }

    @Test(arguments: [
        SystemLanguageModel.Availability.UnavailableReason.deviceNotEligible, .appleIntelligenceNotEnabled,
        .modelNotReady,
    ])
    func unavailableForEveryReasonTheSystemModelGives(reason: SystemLanguageModel.Availability.UnavailableReason)
        throws
    {
        #expect(try Self.dataSource(availability: .unavailable(reason)).availability() == .unavailable)
    }

    @Test func unavailableWhenTheSystemModelDoesntSupportTheLocale() throws {
        #expect(try Self.dataSource(supportsLocale: { _ in false }).availability() == .unavailable)
    }

    @Test func asksAboutTheCalendarsLocale() throws {
        let asked = Recorded<[Locale]>([])
        _ = try Self.dataSource(supportsLocale: { locale in
            asked.update { $0.append(locale) }
            return true
        }).availability()

        #expect(asked.value.map(\.identifier) == ["en_US"])
    }

    // MARK: - LMSRC-2: only an App Intent's instruction gets logDrink

    @Test func anAppInstructionGetsOnlyTheReadOnlyTools() throws {
        #expect(try Self.dataSource().tools(for: .app).map(\.name) == Self.readOnlyTools)
    }

    @Test func anAppIntentInstructionAlsoGetsLogDrink() throws {
        #expect(try Self.dataSource().tools(for: .appIntent).map(\.name) == Self.readOnlyTools + ["logDrink"])
    }

    // MARK: - LMSRC-3: the instructions name the language, and only an App Intent's mention logging

    @Test func theInstructionsNameTheUsersLanguage() {
        let french = LanguageModelInstructions.text(for: .app, locale: Locale(identifier: "fr_FR"))
        let english = LanguageModelInstructions.text(for: .app, locale: Locale(identifier: "en_US"))

        #expect(french.contains("Answer in French."))
        #expect(english.contains("Answer in English."))
    }

    @Test func theInstructionsSayToTakeEveryNumberFromATool() {
        let text = LanguageModelInstructions.text(for: .app, locale: Locale(identifier: "en_US"))

        #expect(text.contains("Get every number, time, and drink from a tool."))
    }

    @Test func onlyAnAppIntentsInstructionsMentionLoggingADrink() {
        let app = LanguageModelInstructions.text(for: .app, locale: Locale(identifier: "en_US"))
        let appIntent = LanguageModelInstructions.text(for: .appIntent, locale: Locale(identifier: "en_US"))

        #expect(!app.contains("Log a drink"))
        #expect(appIntent.contains("Log a drink only when the user says they drank it."))
    }

    // MARK: - LMSRC-8: a failure is logged with the kind of error it was

    struct OtherError: Error {}

    static let context = LanguageModelSession.GenerationError.Context(debugDescription: "")

    /// Every error the model can generate, with the kind the log names it by.
    static let generationErrors: [(LanguageModelSession.GenerationError, String)] = [
        (.exceededContextWindowSize(context), "exceededContextWindowSize"),
        (.assetsUnavailable(context), "assetsUnavailable"),
        (.guardrailViolation(context), "guardrailViolation"),
        (.unsupportedGuide(context), "unsupportedGuide"),
        (.unsupportedLanguageOrLocale(context), "unsupportedLanguageOrLocale"),
        (.decodingFailure(context), "decodingFailure"),
        (.rateLimited(context), "rateLimited"),
        (.concurrentRequests(context), "concurrentRequests"),
        (.refusal(.init(transcriptEntries: []), context), "refusal"),
    ]

    @Test(arguments: generationErrors)
    func aGenerationErrorIsNamedByItsCase(error: LanguageModelSession.GenerationError, kind: String) {
        #expect(FoundationModelLanguageModelDataSource.failureKind(of: error) == kind)
    }

    @Test func aToolsErrorIsNamedAsOne() throws {
        let tool = CaffeineStatusTool(
            caffeineDecay: FakeCaffeineDecayRepository(),
            format: LanguageModelFormat(calendar: try LanguageModelFormatTests.calendar("America/New_York")))
        let error = LanguageModelSession.ToolCallError(tool: tool, underlyingError: OtherError())

        #expect(FoundationModelLanguageModelDataSource.failureKind(of: error) == "toolCallError")
    }

    @Test func anyOtherErrorIsNamedOther() {
        #expect(FoundationModelLanguageModelDataSource.failureKind(of: OtherError()) == "other")
    }
}
