//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DemoHealthDataFlagDataSource
//

/// Stores whether the demo Health data switch is on.
///
/// ``HealthDataRepository`` reads it to choose between Apple Health and the demo data sources. It's the app's feature
/// flag for the demo, not the user's data. The Apple Health Card article lists its requirements, DEMOFLAG-1 to
/// DEMOFLAG-3.
protocol DemoHealthDataFlagDataSource: Sendable {
    /// Returns whether the switch is on. It's off until a value is stored.
    ///
    /// - Throws: An error if the stored value couldn't be read.
    func usesDemoData() async throws -> Bool

    /// Stores whether the switch is on, and signals each subscriber if the value changed.
    ///
    /// - Parameter isOn: Whether the switch is on.
    /// - Throws: An error if the value couldn't be stored. Nothing is signalled then.
    func setUsesDemoData(_ isOn: Bool) async throws

    /// Returns a stream for one subscriber that yields after each change to the switch. It ends when its subscriber
    /// stops listening.
    func changes() async -> AsyncStream<Void>
}
