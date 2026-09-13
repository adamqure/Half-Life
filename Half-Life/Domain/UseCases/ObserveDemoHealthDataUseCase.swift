//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life ObserveDemoHealthDataUseCase
//

/// Streams whether the demo Health data switch is on, starting with the current answer.
///
/// Settings' demo Health data switch observes it. The Apple Health Card article lists its requirement, HUSE-2.
struct ObserveDemoHealthDataUseCase: UseCase {
    /// The repository that holds the switch.
    let repository: any HealthDataRepository

    /// Returns a stream of whether the switch is on: the current answer, then each change.
    func execute(_: Void) -> AsyncStream<Bool> {
        repository.usesDemoData()
    }
}
