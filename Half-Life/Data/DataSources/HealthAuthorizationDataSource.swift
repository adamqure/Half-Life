//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthAuthorizationDataSource
//

/// Reads and requests Half-Life's access to Apple Health.
///
/// An implementation is the only data source that requests Health access (constitution Article V.3.1). The data
/// sources that read sleep, steps, and heart rate never request it themselves. See the Onboarding article.
protocol HealthAuthorizationDataSource: Sendable {
    /// Returns whether Half-Life has asked to read the Health types its features read.
    func status() async -> HealthAccessStatus

    /// Asks to read the Health types Half-Life's features read, in one sheet, if the sheet hasn't been shown for them.
    ///
    /// - Throws: An error if the request couldn't be made. The user denying access isn't an error.
    func requestAccess() async throws
}
