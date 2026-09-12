//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkLogRepository
//

/// The source of truth for every drink the user has logged.
///
/// An implementation stores drinks through the drink data source, which it shares with ``CaffeineDecayRepository``.
/// It publishes what the data source holds: after each change the data source signals, it re-reads the drinks and
/// publishes them. The Drink Composer article lists its requirements, DLOG-1 to DLOG-3.
protocol DrinkLogRepository: Sendable {
    /// Streams every logged drink, oldest first, starting with the current set.
    ///
    /// Each new subscriber immediately receives every logged drink. After that, every subscriber receives the
    /// updated set whenever the drink data source signals a change.
    func loggedDrinks() -> AsyncStream<[LoggedDrink]>

    /// Stores a drink. The updated set is published when the data source signals the change.
    ///
    /// The repository first executes ``DrinkLogRule`` with the current time.
    ///
    /// - Parameter drink: The drink to store.
    /// - Throws: A ``DrinkLogRule/Violation`` if the drink can't be logged, or an error if it couldn't be stored.
    func log(_ drink: LoggedDrink) async throws
}
