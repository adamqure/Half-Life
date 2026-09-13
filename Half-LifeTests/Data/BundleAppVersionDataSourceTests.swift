//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests BundleAppVersionDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the bundle's version data source against VER-1 and VER-2 in the Settings article.
struct BundleAppVersionDataSourceTests {

    // MARK: - VER-1: the version and build are the Info.plist's, and there's none without both

    @Test func readsTheVersionAndBuildFromTheInfoPlist() {
        let info = ["CFBundleShortVersionString": "1.2", "CFBundleVersion": "34"]
        let dataSource = BundleAppVersionDataSource(infoValue: { info[$0] })

        #expect(dataSource.appVersion() == AppVersion(version: "1.2", build: "34"))
    }

    @Test(arguments: ["CFBundleShortVersionString", "CFBundleVersion"])
    func hasNoVersionWithoutBothKeys(missing: String) {
        let info = ["CFBundleShortVersionString": "1.2", "CFBundleVersion": "34"].filter { $0.key != missing }
        let dataSource = BundleAppVersionDataSource(infoValue: { info[$0] })

        #expect(dataSource.appVersion() == nil)
    }

    // MARK: - VER-2: by default, it reads the app's own bundle

    @Test func readsTheAppsOwnBundleByDefault() throws {
        let version = try #require(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        let build = try #require(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)

        #expect(BundleAppVersionDataSource().appVersion() == AppVersion(version: version, build: build))
    }
}
