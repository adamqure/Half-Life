//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life UserProfileRepository
//

import Foundation

/// The source of truth for what the user has told the app about themselves.
///
/// It's app-scoped. Onboarding saves through it, and features observe the profile and the recommended sleep that
/// follows from it. See the Onboarding and Today Screen articles.
protocol UserProfileRepository: Sendable {
    /// Streams the user's profile: the current one as soon as it's subscribed to, then every change.
    ///
    /// When nothing has been stored, or the stored profile can't be read, the current profile has nothing given.
    func profile() -> AsyncStream<UserProfile>

    /// Streams the nightly sleep recommended for the user's age: the current range, then one after every change to
    /// the profile.
    ///
    /// - Parameter calendar: The calendar whose year the user's age is counted in.
    func recommendedSleep(in calendar: Calendar) -> AsyncStream<RecommendedSleep>

    /// Saves the user's name and birth year, keeping the rest of the profile.
    ///
    /// - Parameters:
    ///   - name: The first name, or `nil` for none.
    ///   - birthYear: The year the user's age implies, or `nil` for none.
    /// - Throws: An error if the profile couldn't be stored.
    func saveAboutYou(name: String?, birthYear: Int?) async throws

    /// Saves what changes how fast the user clears caffeine, with the half-life ``HalfLifePriorRule`` gives for it.
    ///
    /// - Parameter factors: The factors the user chose. Empty means none of them.
    /// - Throws: An error if the profile couldn't be stored.
    func saveHalfLifeFactors(_ factors: Set<HalfLifeFactor>) async throws

    /// Saves when the user wants to be asleep.
    ///
    /// - Parameter bedtime: The bedtime.
    /// - Throws: An error if the profile couldn't be stored.
    func saveBedtime(_ bedtime: Bedtime) async throws

    /// Records that the user has finished onboarding.
    ///
    /// - Throws: An error if the profile couldn't be stored.
    func completeOnboarding() async throws
}
