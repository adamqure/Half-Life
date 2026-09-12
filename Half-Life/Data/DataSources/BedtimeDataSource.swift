//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life BedtimeDataSource
//

/// Supplies the user's bedtime to ``CaffeineDecayRepository``, and signals when it changes.
///
/// ``FileProfileDataSource`` implements it from the stored profile. See the Onboarding article, BEDSRC-1.
protocol BedtimeDataSource: Sendable {
    /// Returns the current bedtime: the stored one, or ``Bedtime/standard`` when nothing is stored.
    ///
    /// - Throws: An error if a stored bedtime couldn't be read.
    func bedtime() async throws -> Bedtime

    /// Returns a stream that yields once after each change that could change the bedtime.
    func changes() async -> AsyncStream<Void>
}
