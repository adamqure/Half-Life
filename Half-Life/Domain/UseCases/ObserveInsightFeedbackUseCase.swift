//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveInsightFeedbackUseCase
//

import Foundation

/// Streams the "Feel right?" answers on the Insights tab's first card.
///
/// ``InsightFeedbackRepository`` stores them. See the Insights article.
struct ObserveInsightFeedbackUseCase: UseCase {
    /// The repository that stores the answers.
    let repository: any InsightFeedbackRepository

    /// Returns a stream of the answers: the current ones, then each new set.
    func execute(_ input: Void) -> AsyncStream<[InsightFeedback]> {
        repository.feedback()
    }
}
