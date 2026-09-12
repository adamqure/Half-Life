//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkLogHistoryViewAccessibilityID
//

/// Accessibility identifiers for the history card, shared with the UI test target.
///
/// The card is part of the Today screen, so it has no `screen` identifier. `TodayRobot` uses these.
enum DrinkLogHistoryViewAccessibilityID {
    /// The day's title, such as "Logged today".
    static let title = "drinkLogHistoryView.title"
    /// The button that shows the day before.
    static let previousDayButton = "drinkLogHistoryView.previousDayButton"
    /// The button that shows the day after.
    static let nextDayButton = "drinkLogHistoryView.nextDayButton"
    /// The button that returns the card to today, shown only on an earlier day.
    static let todayButton = "drinkLogHistoryView.todayButton"
    /// The day's total caffeine.
    static let total = "drinkLogHistoryView.total"
    /// A logged drink's row. Every row has this identifier.
    static let drink = "drinkLogHistoryView.drink"
    /// A logged drink's delete button. Every row's button has this identifier.
    static let deleteButton = "drinkLogHistoryView.deleteButton"
    /// The button that confirms the pending deletion.
    static let confirmDeleteButton = "drinkLogHistoryView.confirmDeleteButton"
    /// The button that keeps the drink instead of deleting it.
    static let cancelDeleteButton = "drinkLogHistoryView.cancelDeleteButton"
    /// The message shown when the day has no drinks.
    static let emptyMessage = "drinkLogHistoryView.emptyMessage"
    /// The message shown when a drink couldn't be deleted.
    static let errorMessage = "drinkLogHistoryView.errorMessage"
}
