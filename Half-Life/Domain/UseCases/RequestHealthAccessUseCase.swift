//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RequestHealthAccessUseCase
//

/// Asks, in Health's sheet, to read sleep, steps, and resting heart rate.
///
/// It's how onboarding's permissions step asks for Health access when the user taps Allow (constitution Article
/// V.3.1). See the Onboarding article.
nonisolated struct RequestHealthAccessUseCase: UseCase {
    /// The repository that owns the permissions.
    let repository: any PermissionsRepository

    /// Asks for Health access.
    ///
    /// - Parameter input: Nothing. The types asked for are the ones Half-Life's features read.
    /// - Throws: The repository's error if the request couldn't be made.
    func execute(_ input: Void) async throws {
        try await repository.requestHealthAccess()
    }
}
