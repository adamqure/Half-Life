//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DemoHistoryDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the demo history's registrations (DEP-DEMO in the Settings article).
struct DemoHistoryDependencyTests {

    /// Each demo history use case holds the one app-scoped drink log repository.
    @Test func previewDemoHistoryUseCasesUseTheAppScopedRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.drinkLogRepository) var repository
            @Dependency(\.addDemoHistory) var addDemoHistory
            @Dependency(\.removeDemoHistory) var removeDemoHistory
            @Dependency(\.observeDemoHistory) var observeDemoHistory

            #expect((addDemoHistory.drinkLog as AnyObject) === (repository as AnyObject))
            #expect((removeDemoHistory.drinkLog as AnyObject) === (repository as AnyObject))
            #expect((observeDemoHistory.drinkLog as AnyObject) === (repository as AnyObject))
        }
    }

    /// Using a demo history use case in a test that hasn't overridden it reports an issue.
    @Test func testUseCasesReportAnIssue() async {
        await withKnownIssue {
            @Dependency(\.addDemoHistory) var addDemoHistory
            try await addDemoHistory.execute(Calendar(identifier: .gregorian))
        }
        await withKnownIssue {
            @Dependency(\.removeDemoHistory) var removeDemoHistory
            try await removeDemoHistory.execute(())
        }
        await withKnownIssue {
            @Dependency(\.observeDemoHistory) var observeDemoHistory
            for await _ in observeDemoHistory.execute(()) {}
        }
    }

    /// Replacing the demo drinks through the drink log data source in a test reports an issue.
    @Test func testDataSourceReportsAnIssueForADemoReplacement() async {
        await withKnownIssue {
            try await DrinkLogDataSourceKey.testValue.replaceDemoDrinks(with: [])
        }
    }
}
