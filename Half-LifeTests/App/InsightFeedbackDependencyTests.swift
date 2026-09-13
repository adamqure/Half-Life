//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests InsightFeedbackDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the registrations for the Insights tab's first card: the "Feel right?" answers, and the card itself
/// (constitution Article I.15, DEP-FEEDBACK and DEP-CARD in the Insights article). None of these tests opens a store.
struct InsightFeedbackDependencyTests {

    @Test func testObservingTheAnswersReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeInsightFeedback) var observeInsightFeedback
            for await _ in observeInsightFeedback.execute(()) {}
        }
    }

    @Test func testRecordingAnAnswerReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.recordInsightFeedback) var recordInsightFeedback
            try? await recordInsightFeedback.execute(
                .init(answer: .agree, confidence: .earlySign, insight: Insight(headline: "", sentence: "")))
        }
    }

    @Test func testObservingTheCardReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeInsightCard) var observeInsightCard
            for await _ in observeInsightCard.execute(()) {}
        }
    }

    /// DEP-FEEDBACK: in previews, both use cases hold the one app-scoped repository.
    @Test func previewUseCasesHoldTheAppScopedRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.insightFeedbackRepository) var repository
            @Dependency(\.observeInsightFeedback) var observeInsightFeedback
            @Dependency(\.recordInsightFeedback) var recordInsightFeedback
            #expect((observeInsightFeedback.repository as AnyObject) === (repository as AnyObject))
            #expect((recordInsightFeedback.repository as AnyObject) === (repository as AnyObject))
        }
    }
}

extension SwiftDataStoreTests {

    /// Checks the card's preview registration. The preview sleep tolerance and language model repositories open an
    /// empty in-memory store, so this runs inside the serialized `SwiftDataStoreTests`.
    @Suite(.timeLimit(.minutes(1)))
    struct InsightCardPreviewDependencyTests {

        /// DEP-CARD: the card's use case holds the app-scoped sleep tolerance, answers, and language model
        /// repositories.
        @Test func previewCardHoldsTheAppScopedRepositories() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.sleepToleranceRepository) var sleepTolerance
                @Dependency(\.insightFeedbackRepository) var insightFeedback
                @Dependency(\.languageModelRepository) var languageModel
                @Dependency(\.observeInsightCard) var observeInsightCard
                #expect((observeInsightCard.sleepTolerance as AnyObject) === (sleepTolerance as AnyObject))
                #expect((observeInsightCard.insightFeedback as AnyObject) === (insightFeedback as AnyObject))
                #expect((observeInsightCard.languageModel as AnyObject) === (languageModel as AnyObject))
            }
        }
    }
}
