//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life KeepSleepToleranceCurrentUseCase
//

/// Keeps the user's caffeine tolerance, and so the sleep threshold, current for as long as it runs.
///
/// Subscribing to ``SleepToleranceRepository/analysis()`` keeps the repository listening for changes, and each change
/// stores the new tolerance, which the cutoff reads. ``AppFeature`` runs it from launch, so the cutoff follows the
/// user's nights without the Sleep screen being open. See TOLUSE-2 in the Insights article.
struct KeepSleepToleranceCurrentUseCase: UseCase {
    /// The repository that stores the tolerance.
    let repository: any SleepToleranceRepository

    /// Subscribes to the analysis until the stream ends or the task is cancelled.
    ///
    /// - Parameter input: None.
    func execute(_ input: Void) async {
        for await _ in repository.analysis() {}
    }
}
