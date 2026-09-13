//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeLanguageModelRepository
//

import Foundation

@testable import Half_Life

/// An in-memory language model repository for use case tests.
///
/// It streams the availabilities it was given, then finishes, answers every instruction with `response`, and every
/// insight request with `insight`, recording each one. It's an actor, like the live repositories.
actor FakeLanguageModelRepository: LanguageModelRepository {
    /// The availabilities that `availability()` streams, in order.
    let availabilities: [LanguageModelAvailability]
    /// Answers an instruction, or throws.
    let response: @Sendable (LanguageModelInstruction) throws -> String
    /// Writes an insight, or throws.
    let insight: @Sendable (InsightRequest) throws -> Insight
    /// Every instruction answered so far, in order.
    private(set) var instructions: [LanguageModelInstruction] = []
    /// Every insight request so far, in order.
    private(set) var insightRequests: [InsightRequest] = []

    init(
        availabilities: [LanguageModelAvailability] = [],
        response: @escaping @Sendable (LanguageModelInstruction) throws -> String = { _ in "" },
        insight: @escaping @Sendable (InsightRequest) throws -> Insight = { _ in Insight(headline: "", sentence: "") }
    ) {
        self.availabilities = availabilities
        self.response = response
        self.insight = insight
    }

    nonisolated func availability() -> AsyncStream<LanguageModelAvailability> {
        AsyncStream { continuation in
            for availability in availabilities {
                continuation.yield(availability)
            }
            continuation.finish()
        }
    }

    func respond(to instruction: LanguageModelInstruction) async throws -> String {
        instructions.append(instruction)
        return try response(instruction)
    }

    func writeInsight(_ request: InsightRequest) async throws -> Insight {
        insightRequests.append(request)
        return try insight(request)
    }
}

extension InsightRequest {
    /// A request for an early sign over 30 days, with no disagreement, for tests that only pass one along.
    static let example = InsightRequest(
        pattern: SleepPattern(
            period: DateInterval(start: Date(timeIntervalSinceReferenceDate: 0), duration: 30 * 24 * 3_600), days: 30,
            nightsOver: 6, nightsUnder: 17, threshold: .standard, direction: .shorter, confidence: .earlySign),
        disagreement: nil)
}
