//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SaveBedtimeUseCase
//

/// Saves when the user wants to be asleep.
///
/// The decay card's level at bedtime follows it, through the data source the profile repository shares with the decay
/// repository. See the Onboarding article.
nonisolated struct SaveBedtimeUseCase: UseCase {
    /// The repository that stores the profile.
    let repository: any UserProfileRepository

    /// Saves the bedtime.
    ///
    /// - Parameter input: The bedtime.
    /// - Throws: The repository's error if the profile couldn't be stored.
    func execute(_ input: Bedtime) async throws {
        try await repository.saveBedtime(input)
    }
}
