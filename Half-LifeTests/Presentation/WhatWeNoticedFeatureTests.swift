//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests WhatWeNoticedFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the Insights tab's first card, "What we noticed", against NOTICED-1 to NOTICED-7 in the Insights article.
@MainActor
struct WhatWeNoticedFeatureTests {

    nonisolated static let period = DateInterval(
        start: Date(timeIntervalSinceReferenceDate: 0), duration: 30 * 24 * 3_600)

    /// A finding over 30 days, with `nightsOver` nights over 40 mg and 12 at or under it.
    nonisolated static func pattern(
        confidence: SleepPattern.Confidence = .earlySign, nightsOver: Int = 6
    ) -> SleepPattern {
        SleepPattern(
            period: period, days: 30, nightsOver: nightsOver, nightsUnder: 12, threshold: .standard,
            direction: .shorter, confidence: confidence)
    }

    /// A card with `pattern`, asking "Feel right?" when `asks`.
    nonisolated static func card(
        _ pattern: SleepPattern = pattern(), asks: Bool = true, disagreement: InsightFeedback? = nil
    ) -> InsightCard {
        InsightCard(pattern: pattern, asksForFeedback: asks, disagreement: disagreement, isDemo: false)
    }

    /// The request for the default card.
    nonisolated static let request = InsightRequest(pattern: pattern(), disagreement: nil)
    nonisolated static let insight = Insight(
        headline: "Shorter nights over 40 mg", sentence: "An early sign, from 18 nights.")

    /// A card showing the default card's insight.
    static func showing() -> WhatWeNoticedFeature.State {
        WhatWeNoticedFeature.State(card: card(), request: request, insight: insight)
    }

    // MARK: - NOTICED-1: `task` reduces each card into State, and writes the insight for its request

    @Test func taskReducesTheCardAndWritesItsInsight() async {
        let analysis = SleepCaffeineAnalysis(
            nights: [], tolerance: nil,
            timeAsleep: SleepComparison(
                underSeconds: 7 * 3_600, overSeconds: 6 * 3_600, nightsUnder: 12, nightsOver: 6),
            timeToFallAsleep: nil, period: Self.period, days: 30, isDemo: false)
        let card = Self.card(SleepPatternRule().pattern(from: analysis))
        let request = InsightRequest(pattern: card.pattern, disagreement: nil)
        let model = FakeLanguageModelRepository(availabilities: [.available], insight: { _ in Self.insight })
        let store = TestStore(initialState: WhatWeNoticedFeature.State()) {
            WhatWeNoticedFeature()
        } withDependencies: {
            $0.observeInsightCard = ObserveInsightCardUseCase(
                sleepTolerance: FakeSleepToleranceRepository(analyses: [analysis]),
                insightFeedback: FakeInsightFeedbackRepository(sets: [[]]), languageModel: model)
            $0.writeInsight = WriteInsightUseCase(repository: model)
        }

        await store.send(.task)
        await store.receive(\.cardUpdated) {
            $0.card = card
            $0.request = request
        }
        await store.receive(\.insightWritten) {
            $0.insight = Self.insight
        }
        await store.finish()
        #expect(await model.insightRequests == [request])
    }

    // MARK: - NOTICED-2: a card for the same request keeps its insight, so a "Yes" only hides the question

    @Test func aCardForTheSameRequestKeepsItsInsight() async {
        let store = TestStore(initialState: Self.showing()) {
            WhatWeNoticedFeature()
        }

        await store.send(.cardUpdated(Self.card(asks: false))) {
            $0.card = Self.card(asks: false)
        }
    }

    // MARK: - NOTICED-3: a card with a new request writes a new insight, with the finding the user disagreed with

