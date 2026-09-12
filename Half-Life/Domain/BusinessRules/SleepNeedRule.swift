//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepNeedRule
//

import Foundation

/// Chooses the nightly sleep recommended for the user's age.
///
/// The age is the current year, in the given calendar, minus the birth year, so it can be a year ahead of the user's
/// real age. With no birth year, it's the adult range. It's stateless and reads no clock. The Onboarding article lists
/// its requirements, SLEEPNEED-1 to SLEEPNEED-3.
nonisolated struct SleepNeedRule {
    /// The first age that gets the adult range.
    static let adultAge = 18
    /// The first age that gets the older adult range.
    static let olderAdultAge = 65

    /// Returns the recommended sleep for someone born in `birthYear`.
    ///
    /// - Parameters:
    ///   - birthYear: The year the user's age implies, or `nil` if they didn't give one.
    ///   - now: The current time.
    ///   - calendar: The calendar whose year the age is counted in.
    /// - Returns: The range for the user's age.
    func recommendedSleep(birthYear: Int?, now: Date, calendar: Calendar) -> RecommendedSleep {
        guard let birthYear else { return .adult }
        let age = calendar.component(.year, from: now) - birthYear
        if age < Self.adultAge {
            return .teen
        }
        return age < Self.olderAdultAge ? .adult : .olderAdult
    }
}
