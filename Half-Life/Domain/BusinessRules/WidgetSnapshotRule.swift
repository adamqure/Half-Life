//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life WidgetSnapshotRule
//

import Foundation

/// The business rule that calculates the ``WidgetSnapshot`` the Home Screen widgets read.
///
/// Its forecast runs until the caffeine is gone, not across the in-app curve's fixed window. Every new drink is logged
/// in the app, which writes a new snapshot, so while nothing new is logged the forecast stays right however long the
/// app goes without running. It asks ``CaffeineDecayRule`` for every level and ``FavouriteDrinksRule`` for the
/// favourites. It holds no state and reads no clock. ``WidgetSnapshotRepository`` executes it. See the Widgets article.
nonisolated struct WidgetSnapshotRule: Sendable {
    /// The time between the forecast's levels, in seconds.
    static let spacing: TimeInterval = 5 * 60
    /// How long before the current 5-minute mark the forecast starts, in seconds.
    static let lookBehind: TimeInterval = 12 * 60 * 60
    /// The shortest the forecast can be, in seconds, so it always reaches 12 hours past the current mark.
    static let minimumLength: TimeInterval = 24 * 60 * 60
    /// The furthest past the current mark the forecast reaches, in seconds, however slowly caffeine clears.
    static let maximumLookAhead: TimeInterval = 7 * 24 * 60 * 60

    private let decay = CaffeineDecayRule()
    private let favouritesRule = FavouriteDrinksRule()

    /// Returns the forecast for `now`: a level at every whole 5-minute mark, from ``lookBehind`` before the current
    /// mark until the first mark at least ``minimumLength`` after the start at which no intake still counts, and never
    /// past ``maximumLookAhead`` after the current mark.
    ///
    /// - Parameters:
    ///   - intakes: The intakes that still count.
    ///   - kinetics: The elimination half-life and the absorption rate.
    ///   - now: The current time.
    func forecast(from intakes: [CaffeineIntake], kinetics: CaffeineKinetics, now: Date) -> [CaffeineLevel] {
        let mark = (now.timeIntervalSinceReferenceDate / Self.spacing).rounded(.down) * Self.spacing
        let start = mark - Self.lookBehind
        let minimumEnd = start + Self.minimumLength
        let maximumEnd = mark + Self.maximumLookAhead
        var levels: [CaffeineLevel] = []
        var index = 0.0
        while true {
            let seconds = start + index * Self.spacing
            let date = Date(timeIntervalSinceReferenceDate: seconds)
            levels.append(decay.level(at: date, from: intakes, kinetics: kinetics))
            let anyCounting = intakes.contains { decay.isCounting($0, at: date, kinetics: kinetics) }
            if seconds >= maximumEnd || (seconds >= minimumEnd && !anyCounting) {
                return levels
            }
            index += 1
        }
    }

    /// Returns the snapshot for `now`.
    ///
    /// - Parameters:
    ///   - drinks: Every logged drink, for the favourites and the last cup.
    ///   - intakes: The intakes that still count, for the forecast.
    ///   - kinetics: The elimination half-life and the absorption rate.
    ///   - profile: The user's profile, for the bedtime and whether onboarding is complete, or `nil` if none has been
    ///     saved, which gives the standard bedtime and onboarding not complete.
    ///   - now: The current time.
    func snapshot(
        drinks: [LoggedDrink], intakes: [CaffeineIntake], kinetics: CaffeineKinetics, profile: UserProfile?, now: Date
    ) -> WidgetSnapshot {
        WidgetSnapshot(
            forecast: forecast(from: intakes, kinetics: kinetics, now: now), bedtime: profile?.bedtime ?? .standard,
            favourites: favouritesRule.favourites(from: drinks), latestDrinkAt: drinks.map(\.consumedAt).max(),
            isOnboardingComplete: profile?.hasCompletedOnboarding ?? false, writtenAt: now)
    }
}
