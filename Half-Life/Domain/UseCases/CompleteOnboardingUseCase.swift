//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CompleteOnboardingUseCase
//

/// Records that the user has finished onboarding.
///
/// The root dismisses onboarding when the profile it observes says so. See the Onboarding article.
nonisolated struct CompleteOnboardingUseCase: UseCase {
    /// The repository that stores the profile.
    let repository: any UserProfileRepository

    /// Records the completion.
    ///
    /// - Parameter input: Nothing.
    /// - Throws: The repository's error if the profile couldn't be stored.
    func execute(_ input: Void) async throws {
        try await repository.completeOnboarding()
    }
}
