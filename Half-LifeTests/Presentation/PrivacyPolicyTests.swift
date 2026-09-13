//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests PrivacyPolicyTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the address Settings' privacy policy link opens (PRIVACY-1 in the Settings article).
struct PrivacyPolicyTests {

    /// PRIVACY-1: the link opens `PRIVACY.md` on the public repository's main branch, the address App Store Connect
    /// gives too.
    @Test func theLinkOpensThePolicyInTheRepository() {
        #expect(PrivacyPolicy.url == URL(string: "https://github.com/adamqure/Half-Life/blob/main/PRIVACY.md"))
    }
}
