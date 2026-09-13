//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SetDemoHealthDataUseCase
//

/// Turns the demo Health data switch on or off.
///
/// Settings' demo Health data switch runs it. The new answer reaches the switch, and the Apple Health card, through
/// the repository's streams. The Apple Health Card article lists its requirement, HUSE-2.
struct SetDemoHealthDataUseCase: UseCase {
    /// The repository that holds the switch.
    let repository: any HealthDataRepository

    /// Turns the switch on or off.
    ///
    /// - Parameter isOn: Whether to show demo Health data in place of Apple Health's.
    /// - Throws: The repository's error if the switch couldn't be stored.
    func execute(_ isOn: Bool) async throws {
        try await repository.setUsesDemoData(isOn)
    }
}
