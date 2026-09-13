//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveInsightFeedbackRepository
//

import Foundation
import OSLog

/// The live insight feedback repository: the source of truth for the "Feel right?" answers.
///
/// It reads the answers from its ``InsightFeedbackDataSource`` for each new subscriber, and after it records one, sends
/// every subscriber the new set. It's the only writer, so the data source needs no change signal. It's an actor, off
/// the main actor (constitution Article I.13). The Insights article lists its requirements, FEEDREPO-1 to FEEDREPO-3.
actor LiveInsightFeedbackRepository: InsightFeedbackRepository {
    private static let logger = Logger(for: LiveInsightFeedbackRepository.self)

    private let dataSource: any InsightFeedbackDataSource
    private var subscribers: [UUID: AsyncStream<[InsightFeedback]>.Continuation] = [:]

    /// Creates the repository.
    ///
    /// - Parameter dataSource: Where the answers are stored.
    init(dataSource: any InsightFeedbackDataSource) {
        self.dataSource = dataSource
    }

    /// Streams every answer stored: the current ones, then the new set after each answer is recorded.
    nonisolated func feedback() -> AsyncStream<[InsightFeedback]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [InsightFeedback].self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        Task { await addSubscriber(id, continuation) }
        return stream
    }

    /// Stores an answer, then sends every subscriber the new set.
    ///
    /// - Parameter feedback: The answer, with the finding it answered.
    /// - Throws: The data source's error if it couldn't be stored. Nothing is sent then.
    func record(_ feedback: InsightFeedback) async throws {
        try await dataSource.record(feedback)
        guard let answers = await readAnswers() else { return }
        for subscriber in subscribers.values {
            subscriber.yield(answers)
        }
    }

    private func addSubscriber(_ id: UUID, _ continuation: AsyncStream<[InsightFeedback]>.Continuation) async {
        subscribers[id] = continuation
        if let answers = await readAnswers() {
            continuation.yield(answers)
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    /// Reads the answers. Returns `nil` if they couldn't be read; the data source has logged the error.
    private func readAnswers() async -> [InsightFeedback]? {
        try? await dataSource.answers()
    }
}
