//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeUserProfileRepository
//

import Foundation

@testable import Half_Life

/// An in-memory user profile repository for use case and reducer tests.
///
/// It streams the profiles and recommended sleep it was given, then finishes, and records every save. It's an actor,
/// like the live repositories.
actor FakeUserProfileRepository: UserProfileRepository {
    /// One call to `saveAboutYou(name:birthYear:)`.
    struct SavedAboutYou: Equatable, Sendable {
        let name: String?
        let birthYear: Int?
    }

    /// The profiles that `profile()` streams, in order.
    let profiles: [UserProfile]
    /// The ranges that `recommendedSleep(in:)` streams, in order.
    let recommendedSleeps: [RecommendedSleep]
    /// The calendar `recommendedSleep(in:)` expects. Given any other, it streams nothing.
    let sleepCalendar: Calendar?
    /// The error every save throws, if any.
    let error: (any Error)?

    private(set) var savedAboutYou: [SavedAboutYou] = []
    private(set) var savedFactors: [Set<HalfLifeFactor>] = []
    private(set) var savedBedtimes: [Bedtime] = []
    private(set) var completeCount = 0

    init(
        profiles: [UserProfile] = [], recommendedSleeps: [RecommendedSleep] = [], sleepCalendar: Calendar? = nil,
        error: (any Error)? = nil
    ) {
        self.profiles = profiles
        self.recommendedSleeps = recommendedSleeps
        self.sleepCalendar = sleepCalendar
        self.error = error
    }

    nonisolated func profile() -> AsyncStream<UserProfile> {
        AsyncStream { continuation in
            for profile in profiles {
                continuation.yield(profile)
            }
            continuation.finish()
        }
    }

    nonisolated func recommendedSleep(in calendar: Calendar) -> AsyncStream<RecommendedSleep> {
        let ranges = sleepCalendar.map { $0 == calendar } ?? true ? recommendedSleeps : []
        return AsyncStream { continuation in
            for range in ranges {
                continuation.yield(range)
            }
            continuation.finish()
        }
    }

    func saveAboutYou(name: String?, birthYear: Int?) throws {
        if let error { throw error }
        savedAboutYou.append(SavedAboutYou(name: name, birthYear: birthYear))
    }

    func saveHalfLifeFactors(_ factors: Set<HalfLifeFactor>) throws {
        if let error { throw error }
        savedFactors.append(factors)
    }

    func saveBedtime(_ bedtime: Bedtime) throws {
        if let error { throw error }
        savedBedtimes.append(bedtime)
    }

    func completeOnboarding() throws {
        if let error { throw error }
        completeCount += 1
    }
}
