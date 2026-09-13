//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FoundationModelLanguageModelDataSource
//

import Foundation
import FoundationModels
import OSLog

/// The live language model data source: Apple's on-device model, through the Foundation Models framework.
///
/// Each instruction gets a new `LanguageModelSession`, with new tools and the standing instructions, and the session
/// is discarded with its response. The tools read the app-scoped repositories, so the model's numbers are the ones on
/// screen. An insight gets a session with no tools, whose prompt gives the facts. The system model's availability and
/// locale support are injected, so tests don't need Apple Intelligence. The Language Model article lists its
/// requirements, LMSRC-1 to LMSRC-8.
struct FoundationModelLanguageModelDataSource: LanguageModelDataSource {
    private static let logger = Logger(for: FoundationModelLanguageModelDataSource.self)

    /// The options for an insight's answer: at most 150 tokens (LMSRC-7).
    ///
    /// The longest valid answer measured was 74 tokens, in French, so the cap leaves room for twice that. A runaway
    /// answer fails at the cap, instead of filling the model's 4,096-token context window.
    static let insightOptions = GenerationOptions(maximumResponseTokens: 150)

    /// The repository the caffeine tools read.
    let caffeineDecay: any CaffeineDecayRepository
    /// The repository the drink tools read, and `logDrink` writes to.
    let drinkLog: any DrinkLogRepository
    /// The repository that gives the tools the current time.
    let currentTime: any CurrentTimeRepository
    /// The calendar the tools read and format in. Its locale is the user's language.
    let calendar: Calendar
    /// Reads the system model's availability.
    let systemAvailability: @Sendable () -> SystemLanguageModel.Availability
    /// Whether the system model supports a locale.
    let supportsLocale: @Sendable (Locale) -> Bool

    /// Creates the data source.
    ///
    /// - Parameters:
    ///   - caffeineDecay: The repository the caffeine tools read.
    ///   - drinkLog: The repository the drink tools read, and `logDrink` writes to.
    ///   - currentTime: The repository that gives the tools the current time.
    ///   - calendar: The calendar the tools read and format in. Defaults to the user's current calendar.
    ///   - systemAvailability: Reads the system model's availability. Defaults to the default model's.
    ///   - supportsLocale: Whether the system model supports a locale. Defaults to asking the default model.
    init(
        caffeineDecay: any CaffeineDecayRepository,
        drinkLog: any DrinkLogRepository,
        currentTime: any CurrentTimeRepository,
        calendar: Calendar = .autoupdatingCurrent,
        systemAvailability: @escaping @Sendable () -> SystemLanguageModel.Availability = {
            SystemLanguageModel.default.availability
        },
        supportsLocale: @escaping @Sendable (Locale) -> Bool = { SystemLanguageModel.default.supportsLocale($0) }
    ) {
        self.caffeineDecay = caffeineDecay
        self.drinkLog = drinkLog
        self.currentTime = currentTime
        self.calendar = calendar
        self.systemAvailability = systemAvailability
        self.supportsLocale = supportsLocale
    }

    private var locale: Locale {
        calendar.locale ?? .autoupdatingCurrent
    }

    /// Reads whether the model can be used now: only when the system model is available and supports the calendar's
    /// locale (LMSRC-1).
    func availability() -> LanguageModelAvailability {
        guard case .available = systemAvailability(), supportsLocale(locale) else {
            return .unavailable
        }
        return .available
    }

    /// Builds new tools for one instruction: the read-only tools, plus `logDrink` for an App Intent's instruction
    /// (LMSRC-2).
    ///
    /// - Parameter origin: Where the instruction came from.
    func tools(for origin: LanguageModelInstruction.Origin) -> [any Tool] {
        let format = LanguageModelFormat(calendar: calendar)
        var tools: [any Tool] = [
            CaffeineStatusTool(caffeineDecay: caffeineDecay, format: format),
            CaffeineCutoffTool(caffeineDecay: caffeineDecay, format: format),
            CaffeineLevelTool(caffeineDecay: caffeineDecay, currentTime: currentTime, format: format),
            DrinksOnDayTool(drinkLog: drinkLog, currentTime: currentTime, format: format),
        ]
        if origin == .appIntent {
            tools.append(
                LogDrinkTool(
                    logDrink: LogDrinkUseCase(currentTime: currentTime, drinkLog: drinkLog), currentTime: currentTime,
                    format: format))
        }
        return tools
    }

