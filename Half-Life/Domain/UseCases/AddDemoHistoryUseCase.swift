//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AddDemoHistoryUseCase
//

import Foundation

/// Adds 30 days of demo drinks to the drink log, ending now.
///
/// Settings adds the demo history through this use case. ``DrinkLogRepository`` executes ``DemoHistoryRule`` and
/// replaces any demo drinks already in the log, so adding it twice doesn't double it. The user's own drinks stay. See
/// the Settings article.
struct AddDemoHistoryUseCase: UseCase {
    /// The repository that stores the demo drinks.
    let drinkLog: any DrinkLogRepository

    /// Adds the demo history.
    ///
    /// - Parameter input: The calendar, and so the time zone, whose days and clock times the demo follows.
    /// - Throws: The repository's error if the demo drinks couldn't be stored.
    func execute(_ input: Calendar) async throws {
        try await drinkLog.addDemoHistory(in: input)
    }
}
