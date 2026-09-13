//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveInsightCardUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks ``ObserveInsightCardUseCase`` against CARD-1 to CARD-6 in the Insights article, with fake repositories.
///
/// Each fake sends its values, then finishes, so a test collects every card the use case sends. The fakes' streams
/// arrive in no fixed order, so a test that sends more than one value checks only what doesn't depend on the order.
struct ObserveInsightCardUseCaseTests {

    static let period = DateInterval(start: Date(timeIntervalSinceReferenceDate: 0), duration: 30 * 24 * 3_600)

    /// An analysis of 30 days with 6 nights over the threshold and 12 at or under it, the nights over it an hour
    /// shorter: an early sign.
    static func analysis(isDemo: Bool = false) -> SleepCaffeineAnalysis {
        SleepCaffeineAnalysis(
            nights: [], tolerance: nil,
            timeAsleep: SleepComparison(
                underSeconds: 7 * 3_600, overSeconds: 6 * 3_600, nightsUnder: 12, nightsOver: 6),
            timeToFallAsleep: nil, period: period, days: 30, isDemo: isDemo)
    }

    /// An answer to "Feel right?" at `confidence`, given a minute after the reference date.
    static func answer(_ answer: InsightFeedback.Answer, _ confidence: SleepPattern.Confidence) -> InsightFeedback {
        InsightFeedback(
            answer: answer, confidence: confidence, headline: "Shorter nights over 40 mg", sentence: "An early sign.",
            answeredAt: Date(timeIntervalSinceReferenceDate: 60))
    }

    /// Every card the use case sends while the repositories send `analyses`, `answers`, and `availabilities`.
    static func cards(
        analyses: [SleepCaffeineAnalysis] = [analysis()], answers: [[InsightFeedback]] = [[]],
        availabilities: [LanguageModelAvailability] = [.available]
    ) async throws -> [InsightCard?] {
        let observe = ObserveInsightCardUseCase(
            sleepTolerance: FakeSleepToleranceRepository(analyses: analyses),
            insightFeedback: FakeInsightFeedbackRepository(sets: answers),
            languageModel: FakeLanguageModelRepository(availabilities: availabilities))
        var cards: [InsightCard?] = []
        for await card in try await executeThroughProtocol(observe, ()) {
            cards.append(card)
        }
        return cards
    }

    // MARK: - CARD-1: with the model available and enough nights, the card shows the finding and asks

    @Test func withEnoughNightsTheCardShowsTheFindingAndAsks() async throws {
        let analysis = Self.analysis()

        #expect(
            try await Self.cards(analyses: [analysis]) == [
                InsightCard(
                    pattern: SleepPatternRule().pattern(from: analysis), asksForFeedback: true, disagreement: nil,
                    isDemo: false)
            ])
    }

    @Test func theCardSaysWhenTheNightsAreTheDemos() async throws {
        let cards = try await Self.cards(analyses: [Self.analysis(isDemo: true)])

        #expect(cards.map { $0?.isDemo } == [true])
    }

    // MARK: - CARD-2: while the model is unavailable, there's no card

    @Test func whileTheModelIsUnavailableThereIsNoCard() async throws {
        #expect(try await Self.cards(availabilities: [.unavailable]) == [nil])
    }

    // MARK: - CARD-3: with too few nights, there's no card

    @Test func withTooFewNightsThereIsNoCard() async throws {
        #expect(try await Self.cards(analyses: [.empty()]) == [nil])
    }

    // MARK: - CARD-4: a "Not really" at the finding's confidence hides the card, and a "Yes" stops the question

    @Test func aNotReallyAtThisConfidenceHidesTheCard() async throws {
        #expect(try await Self.cards(answers: [[Self.answer(.disagree, .earlySign)]]) == [nil])
    }

    @Test func aYesAtThisConfidenceKeepsTheCardWithoutTheQuestion() async throws {
        let cards = try await Self.cards(answers: [[Self.answer(.agree, .earlySign)]])

        #expect(cards.map { $0?.asksForFeedback } == [false])
    }

    // MARK: - CARD-5: after a "Not really" at another confidence, the card asks again, and carries it for the prompt

    @Test func afterANotReallyAtAnotherConfidenceTheCardAsksAndCarriesIt() async throws {
        let disagreement = Self.answer(.disagree, .consistent)
        let cards = try await Self.cards(answers: [[disagreement]])

        #expect(cards.map { $0?.asksForFeedback } == [true])
        #expect(cards.map { $0?.disagreement } == [disagreement])
    }

    // MARK: - CARD-6: it waits for all three streams, and sends a card only when it changes

    @Test func itWaitsForEveryStream() async throws {
        #expect(try await Self.cards(answers: []).isEmpty)
    }

    @Test func itSendsACardOnlyWhenItChanges() async throws {
        let analysis = Self.analysis()

        #expect(try await Self.cards(analyses: [analysis, analysis]).count == 1)
    }
}
