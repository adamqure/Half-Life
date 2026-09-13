//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RemoveDemoHistoryUseCase
//

/// Removes every demo drink from the drink log, and leaves the user's own drinks.
///
/// Settings removes the demo history through this use case. See the Settings article.
struct RemoveDemoHistoryUseCase: UseCase {
    /// The repository that deletes the demo drinks.
    let drinkLog: any DrinkLogRepository

    /// Removes the demo history.
    ///
    /// - Parameter input: Nothing.
    /// - Throws: The repository's error if the deletion couldn't be stored.
    func execute(_ input: Void) async throws {
        try await drinkLog.removeDemoHistory()
    }
}
