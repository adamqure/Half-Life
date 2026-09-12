//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life StandardBedtimeDataSource
//

/// The bedtime data source until the user can set their own bedtime.
///
/// Nothing can store a bedtime yet, so the current one is always ``Bedtime/standard`` (BEDSRC-1). The onboarding
/// survey and Settings (roadmap ranks 6 and 21) replace it with a source that stores one.
struct StandardBedtimeDataSource: BedtimeDataSource {
    /// Returns ``Bedtime/standard``.
    func bedtime() -> Bedtime {
        .standard
    }
}
