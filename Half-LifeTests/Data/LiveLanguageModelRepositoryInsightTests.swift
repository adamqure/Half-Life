//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveLanguageModelRepositoryInsightTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks how the live language model repository writes the Insights tab's first finding, against LMREPO-6 to LMREPO-9
/// in the Language Model article, with a fake data source.
struct LiveLanguageModelRepositoryInsightTests {

    struct ModelFailed: Error {}

    /// Part of the facts an insight's prompt gives.
    static let facts = "Caffeine when you fell asleep: over 40 mg on 6 nights, 40 mg or under on 17 nights."

    static func repository(_ dataSource: FakeLanguageModelDataSource) -> LiveLanguageModelRepository {
        LiveLanguageModelRepository(dataSource: dataSource, clock: LiveLanguageModelRepositoryTests.clock(minutes: 0))
    }

    /// A data source that's available, and writes `insight` from the facts above.
    static func dataSource(writing insight: Insight) -> FakeLanguageModelDataSource {
        FakeLanguageModelDataSource(
            availabilities: [.available], insight: { _ in WrittenInsight(insight: insight, facts: facts) })
    }

    /// LMREPO-6: while the model is available, the request reaches the data source, and an insight whose numbers are
    /// all in the facts comes back.
    @Test func writingWhileAvailableReturnsAGroundedInsight() async throws {
        let insight = Insight(
            headline: "Shorter nights over 40 mg",
            sentence: "An early sign: your 6 nights over 40 mg were shorter than your 17 others.")
        let dataSource = Self.dataSource(writing: insight)

        #expect(try await Self.repository(dataSource).writeInsight(.example) == insight)
        #expect(dataSource.insightRequests.value == [.example])
    }

    /// LMREPO-7: an insight with a number the facts don't hold, in its headline or its sentence, is discarded.
    @Test(arguments: [
        Insight(headline: "45 minutes shorter over 40 mg", sentence: "An early sign from your nights."),
        Insight(headline: "Shorter nights over 40 mg", sentence: "An early sign, from 23 nights."),
    ])
    func anInsightWithANumberTheFactsDontHoldIsDiscarded(insight: Insight) async {
        let repository = Self.repository(Self.dataSource(writing: insight))

        await #expect(throws: LanguageModelError.ungrounded) {
            try await repository.writeInsight(.example)
        }
    }

    /// LMREPO-8: while the model is unavailable, writing throws and never reaches the data source.
    @Test func writingWhileUnavailableThrowsWithoutReachingTheDataSource() async {
        let dataSource = FakeLanguageModelDataSource(availabilities: [.unavailable])

        await #expect(throws: LanguageModelError.unavailable) {
            try await Self.repository(dataSource).writeInsight(.example)
        }
        #expect(dataSource.insightRequests.value.isEmpty)
    }

    /// LMREPO-9: the data source's error is thrown on to the caller.
    @Test func writingThrowsTheDataSourcesError() async {
        let dataSource = FakeLanguageModelDataSource(
            availabilities: [.available], insight: { _ in throw ModelFailed() })

        await #expect(throws: ModelFailed.self) {
            try await Self.repository(dataSource).writeInsight(.example)
        }
    }
}