    /// The facts an insight's prompt gives the model: the request's finding, with every number formatted (LMSRC-6).
    ///
    /// - Parameter request: The finding to put into words, and the one the user last disagreed with.
    func insightFacts(for request: InsightRequest) -> String {
        InsightFacts(pattern: request.pattern, format: LanguageModelFormat(calendar: calendar)).text
    }

    /// A new session for the Insights tab's first finding: the insight's instructions, and no tools, so the model has
    /// nothing to call again and again (LMSRC-6).
    func insightSession() -> LanguageModelSession {
        LanguageModelSession(instructions: LanguageModelInstructions.insightText(locale: locale))
    }

    /// Answers one instruction in a new session, with new tools and the standing instructions, then discards the
    /// session.
    ///
    /// Nothing the model reads or writes is logged (constitution Article XI.6). A failure is logged with its error's
    /// kind, domain, and code only (LMSRC-8).
    func respond(to instruction: LanguageModelInstruction) async throws -> String {
        let session = LanguageModelSession(
            tools: tools(for: instruction.origin),
            instructions: LanguageModelInstructions.text(for: instruction.origin, locale: locale))
        do {
            return try await session.respond(to: instruction.prompt).content
        } catch {
            let kind = Self.failureKind(of: error)
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                """
                Couldn't respond to an instruction: \(kind, privacy: .public) \(domain, privacy: .public) \
                \(code, privacy: .public)
                """)
            throw error
        }
    }

    /// Writes the Insights tab's first finding in a new session with no tools, from a prompt that gives the facts,
    /// through guided generation capped at 150 tokens, then discards the session.
    ///
    /// Nothing the model reads or writes is logged (constitution Article XI.6). A failure is logged with its error's
    /// kind, domain, and code only (LMSRC-8).
    func writeInsight(_ request: InsightRequest) async throws -> WrittenInsight {
        let facts = insightFacts(for: request)
        let session = insightSession()
        do {
            let answer = try await session.respond(
                to: LanguageModelInstructions.insightPrompt(facts: facts, disagreement: request.disagreement),
                generating: GeneratedInsight.self, options: Self.insightOptions)
            return WrittenInsight(insight: answer.content.insight, facts: facts)
        } catch {
            let kind = Self.failureKind(of: error)
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                """
                Couldn't write an insight: \(kind, privacy: .public) \(domain, privacy: .public) \
                \(code, privacy: .public)
                """)
            throw error
        }
    }

    /// The kind of error a session failed with, for the log: the name of the framework's `GenerationError` case,
    /// `toolCallError` when a tool threw, or `other` (LMSRC-8).
    ///
    /// It names the kind only. The error's description and context can hold the prompt, so they're never logged
    /// (constitution Article XI.6).
    ///
    /// - Parameter error: The error the session threw.
    static func failureKind(of error: any Error) -> String {
        switch error {
        case let error as LanguageModelSession.GenerationError: generationErrorKind(error)
        case is LanguageModelSession.ToolCallError: "toolCallError"
        default: "other"
        }
    }

    private static func generationErrorKind(_ error: LanguageModelSession.GenerationError) -> String {
        switch error {
        case .exceededContextWindowSize: "exceededContextWindowSize"
        case .assetsUnavailable: "assetsUnavailable"
        case .guardrailViolation: "guardrailViolation"
        case .unsupportedGuide: "unsupportedGuide"
        case .unsupportedLanguageOrLocale: "unsupportedLanguageOrLocale"
        case .decodingFailure: "decodingFailure"
        case .rateLimited: "rateLimited"
        case .concurrentRequests: "concurrentRequests"
        case .refusal: "refusal"
        @unknown default: "unknownGenerationError"
        }
    }
}
