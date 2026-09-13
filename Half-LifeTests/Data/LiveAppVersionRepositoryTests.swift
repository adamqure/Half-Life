//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveAppVersionRepositoryTests
//

import Testing

@testable import Half_Life

/// Checks the app version repository against VERREPO-1 in the Settings article.
struct LiveAppVersionRepositoryTests {

    static func collect(_ stream: AsyncStream<AppVersion>) async -> [AppVersion] {
        var received: [AppVersion] = []
        for await version in stream {
            received.append(version)
        }
        return received
    }

    // MARK: - VERREPO-1: the stream sends the data source's version once, then finishes, because it never changes

    @Test func streamsTheDataSourcesVersionOnceThenFinishes() async {
        let version = AppVersion(version: "1.2", build: "34")
        let repository = LiveAppVersionRepository(dataSource: FakeAppVersionDataSource(version: version))

        #expect(await Self.collect(repository.appVersion()) == [version])
    }

    @Test func streamsNothingWithoutAVersion() async {
        let repository = LiveAppVersionRepository(dataSource: FakeAppVersionDataSource(version: nil))

        #expect(await Self.collect(repository.appVersion()).isEmpty)
    }
}
