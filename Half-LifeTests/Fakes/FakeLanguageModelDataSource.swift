//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeLanguageModelDataSource
//

@testable import Half_Life

/// A language model data source for repository tests, with no model behind it.
///
/// Each read of the availability returns the next of the given values, and keeps returning the last one. Every
/// instruction is recorded and answered with `response`, and every insight request is recorded and answered with
/// `insight`.
final class FakeLanguageModelDataSource: LanguageModelDataSource {
    /// The availabilities still to return, in order.
    private let remaining: Recorded<[LanguageModelAvailability]>
    /// Answers an instruction, or throws.
    private let response: @Sendable (LanguageModelInstruction) throws -> String
    /// Writes an insight and the facts it came from, or throws.
    private let insight: @Sendable (InsightRequest) throws -> WrittenInsight
    /// Every instruction passed to `respond(to:)`, in order.
    let received = Recorded<[LanguageModelInstruction]>([])
    /// Every request passed to `writeInsight(_:)`, in order.
    let insightRequests = Recorded<[InsightRequest]>([])

    init(
        availabilities: [LanguageModelAvailability],
        response: @escaping @Sendable (LanguageModelInstruction) throws -> String = { _ in "" },
        insight: @escaping @Sendable (InsightRequest) throws -> WrittenInsight = { _ in
            WrittenInsight(insight: Insight(headline: "", sentence: ""), facts: "")
        }
    ) {
        remaining = Recorded(availabilities)
        self.response = response
        self.insight = insight
    }

    func availability() -> LanguageModelAvailability {
        var next = LanguageModelAvailability.unavailable
        remaining.update { values in
            next = values.first ?? .unavailable
            if values.count > 1 {
                values.removeFirst()
            }
        }
        return next
    }

    func respond(to instruction: LanguageModelInstruction) async throws -> String {
        received.update { $0.append(instruction) }
        return try response(instruction)
    }

    func writeInsight(_ request: InsightRequest) async throws -> WrittenInsight {
        insightRequests.update { $0.append(request) }
        return try insight(request)
    }
}
