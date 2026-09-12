//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SaveHalfLifeFactorsUseCase
//

/// Saves what the user said changes how fast they clear caffeine.
///
/// The repository derives the starting half-life from the factors and stores it with them. See the Onboarding article.
nonisolated struct SaveHalfLifeFactorsUseCase: UseCase {
    /// The repository that stores the profile.
    let repository: any UserProfileRepository

    /// Saves the factors.
    ///
    /// - Parameter input: The factors the user chose. Empty means none of them.
    /// - Throws: The repository's error if the profile couldn't be stored.
    func execute(_ input: Set<HalfLifeFactor>) async throws {
        try await repository.saveHalfLifeFactors(input)
    }
}