    @Test func aNewRequestWritesANewInsight() async {
        let disagreement = InsightFeedback(
            answer: .disagree, confidence: .earlySign, headline: Self.insight.headline,
            sentence: Self.insight.sentence, answeredAt: Date(timeIntervalSinceReferenceDate: 60))
        let card = Self.card(Self.pattern(confidence: .consistent, nightsOver: 10), disagreement: disagreement)
        let request = InsightRequest(pattern: card.pattern, disagreement: disagreement)
        let newInsight = Insight(headline: "Your longer nights", sentence: "Consistent so far, from 22 nights.")
        let model = FakeLanguageModelRepository(insight: { _ in newInsight })
        let store = TestStore(initialState: Self.showing()) {
            WhatWeNoticedFeature()
        } withDependencies: {
            $0.writeInsight = WriteInsightUseCase(repository: model)
        }

        await store.send(.cardUpdated(card)) {
            $0.card = card
            $0.request = request
            $0.insight = nil
        }
        await store.receive(\.insightWritten) {
            $0.insight = newInsight
        }
        #expect(await model.insightRequests == [request])
    }

    // MARK: - NOTICED-4: a hidden card hides the card

    @Test func aHiddenCardHidesTheCard() async {
        let store = TestStore(initialState: Self.showing()) {
            WhatWeNoticedFeature()
        }

        await store.send(.cardUpdated(nil)) {
            $0.card = nil
        }
    }

    // MARK: - NOTICED-5: when the insight can't be written, or fails the number check, there's no insight to show

    @Test func anInsightThatCantBeWrittenLeavesNone() async {
        let store = TestStore(initialState: WhatWeNoticedFeature.State()) {
            WhatWeNoticedFeature()
        } withDependencies: {
            $0.writeInsight = WriteInsightUseCase(
                repository: FakeLanguageModelRepository(insight: { _ in throw LanguageModelError.ungrounded }))
        }

        await store.send(.cardUpdated(Self.card())) {
            $0.card = Self.card()
            $0.request = Self.request
        }
        await store.finish()
    }

    // MARK: - NOTICED-6: an insight written for an earlier request is dropped

    @Test func anInsightForAnEarlierRequestIsDropped() async {
        let current = Self.card(Self.pattern(confidence: .consistent, nightsOver: 10))
        let store = TestStore(
            initialState: WhatWeNoticedFeature.State(
                card: current, request: InsightRequest(pattern: current.pattern, disagreement: nil))
        ) {
            WhatWeNoticedFeature()
        }

        await store.send(.insightWritten(Self.request, Self.insight))
    }

    // MARK: - NOTICED-7: an answer is recorded with the card's confidence and the insight, at the current time

    @Test(arguments: [InsightFeedback.Answer.agree, .disagree])
    func answeringRecordsTheAnswer(answer: InsightFeedback.Answer) async {
        let answers = FakeInsightFeedbackRepository()
        let now = Date(timeIntervalSinceReferenceDate: 3_600)
        let store = TestStore(initialState: Self.showing()) {
            WhatWeNoticedFeature()
        } withDependencies: {
            $0.recordInsightFeedback = RecordInsightFeedbackUseCase(
                currentTime: FakeCurrentTimeRepository(date: now), repository: answers)
        }

        await store.send(.answered(answer))
        await store.finish()
        #expect(
            answers.recorded.value == [
                InsightFeedback(
                    answer: answer, confidence: .earlySign, headline: Self.insight.headline,
                    sentence: Self.insight.sentence, answeredAt: now)
            ])
    }

    @Test func anAnswerThatCantBeStoredChangesNothing() async {
        let store = TestStore(initialState: Self.showing()) {
            WhatWeNoticedFeature()
        } withDependencies: {
            $0.recordInsightFeedback = RecordInsightFeedbackUseCase(
                currentTime: FakeCurrentTimeRepository(date: .distantPast),
                repository: FakeInsightFeedbackRepository(recordError: LanguageModelError.unavailable))
        }

        await store.send(.answered(.agree))
        await store.finish()
    }

    @Test func withoutAnInsightThereIsNothingToAnswer() async {
        let store = TestStore(
            initialState: WhatWeNoticedFeature.State(card: Self.card(), request: Self.request)
        ) {
            WhatWeNoticedFeature()
        }

        await store.send(.answered(.agree))
    }
}
