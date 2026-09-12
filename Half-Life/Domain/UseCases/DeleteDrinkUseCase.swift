//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DeleteDrinkUseCase
//

/// Deletes a drink the user logged.
///
/// The history card deletes drinks through this use case. It deletes through ``DrinkLogRepository``. The drink log's
/// streams and ``CaffeineDecayRepository`` hear about the deletion from the data source the two repositories share,
/// not from this use case. See the Today Screen article.
struct DeleteDrinkUseCase: UseCase {
    /// The repository that deletes the drink.
    let drinkLog: any DrinkLogRepository

    /// Deletes the drink with the given identifier.
    ///
    /// - Parameter input: The identifier of the drink to delete.
    /// - Throws: The repository's error if the deletion couldn't be stored.
    func execute(_ input: LoggedDrink.ID) async throws {
        try await drinkLog.delete(input)
    }
}
