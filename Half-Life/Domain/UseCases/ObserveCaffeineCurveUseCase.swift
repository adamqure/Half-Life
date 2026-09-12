//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveCaffeineCurveUseCase
//

/// Streams the active caffeine curve, starting with one calculated for the current time.
nonisolated struct ObserveCaffeineCurveUseCase: UseCase {
    /// The repository that owns the curve.
    let repository: any CaffeineDecayRepository

    /// Returns a stream of the active curve: one calculated for the current time, then a new one after every
    /// change to the data it comes from.
    ///
    /// - Parameter input: Nothing. Observing the curve takes no input.
    func execute(_ input: Void) -> AsyncStream<[CaffeineLevel]> {
        repository.curve()
    }
}
