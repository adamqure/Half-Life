//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveLanguageModelRepository
//

import Foundation
import OSLog

/// The live language model repository.
///
/// It holds only the availability. It re-reads it from the data source at each whole minute the clock streams,
/// because the framework doesn't announce changes, and sends each subscriber a new value only when it changes. It
/// keeps nothing from an instruction or its response. It's an actor off the main actor, like every repository
/// (constitution Article I.13). The Language Model article lists its requirements, LMREPO-1 to LMREPO-5.
actor LiveLanguageModelRepository: LanguageModelRepository {
    private static let logger = Logger(for: LiveLanguageModelRepository.self)

    /// The data source that wraps the model. It never changes, so any context can read it.
    nonisolated let dataSource: any LanguageModelDataSource
    private let clock: any ClockDataSource

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - dataSource: The data source that wraps the model.
    ///   - clock: The clock whose minutes the availability is re-read at.
    init(dataSource: any LanguageModelDataSource, clock: any ClockDataSource) {
        self.dataSource = dataSource
        self.clock = clock
    }

    /// Streams the availability: the current one immediately, then a new one at any minute it has changed
    /// (LMREPO-1, LMREPO-2).
    nonisolated func availability() -> AsyncStream<LanguageModelAvailability> {
        let dataSource = dataSource
        let minutes = clock.minutes()
        return AsyncStream { continuation in
            let task = Task {
                var sent = dataSource.availability()
                continuation.yield(sent)
                for await _ in minutes {
                    let current = dataSource.availability()
                    if current != sent {
                        continuation.yield(current)
                        sent = current
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Answers one instruction, if the model is available (LMREPO-3 to LMREPO-5).
    ///
    /// - Parameter instruction: The prompt, and where it came from.
    /// - Returns: The data source's response.
    /// - Throws: ``LanguageModelError/unavailable`` without reaching the data source while the model is unavailable,
    ///   or the data source's error.
    func respond(to instruction: LanguageModelInstruction) async throws -> String {
        guard dataSource.availability() == .available else {
            Self.logger.notice("Refused an instruction, because the language model is unavailable.")
            throw LanguageModelError.unavailable
        }
        return try await dataSource.respond(to: instruction)
    }

    /// Writes the Insights tab's first finding, if the model is available, and executes ``InsightNumberRule`` on it
    /// (LMREPO-6 to LMREPO-9).
    ///
    /// - Parameter request: The finding to put into words, and the one the user last disagreed with.
    /// - Returns: The insight, when every number in its headline and sentence is in the facts its tools reported.
    /// - Throws: ``LanguageModelError/unavailable`` without reaching the data source while the model is unavailable,
    ///   ``LanguageModelError/ungrounded`` when the insight holds another number, or the data source's error.
    func writeInsight(_ request: InsightRequest) async throws -> Insight {
        guard dataSource.availability() == .available else {
            Self.logger.notice("Refused an insight, because the language model is unavailable.")
            throw LanguageModelError.unavailable
        }
        let written = try await dataSource.writeInsight(request)
        let text = written.insight.headline + "\n" + written.insight.sentence
        guard InsightNumberRule().isGrounded(text, in: written.facts) else {
            Self.logger.notice("Discarded an insight with a number its tools didn't give.")
            throw LanguageModelError.ungrounded
        }
        return written.insight
    }
}
