//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DailyCaffeineIntake
//

import Foundation

/// The caffeine the user logged on one calendar day: the Today screen's "Today" tile.
///
/// ``DailyCaffeineIntakeRule`` calculates it. See the Today Screen article.
struct DailyCaffeineIntake: Sendable, Equatable {
    /// The start of the day: its midnight, in the calendar the intake was calculated in.
    let day: Date
    /// The caffeine in every drink consumed that day, in milligrams, as each was logged. Never negative.
    let milligrams: Double
}
