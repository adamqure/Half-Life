//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkLogUITestStoreTests
//

import Foundation
import SwiftData
import Testing

@testable import Half_Life

extension SwiftDataStoreTests {

    /// Checks the drink log data source that a UI test's launch gets (LAUNCH-3 in the Onboarding article). It runs
    /// inside the serialized `SwiftDataStoreTests`, because it opens a store. It never opens the device's store: the
    /// configuration outside UI tests isn't tested, because that one would.
    @Suite struct DrinkLogUITestStoreTests {

        /// LAUNCH-3: when a UI test launches the app, the drink log is an empty store that lives only in memory, so
        /// every UI test starts from the same log and never touches the simulator's own drinks.
        @Test(arguments: [LaunchEnvironmentKey.completed, LaunchEnvironmentKey.fresh])
        func aUITestLaunchGetsAnEmptyInMemoryDrinkLog(profile: String) async throws {
            let configuration = UITestLaunchConfiguration(environment: [LaunchEnvironmentKey.profile: profile])

            let source = DrinkLogDataSourceKey.makeLiveValue(configuration: configuration)

            let isInMemory = source.modelContainer.configurations.allSatisfy(\.isStoredInMemoryOnly)
            #expect(isInMemory)
            #expect(try await source.drinks().isEmpty)
        }
    }
}
