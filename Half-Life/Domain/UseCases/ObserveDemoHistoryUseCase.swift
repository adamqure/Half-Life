//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveDemoHistoryUseCase
//

/// Streams whether the drink log holds demo drinks, so Settings can offer to add or remove them.
///
/// See the Settings article.
struct ObserveDemoHistoryUseCase: UseCase {
    /// The repository whose answer it streams.
    let drinkLog: any DrinkLogRepository

    /// Streams whether the log holds demo drinks: the current answer first, then each change.
    ///
    /// - Parameter input: Nothing.
    /// - Returns: The repository's stream.
    func execute(_ input: Void) -> AsyncStream<Bool> {
        drinkLog.hasDemoHistory()
    }
}
