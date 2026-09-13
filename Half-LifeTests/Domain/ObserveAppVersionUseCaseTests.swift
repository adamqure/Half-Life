//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveAppVersionUseCaseTests
//

import Testing

@testable import Half_Life

/// Checks that observing the app's version streams what the repository publishes (VERUSE-1 in the Settings article).
struct ObserveAppVersionUseCaseTests {

    @Test func streamsTheVersionTheRepositoryPublishes() async throws {
        let version = AppVersion(version: "1.2", build: "34")
        let observe = ObserveAppVersionUseCase(repository: FakeAppVersionRepository(versions: [version]))

        var received: [AppVersion] = []
        for await published in try await executeThroughProtocol(observe, ()) {
            received.append(published)
        }

        #expect(received == [version])
    }
}
