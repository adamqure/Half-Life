//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthAccessStatus
//

/// Whether Half-Life has asked to read Apple Health.
///
/// HealthKit never tells an app whether the user allowed it to read a type, so there's no "allowed" case: the app
/// only knows whether it has asked. See the Onboarding article, PERM-2.
nonisolated enum HealthAccessStatus: Sendable, Equatable {
    /// Half-Life hasn't asked yet, so asking shows Health's sheet.
    case notRequested
    /// Half-Life has asked. The user may have allowed or denied any of the types.
    case requested
    /// The device has no Apple Health.
    case unavailable
}
