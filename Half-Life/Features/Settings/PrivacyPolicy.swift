//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life PrivacyPolicy
//

import Foundation

/// Where Half-Life's privacy policy is published: `PRIVACY.md` in the app's public repository.
///
/// Settings' root links to it, and App Store Connect gives the same address (App Review Guideline 5.1.1(i)). See the
/// Settings article, PRIVACY-1.
enum PrivacyPolicy {
    // swiftlint:disable force_unwrapping
    /// The policy's address on GitHub.
    ///
    /// It's a fixed address that's a valid URL, so creating it can't fail (constitution Article IV.2).
    static let url = URL(string: "https://github.com/adamqure/Half-Life/blob/main/PRIVACY.md")!
    // swiftlint:enable force_unwrapping
}
