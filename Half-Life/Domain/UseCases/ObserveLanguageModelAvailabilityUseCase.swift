//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveLanguageModelAvailabilityUseCase
//

/// Streams whether the on-device language model can be used, so a feature that uses it can hide while it can't.
///
/// See OBSLM-1 in the Language Model article.
struct ObserveLanguageModelAvailabilityUseCase: UseCase {
    /// The repository that owns the availability.
    let repository: any LanguageModelRepository

    /// Streams the availability: the current one first, then each change.
    func execute(_ input: Void) -> AsyncStream<LanguageModelAvailability> {
        repository.availability()
    }
}
