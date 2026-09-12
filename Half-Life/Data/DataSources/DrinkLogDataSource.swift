//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkLogDataSource
//

/// Stores the drinks the user logs, and their negligible marks.
///
/// An implementation is the only code that touches the drink log's storage (constitution Article I.14). Two
/// repositories share it. The drink log repository stores and reads drinks, and ``LiveCaffeineDecayRepository``
/// reads the drinks that still count and marks the ones that don't. The data source signals a change after each
/// store and each deletion, so both repositories hear about a drink however it was stored or deleted. The Drink
/// Composer article lists its requirements, SRC-1 to SRC-7, and the Caffeine Decay Model article lists DATA-1 to
/// DATA-5.
protocol DrinkLogDataSource: Sendable {
    /// Stores a drink, unmarked, then signals a change to every subscriber.
    ///
    /// - Parameter drink: The drink to store.
    /// - Throws: An error if the drink couldn't be stored. Nothing is signalled then.
    func store(_ drink: LoggedDrink) async throws

    /// Deletes the drink with the given identifier, marked or not, then signals a change to every subscriber.
    ///
    /// When no stored drink has the identifier, it changes nothing and signals nothing.
    ///
    /// - Parameter id: The identifier of the drink to delete.
    /// - Throws: An error if the deletion couldn't be stored. Nothing is signalled then.
    func delete(_ id: LoggedDrink.ID) async throws

    /// Returns every stored drink, oldest first, whether or not it's marked negligible.
    ///
    /// - Throws: An error if the drinks couldn't be read.
    func drinks() async throws -> [LoggedDrink]

    /// Returns the drinks that aren't marked negligible, oldest first.
    ///
    /// - Throws: An error if the drinks couldn't be read.
    func nonNegligibleDrinks() async throws -> [LoggedDrink]

    /// Marks the drinks with the given intakes' identifiers as negligible.
    ///
    /// A mark is never cleared, marking never deletes a drink, and marking signals nothing.
    ///
    /// - Parameter intakes: The intakes whose drinks to mark.
    /// - Throws: An error if the marks couldn't be stored.
    func markNegligible(_ intakes: [CaffeineIntake]) async throws

    /// Returns a stream for one subscriber that yields after each change.
    ///
    /// The stream ends when its subscriber stops listening.
    func changes() async -> AsyncStream<Void>
}
