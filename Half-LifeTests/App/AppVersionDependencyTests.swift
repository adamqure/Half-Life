//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests AppVersionDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the app version's registrations (DEP-VER in the Settings article).
struct AppVersionDependencyTests {

    /// In previews, as live, the use case streams the app bundle's own version.
    @Test func previewUseCaseStreamsTheAppsOwnVersion() async throws {
        let version = try #require(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        let build = try #require(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
        let observeAppVersion = withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.observeAppVersion) var observeAppVersion
            return observeAppVersion
        }

        var received: [AppVersion] = []
        for await published in observeAppVersion.execute(()) {
            received.append(published)
        }

        #expect(received == [AppVersion(version: version, build: build)])
    }

    /// Using the use case in a test that hasn't overridden it reports an issue.
    @Test func testUseCaseReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeAppVersion) var observeAppVersion
            for await _ in observeAppVersion.execute(()) {}
        }
    }
}
