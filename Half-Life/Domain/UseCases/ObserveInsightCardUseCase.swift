//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveInsightCardUseCase
//

import Foundation

/// Streams what the Insights tab's first card shows, or `nil` while it's hidden.
///
/// It combines three repositories' streams: the Sleep screen's analysis, from ``SleepToleranceRepository``, the "Feel
/// right?" answers, from ``InsightFeedbackRepository``, and the language model's availability, from
/// ``LanguageModelRepository``. Once all three have sent a value, it executes ``SleepPatternRule`` and
/// ``InsightFeedbackRule`` on the latest of each, and sends the card whenever it changes. The card is hidden while the
/// model is unavailable, with too few nights, and after a "Not really" at the finding's confidence.
///
/// The owner chose on 2026-09-13 to combine them here, so it's one of the use cases that execute a business rule, each
/// an exception the owner approved (the Architecture article). It holds no state between calls. See CARD-1 to CARD-6
/// in the Insights article.
struct ObserveInsightCardUseCase: UseCase {
    /// The repository that owns the Sleep screen's analysis.
    let sleepTolerance: any SleepToleranceRepository
    /// The repository that stores the "Feel right?" answers.
    let insightFeedback: any InsightFeedbackRepository
    /// The repository that owns the language model's availability.
    let languageModel: any LanguageModelRepository

    /// A value from one of the three streams.
    private enum Update: Sendable {
        case analysis(SleepCaffeineAnalysis)
        case answers([InsightFeedback])
        case availability(LanguageModelAvailability)
    }

    /// Returns a stream of the card: the first once all three repositories have sent a value, then each change. It
    /// finishes when all three repositories' streams have.
    ///
    /// - Parameter input: None.
    func execute(_ input: Void) -> AsyncStream<InsightCard?> {
        let updates = Self.merge(sleepTolerance.analysis(), insightFeedback.feedback(), languageModel.availability())
        return AsyncStream { continuation in
            let task = Task {
                var analysis: SleepCaffeineAnalysis?
                var answers: [InsightFeedback]?
                var availability: LanguageModelAvailability?
                var lastSent: InsightCard??
                for await update in updates {
                    switch update {
                    case let .analysis(value): analysis = value
                    case let .answers(value): answers = value
                    case let .availability(value): availability = value
                    }
                    guard let analysis, let answers, let availability else { continue }
                    let card = Self.card(from: analysis, answers: answers, availability: availability)
                    if let lastSent, lastSent == card { continue }
                    lastSent = .some(card)
                    continuation.yield(card)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The card for the latest values, or `nil` while it's hidden.
    private static func card(
        from analysis: SleepCaffeineAnalysis, answers: [InsightFeedback], availability: LanguageModelAvailability
    ) -> InsightCard? {
        guard availability == .available else { return nil }
        let pattern = SleepPatternRule().pattern(from: analysis)
        guard pattern.confidence != .tooFew else { return nil }
        let status = InsightFeedbackRule().status(for: pattern.confidence, answers: answers)
        guard !status.isDismissed else { return nil }
        return InsightCard(
            pattern: pattern, asksForFeedback: status.asksForFeedback, disagreement: status.lastDisagreement,
            isDemo: analysis.isDemo)
    }

    /// One stream of the three streams' values, in the order they arrive. It finishes when all three have.
    private static func merge(
        _ analyses: AsyncStream<SleepCaffeineAnalysis>, _ answers: AsyncStream<[InsightFeedback]>,
        _ availabilities: AsyncStream<LanguageModelAvailability>
    ) -> AsyncStream<Update> {
        AsyncStream { continuation in
            let task = Task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        for await value in analyses {
                            continuation.yield(.analysis(value))
                        }
                    }
                    group.addTask {
                        for await value in answers {
                            continuation.yield(.answers(value))
                        }
                    }
                    group.addTask {
                        for await value in availabilities {
                            continuation.yield(.availability(value))
                        }
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
