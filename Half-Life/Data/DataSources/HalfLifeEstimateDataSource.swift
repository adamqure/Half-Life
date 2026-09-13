//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HalfLifeEstimateDataSource
//

/// Reads and stores the user's personal half-life estimate.
///
/// An implementation is the only code that touches the estimate's storage (constitution Article I.14). It signals
/// every subscriber after each successful store. ``HalfLifeEstimateRepository`` stores through it, and
/// ``EstimatedHalfLifeDataSource`` reads it for the decay model. See the Half-Life Estimator article.
protocol HalfLifeEstimateDataSource: Sendable {
    /// Returns the stored estimate, or `nil` if nothing has been stored.
    ///
    /// - Throws: An error if a stored estimate couldn't be read.
    func storedEstimate() async throws -> HalfLifeEstimate?

    /// Stores `estimate` in place of whatever was stored, then signals every subscriber.
    ///
    /// - Parameter estimate: The estimate to store.
    /// - Throws: An error if the estimate couldn't be stored. Nothing is signalled.
    func store(_ estimate: HalfLifeEstimate) async throws

    /// Returns a stream that yields once after each successful store.
    func changes() async -> AsyncStream<Void>
}
