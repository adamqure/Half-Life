//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life EstimatedHalfLifeDataSource
//

import Foundation
import OSLog

/// Serves the decay model the user's half-life: the personal estimate's, when it started from the survey's current
/// answers, and otherwise the survey's starting half-life.
///
/// It's the ``HalfLifeDataSource`` behind ``CaffeineDecayRepository``, so the curve adopts each estimate as soon as
/// it's stored. An estimate that started from older answers is ignored until it's recalculated, so a changed survey
/// reaches the curve at once. It stores nothing itself: it reads the estimate data source and the profile's half-life,
/// and signals when either changes. The Half-Life Estimator article lists its requirements, ESTSRC-1 to ESTSRC-3.
struct EstimatedHalfLifeDataSource: HalfLifeDataSource {
    private static let logger = Logger(for: EstimatedHalfLifeDataSource.self)

    /// Where the personal estimate is stored.
    let estimates: any HalfLifeEstimateDataSource
    /// Where the survey's starting half-life is read from: the profile.
    let prior: any HalfLifeDataSource

    /// Returns the estimate's half-life if it started from the survey's current half-life, and the survey's otherwise.
    ///
    /// An estimate that can't be read is logged, with its error's domain and code only, and the survey's half-life is
    /// returned.
    ///
    /// - Throws: The profile's error if the survey's half-life couldn't be read.
    func halfLife() async throws -> CaffeineHalfLife {
        let surveyed = try await prior.halfLife()
        do {
            guard let estimate = try await estimates.storedEstimate(), estimate.prior == surveyed else {
                return surveyed
            }
            return estimate.halfLife
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the estimate: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return surveyed
        }
    }

    /// Returns a stream that yields after each change to the estimate or to the survey's half-life, until the
    /// subscriber stops listening.
    func changes() async -> AsyncStream<Void> {
        let sources = [await estimates.changes(), await prior.changes()]
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        let forwarders = sources.map { changes in
            Task {
                for await _ in changes {
                    continuation.yield()
                }
            }
        }
        continuation.onTermination = { _ in
            for forwarder in forwarders {
                forwarder.cancel()
            }
        }
        return stream
    }
}
