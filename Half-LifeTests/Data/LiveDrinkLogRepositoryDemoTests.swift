//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveDrinkLogRepositoryDemoTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live drink log repository's demo history against DEMOREPO-1 to DEMOREPO-4 in the Settings article, with
/// a fake drink log data source and a stopped clock. The time limit turns an answer that never arrives into a failure
/// instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct LiveDrinkLogRepositoryDemoTests {

    struct DataSourceFailed: Error {}

    /// 8:00pm UTC on 2026-09-12.
    static let now = Date(timeIntervalSince1970: 1_789_243_200)
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    static let own = LoggedDrink(type: .cola, quantity: 1, milligrams: 34, consumedAt: now.addingTimeInterval(-3_600))
    static let oldDemo = LoggedDrink(
        type: .espresso, quantity: 1, milligrams: 62.7, consumedAt: now.addingTimeInterval(-7_200), isDemo: true)

    static func repository(_ source: FakeDrinkLogDataSource) -> LiveDrinkLogRepository {
        LiveDrinkLogRepository(dataSource: source, clock: FakeClockDataSource(date: now, minuteDates: []))
    }

    /// Everything about each drink but its identifier, which the rule makes new each time.
    static func contents(_ drinks: [LoggedDrink]) -> [String] {
        drinks.sorted { $0.consumedAt < $1.consumedAt }.map { drink in
            "\(drink.type) ×\(drink.quantity) \(drink.milligrams) mg at \(drink.consumedAt) demo \(drink.isDemo)"
        }
    }

    // MARK: - DEMOREPO-1: adding stores the rule's drinks for now in place of the old demo drinks

    @Test func addingStoresTheRulesDrinksForNowAndKeepsTheUsersOwn() async throws {
        let source = FakeDrinkLogDataSource(drinks: [Self.own, Self.oldDemo])

        try await Self.repository(source).addDemoHistory(in: Self.utc)

        let held = await source.heldDrinks
        #expect(held.filter { !$0.isDemo } == [Self.own])
        #expect(
            Self.contents(held.filter(\.isDemo))
                == Self.contents(DemoHistoryRule().drinks(now: Self.now, calendar: Self.utc)))
    }

    // MARK: - DEMOREPO-2: removing deletes only the demo drinks

    @Test func removingDeletesOnlyTheDemoDrinks() async throws {
        let source = FakeDrinkLogDataSource(drinks: [Self.own, Self.oldDemo])

        try await Self.repository(source).removeDemoHistory()

        #expect(await source.heldDrinks == [Self.own])
    }

    // MARK: - DEMOREPO-3: the answer starts with the current one, then comes only when it changes

    @Test func aNewSubscriberGetsTheCurrentAnswer() async throws {
        var withDemo = Self.repository(FakeDrinkLogDataSource(drinks: [Self.own, Self.oldDemo]))
            .hasDemoHistory().makeAsyncIterator()
        var withoutDemo = Self.repository(FakeDrinkLogDataSource(drinks: [Self.own]))
            .hasDemoHistory().makeAsyncIterator()

        #expect(await withDemo.next() == true)
        #expect(await withoutDemo.next() == false)
    }

    @Test func theAnswerFollowsChangesAndComesOnlyWhenItChanges() async throws {
        let source = FakeDrinkLogDataSource(drinks: [Self.own])
        let repository = Self.repository(source)
        var answers = repository.hasDemoHistory().makeAsyncIterator()
        #expect(await answers.next() == false)

        try await repository.addDemoHistory(in: Self.utc)
        #expect(await answers.next() == true)

        // Logging one of the user's own drinks doesn't change the answer, so nothing is sent for it.
        try await repository.log(
            LoggedDrink(type: .cola, quantity: 1, milligrams: 34, consumedAt: Self.now.addingTimeInterval(-60)))
        try await repository.removeDemoHistory()
        #expect(await answers.next() == false)
    }

    // MARK: - DEMOREPO-4: a failed replacement throws, and nothing changes

    @Test func aFailedReplacementThrowsAndChangesNothing() async {
        let source = FakeDrinkLogDataSource(drinks: [Self.own, Self.oldDemo])
        await source.failDemoReplacements(with: DataSourceFailed())
        let repository = Self.repository(source)

        await #expect(throws: DataSourceFailed.self) {
            try await repository.addDemoHistory(in: Self.utc)
        }
        await #expect(throws: DataSourceFailed.self) {
            try await repository.removeDemoHistory()
        }
        #expect(await source.heldDrinks == [Self.own, Self.oldDemo])
    }
}
