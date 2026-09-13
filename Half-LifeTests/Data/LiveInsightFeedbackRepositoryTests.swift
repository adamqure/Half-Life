//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveInsightFeedbackRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live insight feedback repository against FEEDREPO-1 to FEEDREPO-3 in the Insights article, with a fake
/// data source. The time limit turns answers that never arrive into a failure instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct LiveInsightFeedbackRepositoryTests {

    struct StoreFailed: Error {}

    static let first = InsightFeedback(
        answer: .disagree, confidence: .earlySign, headline: "Late caffeine, shorter nights",
        sentence: "On 6 nights you slept less.", answeredAt: Date(timeIntervalSinceReferenceDate: 60))
    static let second = InsightFeedback(
        answer: .agree, confidence: .consistent, headline: "A steady pattern", sentence: "Across 12 nights.",
        answeredAt: Date(timeIntervalSinceReferenceDate: 120))

    // MARK: - FEEDREPO-1: a new subscriber gets the stored answers

    @Test func aNewSubscriberGetsTheStoredAnswers() async throws {
        let repository = LiveInsightFeedbackRepository(dataSource: FakeInsightFeedbackDataSource(answers: [Self.first]))

        var answers = repository.feedback().makeAsyncIterator()

        #expect(await answers.next() == [Self.first])
    }

    // MARK: - FEEDREPO-2: a recorded answer is stored, and every subscriber gets the new answers

    @Test func aRecordedAnswerReachesEverySubscriber() async throws {
        let source = FakeInsightFeedbackDataSource(answers: [Self.first])
        let repository = LiveInsightFeedbackRepository(dataSource: source)
        var one = repository.feedback().makeAsyncIterator()
        var two = repository.feedback().makeAsyncIterator()
        _ = await one.next()
        _ = await two.next()

        try await repository.record(Self.second)

        #expect(await one.next() == [Self.first, Self.second])
        #expect(await two.next() == [Self.first, Self.second])
        #expect(await source.stored == [Self.first, Self.second])
    }

    // MARK: - FEEDREPO-3: an answer that can't be stored throws, and changes nothing

    @Test func anAnswerThatCantBeStoredThrows() async throws {
        let source = FakeInsightFeedbackDataSource(answers: [Self.first])
        await source.failRecords(with: StoreFailed())
        let repository = LiveInsightFeedbackRepository(dataSource: source)

        await #expect(throws: StoreFailed.self) {
            try await repository.record(Self.second)
        }
        #expect(await source.stored == [Self.first])
    }
}
