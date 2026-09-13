//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveSleepCaffeineAnalysisUseCase
//

import Foundation

/// Streams the analysis of the user's nights in the last 30 days against the caffeine at sleep onset: the Insights
/// tab's Sleep screen, and "What we noticed".
///
/// ``SleepToleranceRepository`` finds it with ``SleepToleranceRule``. See TOLUSE-1 in the Insights article.
struct ObserveSleepCaffeineAnalysisUseCase: UseCase {
    /// The repository that owns the analysis.
    let repository: any SleepToleranceRepository

    /// Returns a stream of the analysis: the current one, then each change.
    ///
    /// - Parameter input: None.
    func execute(_ input: Void) -> AsyncStream<SleepCaffeineAnalysis> {
        repository.analysis()
    }
}
