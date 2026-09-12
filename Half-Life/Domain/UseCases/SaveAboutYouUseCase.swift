//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SaveAboutYouUseCase
//

import Foundation

/// Saves the name and age the user gave in onboarding's About you step.
///
/// The name is trimmed, and a blank one is saved as none. The age is saved as the birth year it implies: the
/// current year, in the given calendar, minus the age. See the Onboarding article.
nonisolated struct SaveAboutYouUseCase: UseCase {
    /// What the user entered.
    struct Input: Sendable, Equatable {
        /// The name as typed, or `nil`.
        let name: String?
        /// The age in years, or `nil` if the user preferred not to say.
        let age: Int?
        /// The calendar whose current year the age is counted back from.
        let calendar: Calendar
    }

    /// The repository that supplies the current time.
    let currentTime: any CurrentTimeRepository
    /// The repository that stores the profile.
    let profile: any UserProfileRepository

    /// Saves the trimmed name and the birth year the age implies.
    ///
    /// - Parameter input: What the user entered.
    /// - Throws: The repository's error if the profile couldn't be stored.
    func execute(_ input: Input) async throws {
        let trimmed = input.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let birthYear = input.age.map { input.calendar.component(.year, from: currentTime.now()) - $0 }
        try await profile.saveAboutYou(name: trimmed.isEmpty ? nil : trimmed, birthYear: birthYear)
    }
}
