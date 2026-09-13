//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HalfLifeEstimateRepository
//

import Foundation

/// The source of truth for the user's personal half-life estimate.
///
/// An implementation executes ``SleepNightRule`` and ``HalfLifeEstimationRule`` on the user's drinks and Health data,
/// and stores the estimate where the decay model reads its half-life, so the curve adopts it. It recalculates only
/// when the estimate is due: when none is stored, when it's a week old, or when the survey's starting half-life has
/// changed. The Half-Life Estimator article lists its requirements, ESTREPO-1 to ESTREPO-8.
///
/// It isn't marked `nonisolated`: an actor that conforms to a `nonisolated` protocol in the same module inherits
/// `nonisolated`, which an actor can't be (constitution Article IV.1).
protocol HalfLifeEstimateRepository: Sendable {
    /// Streams the estimate: the current one as soon as it's subscribed to, then each one recalculated after that.
    ///
    /// A subscriber arriving when the estimate is due waits for the recalculation. If there's no estimate and none
    /// can be calculated, because the data couldn't be read, the stream sends nothing until one can.
    func estimate() -> AsyncStream<HalfLifeEstimate>

    /// Recalculates the estimate if it's due, and publishes it. A recalculation that's already running covers it.
    func refresh() async
}
