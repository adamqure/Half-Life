//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WidgetTimeline
//

import Foundation

/// The widgets' timeline: what they show at each moment, and when WidgetKit should ask for a new one.
///
/// ``WidgetTimelineRule`` calculates it from a ``WidgetSnapshot``. See the Widgets article.
nonisolated struct WidgetTimeline: Sendable, Equatable {
    /// The entries, earliest first.
    let entries: [WidgetTimelineEntry]
    /// When WidgetKit should ask for a new timeline.
    let reloadDate: Date
}

/// What the widgets show from one moment until the next entry.
nonisolated struct WidgetTimelineEntry: Sendable, Equatable {
    /// When the entry starts to show.
    let date: Date
    /// The caffeine and the favourites, or `nil` while Half-Life isn't set up, so the widgets ask the user to finish
    /// setting it up.
    let content: WidgetContent?
}

/// The caffeine and the favourites one widget entry shows.
nonisolated struct WidgetContent: Sendable, Equatable {
    /// The level at the entry's date.
    let level: CaffeineLevel
    /// The levels from 6 hours before the entry's date to 6 hours after, every 5 minutes.
    let curve: [CaffeineLevel]
    /// The level at the next bedtime at or after the entry's date, or `nil` if the calendar can't find it.
    let levelAtBedtime: CaffeineLevel?
    /// The three one-tap favourites, most logged first.
    let favourites: [FavouriteDrink]
    /// When the latest drink was consumed, or `nil` if none has been logged.
    let latestDrinkAt: Date?
}
