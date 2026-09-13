//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests InsightFeedbackUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the "Feel right?" use cases against FEEDUSE-1 and FEEDUSE-2 in the Insights article, with the fake
/// repositories.
struct InsightFeedbackUseCaseTests {

    struct StoreFailed: Error {}

    static let answer = InsightFeedback(
        answer: .agree, confidence: .earlySign, headline: "Late caffeine, shorter nights",
        sentence: "On 6 nights you slept less.", answeredAt: Date(timeIntervalSinceReferenceDate: 60))

    // MARK: - FEEDUSE-1: observing streams the repository's answers

    @Test func observingStreamsTheRepositorysAnswers() async throws {
        let repository = FakeInsightFeedbackRepository(sets: [[], [Self.answer]])

        var received: [[InsightFeedback]] = []
        for await answers in try await executeThroughProtocol(ObserveInsightFeedbackUseCase(repository: repository), ())
        {
            received.append(answers)
        }

        #expect(received == [[], [Self.answer]])
    }

    // MARK: - FEEDUSE-2: recording stores the answer at the current time, and passes on the repository's error

    @Test func recordingStoresTheAnswerAtTheCurrentTimeAndPassesOnItsError() async throws {
        let input = RecordInsightFeedbackUseCase.Input(
            answer: .agree, confidence: .earlySign,
            insight: Insight(headline: Self.answer.headline, sentence: Self.answer.sentence))
        let now = FakeCurrentTimeRepository(date: Self.answer.answeredAt)
        let repository = FakeInsightFeedbackRepository()

        try await executeThroughProtocol(RecordInsightFeedbackUseCase(currentTime: now, repository: repository), input)
        #expect(repository.recorded.value == [Self.answer])

        let failing = FakeInsightFeedbackRepository(recordError: StoreFailed())
        await #expect(throws: StoreFailed.self) {
            try await RecordInsightFeedbackUseCase(currentTime: now, repository: failing).execute(input)
        }
    }
}
