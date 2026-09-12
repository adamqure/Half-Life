//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveLoggedDrinksUseCase
//

/// Streams every logged drink, oldest first, starting with the current set.
///
/// The drink composer observes it to open on the last drink logged. See the Drink Composer article.
struct ObserveLoggedDrinksUseCase: UseCase {
    /// The repository whose drinks are streamed.
    let repository: any DrinkLogRepository

    /// Streams every set of drinks the repository publishes.
    ///
    /// - Parameter input: None.
    /// - Returns: The logged drinks, oldest first: the current set, then the updated set after each change.
    func execute(_ input: Void) -> AsyncStream<[LoggedDrink]> {
        repository.loggedDrinks()
    }
}
