//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveRecommendedSleepUseCase
//

import Foundation

/// Streams the nightly sleep recommended for the user's age.
///
/// See the Onboarding article's SleepNeedRule.
nonisolated struct ObserveRecommendedSleepUseCase: UseCase {
    /// The repository that owns the profile.
    let repository: any UserProfileRepository

    /// Returns a stream of the recommended sleep: the current range, then one after each change to the profile.
    ///
    /// - Parameter input: The calendar whose year the user's age is counted in.
    func execute(_ input: Calendar) -> AsyncStream<RecommendedSleep> {
        repository.recommendedSleep(in: input)
    }
}
