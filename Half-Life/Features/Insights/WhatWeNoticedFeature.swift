//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WhatWeNoticedFeature
//

import ComposableArchitecture
import Foundation
import OSLog

/// The Insights tab's first card, "What we noticed": one finding about the user's own nights, which the on-device
/// language model puts into words, with "Feel right?".
///
/// It observes the card, and reduces each value into `State`. When the card's request changes, it asks the model to
/// write the insight for it, and keeps the insight until the request changes again, so a "Yes" doesn't rewrite it. An
/// insight for an earlier request is dropped. The card shows only with an insight, so it stays hidden while one is
/// being written, and when one couldn't be written or failed the number check. An answer is recorded, and the card
/// follows the answers' stream rather than hiding itself (constitution Article I.5). See the Insights article,
/// NOTICED-1 to NOTICED-7.
@Reducer nonisolated struct WhatWeNoticedFeature {
    private static let logger = Logger(for: WhatWeNoticedFeature.self)

    /// What the card shows.
    @ObservableState
    struct State: Equatable {
        /// What the card shows, or `nil` while it's hidden.
        var card: InsightCard?
        /// The request the insight is written for, or `nil` before the first card.
        var request: InsightRequest?
        /// The finding in the model's words, or `nil` until it's written.
        var insight: Insight?
    }

    /// What can happen to the card.
    enum Action {
        /// Subscribes to the card, for as long as the tab is on screen.
        case task
        /// The card changed, or is hidden.
        case cardUpdated(InsightCard?)
        /// The model wrote the insight for a request.
        case insightWritten(InsightRequest, Insight)
        /// The user answered "Feel right?".
        case answered(InsightFeedback.Answer)
    }

    private enum CancelID {
        case write
    }

    @Dependency(\.observeInsightCard) private var observeInsightCard
    @Dependency(\.writeInsight) private var writeInsight
    @Dependency(\.recordInsightFeedback) private var recordInsightFeedback

    /// Starts the observation, writes the insight for each new request, and records each answer.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { [observeInsightCard] send in
                    for await card in observeInsightCard.execute(()) {
                        await send(.cardUpdated(card))
                    }
                }
            case let .cardUpdated(card):
                state.card = card
                guard let card else { return .none }
                let request = InsightRequest(pattern: card.pattern, disagreement: card.disagreement)
                guard request != state.request else { return .none }
                state.request = request
                state.insight = nil
                return write(request)
            case let .insightWritten(request, insight):
                guard request == state.request else { return .none }
                state.insight = insight
                return .none
            case let .answered(answer):
                guard let card = state.card, let insight = state.insight else { return .none }
                return record(.init(answer: answer, confidence: card.pattern.confidence, insight: insight))
            }
        }
    }

    /// Asks the model to write the insight for `request`, cancelling one still being written.
    ///
    /// A failure leaves the card without an insight. The repository or data source has already logged why.
    private func write(_ request: InsightRequest) -> Effect<Action> {
        .run { [writeInsight] send in
            guard let insight = try? await writeInsight.execute(request) else { return }
            await send(.insightWritten(request, insight))
        }
        .cancellable(id: CancelID.write, cancelInFlight: true)
    }

    /// Records an answer to "Feel right?". The answers' stream brings the change back to the card.
    private func record(_ input: RecordInsightFeedbackUseCase.Input) -> Effect<Action> {
        .run { [recordInsightFeedback] _ in
            do {
                try await recordInsightFeedback.execute(input)
            } catch {
                let error = error as NSError
                Self.logger.error(
                    "Couldn't store an answer: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            }
        }
    }
}
