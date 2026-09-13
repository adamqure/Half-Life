//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life RefreshHalfLifeEstimateUseCase
//

/// Recalculates the user's personal half-life estimate if it's due: when none is stored, when it's a week old, or when
/// the survey's starting half-life has changed.
///
/// The decay card runs it when it appears. See the Half-Life Estimator article.
nonisolated struct RefreshHalfLifeEstimateUseCase: UseCase {
    /// The repository that owns the estimate.
    let repository: any HalfLifeEstimateRepository

    /// Refreshes the estimate. The repository publishes it if it recalculated.
    ///
    /// - Parameter input: Nothing.
    func execute(_ input: Void) async {
        await repository.refresh()
    }
}
