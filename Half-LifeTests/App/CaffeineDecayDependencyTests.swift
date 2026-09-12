//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineDecayDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// The error a store that won't open throws, for the data source's fallback test.
private struct StoreDidNotOpen: Error {}

/// Checks the decay curve's test registrations (constitution Article I.15). None of these tests opens a store.
///
/// The live values aren't read in tests, because the live data source opens the device's store with CloudKit.
struct CaffeineDecayDependencyTests {

    /// A test that observes the curve without overriding the repository fails.
    @Test func testCaffeineDecayRepositoryReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.caffeineDecayRepository) var repository
            for await _ in repository.curve() {}
        }
    }

    /// A test that observes the curve without overriding the use case fails.
    @Test func testObserveCaffeineCurveReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeCaffeineCurve) var observeCaffeineCurve
            for await _ in observeCaffeineCurve.execute(()) {}
        }
    }

    /// A test that reaches the drink log data source without overriding a repository fails, whatever it does.
    @Test func testDrinkLogDataSourceReportsAnIssueForEveryOperation() async {
        let source = DrinkLogDataSourceKey.testValue
        let drink = LoggedDrink(type: .espresso, quantity: 1, milligrams: 64, consumedAt: Date())

        await withKnownIssue {
            try await source.store(drink)
        }
        await withKnownIssue {
            _ = try await source.drinks()
        }
        await withKnownIssue {
            _ = try await source.nonNegligibleDrinks()
        }
        await withKnownIssue {
            try await source.markNegligible([drink.intake])
        }
        await withKnownIssue {
            for await _ in await source.changes() {}
        }
    }
}

extension SwiftDataStoreTests {

    /// Checks the preview registrations, which open an empty in-memory store. It runs inside the serialized
    /// `SwiftDataStoreTests`, because it opens a store.
    @Suite(.timeLimit(.minutes(1)))
    struct CaffeineDecayPreviewDependencyTests {

        @Test func previewRepositoryIsTheLiveRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.caffeineDecayRepository) var repository
                #expect(repository is LiveCaffeineDecayRepository)
            }
        }

        @Test func previewObserveCaffeineCurveUsesTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.caffeineDecayRepository) var repository
                @Dependency(\.observeCaffeineCurve) var observeCaffeineCurve
                #expect((observeCaffeineCurve.repository as AnyObject) === (repository as AnyObject))
            }
        }

        /// The preview repository runs end to end: SwiftData, the standard half-life, the system clock, and the rule.
        @Test func previewRepositoryPublishesAWholeCurve() async throws {
            let repository = withDependencies {
                $0.context = .preview
            } operation: { () -> any CaffeineDecayRepository in
                @Dependency(\.caffeineDecayRepository) var repository
                return repository
            }

            var curves = repository.curve().makeAsyncIterator()
            let curve = try #require(await curves.next())

            #expect(curve.count == CaffeineDecayRule.sampleCount)
        }
    }

    /// Checks how the shared drink log data source is made. It runs inside the serialized `SwiftDataStoreTests`,
    /// because it opens stores.
    @Suite struct DrinkLogDataSourceKeyTests {

        static let drink = LoggedDrink(
            type: .espresso, quantity: 1, milligrams: 64, consumedAt: Date(timeIntervalSinceReferenceDate: 0))

        @Test func dataSourceUsesTheStoreItOpens() async throws {
            let container = try SwiftDataDrinkLogDataSource.makeModelContainer(isStoredInMemoryOnly: true)

            let source = DrinkLogDataSourceKey.makeDataSource { container }
            try await source.store(Self.drink)

            #expect(try await SwiftDataDrinkLogDataSource(modelContainer: container).drinks() == [Self.drink])
        }

        /// If the device's store can't be opened, the app still works this launch, on an in-memory store.
        @Test func dataSourceFallsBackToAnInMemoryStoreWhenTheStoreDoesntOpen() async throws {
            let source = DrinkLogDataSourceKey.makeDataSource { throw StoreDidNotOpen() }
            try await source.store(Self.drink)

            #expect(try await source.drinks() == [Self.drink])
        }

        @Test func previewDataSourceIsASwiftDataStore() {
            #expect(DrinkLogDataSourceKey.previewValue is SwiftDataDrinkLogDataSource)
        }
    }
}
