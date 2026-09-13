//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life PersonalSleepThresholdDataSource
//

import Foundation
import OSLog

/// Serves the decay model the sleep threshold: the user's caffeine tolerance once their nights show one, and
/// ``SleepThreshold/standard`` until then.
///
/// It's the ``SleepThresholdDataSource`` behind ``CaffeineDecayRepository``, so the cutoff, the composer's warning,
/// the reminders, and the sleep window adopt each tolerance as soon as it's stored. It stores nothing itself: it reads
/// the tolerance data source that ``SleepToleranceRepository`` stores through, and signals when it changes. The
/// Insights article lists its requirements, TOLSRC-1 to TOLSRC-3.
struct PersonalSleepThresholdDataSource: SleepThresholdDataSource {
    private static let logger = Logger(for: PersonalSleepThresholdDataSource.self)

    /// Where the tolerance is stored.
    let tolerances: any SleepToleranceDataSource

    /// Returns the stored tolerance as the threshold, or ``SleepThreshold/standard`` when there's none.
    ///
    /// A tolerance that can't be read is logged, with its error's domain and code only, and the standard threshold is
    /// returned, so the cutoff never fails for want of one.
    func threshold() async throws -> SleepThreshold {
        do {
            guard let tolerance = try await tolerances.storedTolerance(),
                let threshold = SleepThreshold(milligrams: tolerance.milligrams)
            else { return .standard }
            return threshold
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the tolerance: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return .standard
        }
    }

    /// Returns a stream that yields after each stored tolerance, until the subscriber stops listening.
    func changes() async -> AsyncStream<Void> {
        await tolerances.changes()
    }
}
