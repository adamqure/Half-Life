//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveCutoffWarningUseCaseTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the cutoff warning's use case and registration: OBSWARN-1 and DEP-WARN in the Caffeine Cutoff article.
struct ObserveCutoffWarningUseCaseTests {

    static let latte = FavouriteDrink(type: .latte, quantity: 2)
    static let warning = CutoffWarning.stillRisingAtBedtime(bedtime: Date(timeIntervalSinceReferenceDate: 22.5 * 3_600))

    /// OBSWARN-1: it streams every warning the repository publishes for the drink, how long ago, and the calendar.
    @Test func streamsTheWarningsTheRepositoryPublishesForTheDrink() async throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let tokyoTimeZone = tokyo.timeZone
        let repository = FakeCaffeineDecayRepository(warnings: { drink, secondsAgo, calendar in
            drink == Self.latte && secondsAgo == 3_600 && calendar.timeZone == tokyoTimeZone ? [nil, Self.warning] : []
        })
        let observe = ObserveCutoffWarningUseCase(repository: repository)

        var received: [CutoffWarning?] = []
        let input = ObserveCutoffWarningUseCase.Input(drink: Self.latte, secondsAgo: 3_600, calendar: tokyo)
        for await warning in try await executeThroughProtocol(observe, input) {
            received.append(warning)
        }

        #expect(received == [nil, Self.warning])
    }

    /// DEP-WARN: a test that observes the warning without overriding the use case fails.
    @Test func testObserveCutoffWarningReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeCutoffWarning) var observeCutoffWarning
            let input = ObserveCutoffWarningUseCase.Input(
                drink: Self.latte, secondsAgo: 0, calendar: Calendar(identifier: .gregorian))
            for await _ in observeCutoffWarning.execute(input) {}
        }
    }
}

extension SwiftDataStoreTests {

    /// Checks the cutoff warning's preview registration, which opens an empty in-memory store. It runs inside the
    /// serialized `SwiftDataStoreTests`, because it opens a store.
    @Suite(.timeLimit(.minutes(1)))
    struct CutoffWarningPreviewDependencyTests {

        /// DEP-WARN: observing the warning uses the one app-scoped decay repository.
        @Test func previewObserveCutoffWarningUsesTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.caffeineDecayRepository) var repository
                @Dependency(\.observeCutoffWarning) var observeCutoffWarning
                #expect((observeCutoffWarning.repository as AnyObject) === (repository as AnyObject))
            }
        }
    }
}
