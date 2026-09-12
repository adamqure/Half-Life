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

/// Reads the user's bedtime from storage.
///
/// An implementation is the only code that touches where the bedtime is stored (constitution Article I.14).
/// ``LiveCaffeineDecayRepository`` reads it. The Today Screen article lists its requirement, BEDSRC-1.
protocol BedtimeDataSource: Sendable {
    /// Returns the current bedtime: the stored one, or ``Bedtime/standard`` when nothing is stored.
    ///
    /// - Throws: An error if a stored bedtime couldn't be read.
    func bedtime() async throws -> Bedtime
}
