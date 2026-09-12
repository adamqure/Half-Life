//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life Biometry
//

/// The kind of biometric authentication a device has.
///
/// The permissions step names its row after it, because iOS 26 still runs on iPhones with Touch ID. See the
/// Onboarding article.
nonisolated enum Biometry: Sendable, Equatable {
    /// Face ID.
    case faceID
    /// Touch ID.
    case touchID
    /// Optic ID, which only Apple Vision Pro has.
    case opticID
}
