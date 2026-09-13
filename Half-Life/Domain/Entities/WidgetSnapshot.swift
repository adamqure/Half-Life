//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WidgetSnapshot
//

import Foundation

/// Everything the Home Screen widgets show, as the app last calculated it.
///
/// The app is the only process that writes user data, so it writes this snapshot for the widget extension to read.
/// ``WidgetSnapshotRule`` calculates it, ``WidgetSnapshotRepository`` stores it, and ``WidgetTimelineRule`` turns it
/// into the widgets' timeline. It's health data, derived from the drink log, the profile, and the half-life estimated
/// from Health data. See the Widgets article.
nonisolated struct WidgetSnapshot: Sendable, Equatable {
    /// The level every 5 minutes, from 12 hours before the snapshot was written until no intake still counts. It always
    /// runs at least 12 hours past the 5-minute mark it was written at.
    let forecast: [CaffeineLevel]
    /// The bedtime, so each entry can find the next one.
    let bedtime: Bedtime
    /// The three one-tap favourites, most logged first.
    let favourites: [FavouriteDrink]
    /// When the latest drink was consumed, or `nil` if none has been logged.
    let latestDrinkAt: Date?
    /// Whether onboarding is complete. Until it is, the widgets ask the user to finish setting up.
    let isOnboardingComplete: Bool
    /// When the app calculated it.
    let writtenAt: Date
}
