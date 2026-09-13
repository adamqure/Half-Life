//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepToleranceDataSource
//

/// Reads and stores the user's caffeine tolerance.
///
/// An implementation is the only code that touches the tolerance's storage (constitution Article I.14). It signals
/// every subscriber after each successful store. ``SleepToleranceRepository`` stores through it, and
/// ``PersonalSleepThresholdDataSource`` reads it for the decay model. See the Insights article.
protocol SleepToleranceDataSource: Sendable {
    /// Returns the stored tolerance, or `nil` if none has been stored, or none was found.
    ///
    /// - Throws: An error if a stored tolerance couldn't be read.
    func storedTolerance() async throws -> SleepTolerance?

    /// Stores `tolerance`, or that there's none, in place of whatever was stored, then signals every subscriber.
    ///
    /// - Parameter tolerance: The tolerance to store, or `nil` when the nights show none.
    /// - Throws: An error if it couldn't be stored. Nothing is signalled then.
    func store(_ tolerance: SleepTolerance?) async throws

    /// Returns a stream that yields once after each successful store.
    func changes() async -> AsyncStream<Void>
}
