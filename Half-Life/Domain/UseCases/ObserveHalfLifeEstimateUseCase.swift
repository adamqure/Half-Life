//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveHalfLifeEstimateUseCase
//

/// Streams the user's personal half-life estimate, starting with the current one.
///
/// No feature shows the estimate yet. See the Half-Life Estimator article.
nonisolated struct ObserveHalfLifeEstimateUseCase: UseCase {
    /// The repository that owns the estimate.
    let repository: any HalfLifeEstimateRepository

    /// Returns a stream of the estimate: the current one, then each recalculated one.
    ///
    /// - Parameter input: Nothing. Observing the estimate takes no input.
    func execute(_ input: Void) -> AsyncStream<HalfLifeEstimate> {
        repository.estimate()
    }
}
