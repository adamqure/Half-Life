//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests WriteInsightUseCaseTests
//

import Testing

@testable import Half_Life

/// Checks ``WriteInsightUseCase`` against a fake repository (WRITE-1 in the Language Model article).
struct WriteInsightUseCaseTests {

    /// WRITE-1: it passes the request to the repository, and returns its insight.
    @Test func writingReturnsTheRepositorysInsight() async throws {
        let insight = Insight(headline: "Shorter nights over 40 mg", sentence: "An early sign.")
        let repository = FakeLanguageModelRepository(insight: { _ in insight })

        #expect(try await executeThroughProtocol(WriteInsightUseCase(repository: repository), .example) == insight)
        #expect(await repository.insightRequests == [.example])
    }

    /// WRITE-1: it throws the repository's error.
    @Test func writingThrowsTheRepositorysError() async {
        let repository = FakeLanguageModelRepository(insight: { _ in throw LanguageModelError.ungrounded })

        await #expect(throws: LanguageModelError.ungrounded) {
            try await executeThroughProtocol(WriteInsightUseCase(repository: repository), .example)
        }
    }
}
