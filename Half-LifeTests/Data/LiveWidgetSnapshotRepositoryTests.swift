//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveWidgetSnapshotRepositoryTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the live widget snapshot repository against WSREPO-1 to WSREPO-3 in the Widgets article, with fake data
/// sources. The time limit turns a snapshot that never arrives into a failure instead of a hang.
@Suite(.timeLimit(.minutes(1)))
struct LiveWidgetSnapshotRepositoryTests {

    struct DataSourceFailed: Error {}

    static let now = Date(timeIntervalSinceReferenceDate: 800_001_130)

    /// The repository and the fakes behind it.
    struct Harness {
        let drinkLog: FakeDrinkLogDataSource
        let profile: FakeUserProfileDataSource
        let halfLife: FakeHalfLifeDataSource
        let snapshots: FakeWidgetSnapshotDataSource
        let widgets: FakeWidgetReloadDataSource
        let events: Recorded<[String]>
        let repository: LiveWidgetSnapshotRepository
    }

    static func harness(
        drinks: [LoggedDrink] = [], profile: UserProfile? = UserProfile(hasCompletedOnboarding: true),
        storeError: (any Error)? = nil
    ) -> Harness {
        let events = Recorded<[String]>([])
        let drinkLog = FakeDrinkLogDataSource(drinks: drinks)
        let profileSource = FakeUserProfileDataSource(stored: profile)
        let halfLife = FakeHalfLifeDataSource(value: .standard)
        let snapshots = FakeWidgetSnapshotDataSource(events: events, storeError: storeError)
        let widgets = FakeWidgetReloadDataSource(events: events)
        let repository = LiveWidgetSnapshotRepository(
            drinkLog: drinkLog, profile: profileSource, halfLife: halfLife,
            absorption: FakeAbsorptionRateDataSource(value: .standard),
            clock: FakeClockDataSource(date: now, minuteDates: []), snapshots: snapshots, widgets: widgets)
        return Harness(
            drinkLog: drinkLog, profile: profileSource, halfLife: halfLife, snapshots: snapshots, widgets: widgets,
            events: events, repository: repository)
    }

    static func drink(_ type: DrinkType, _ quantity: Int, minutesAgo: Double) -> LoggedDrink {
        LoggedDrink(
            type: type, quantity: quantity, milligrams: type.estimatedMilligrams(quantity: quantity),
            consumedAt: now.addingTimeInterval(-minutesAgo * 60))
    }

    static func expected(
        _ drinks: [LoggedDrink], bedtime: Bedtime = .standard, isOnboardingComplete: Bool = true,
        halfLife: CaffeineHalfLife = .standard
    ) -> WidgetSnapshot {
        WidgetSnapshotRule().snapshot(
            drinks: drinks, intakes: drinks.map(\.intake),
            kinetics: CaffeineKinetics(halfLife: halfLife, absorption: .standard),
            profile: UserProfile(bedtime: bedtime, hasCompletedOnboarding: isOnboardingComplete), now: now)
    }

    /// Waits until the repository is listening to the drink log's changes, so a signal can't be missed.
    static func waitUntilListening(_ drinkLog: FakeDrinkLogDataSource) async {
        while await drinkLog.subscriberCount == 0 {
            await Task.yield()
        }
    }

    // MARK: - WSREPO-1: a new subscriber gets the current snapshot, then a new one after each change

    @Test func aNewSubscriberGetsTheSnapshotForTheCurrentData() async throws {
        let drinks = [Self.drink(.latte, 2, minutesAgo: 90), Self.drink(.cola, 1, minutesAgo: 300)]
        let bedtime = try #require(Bedtime(hour: 23, minute: 0))
        let harness = Self.harness(drinks: drinks, profile: UserProfile(bedtime: bedtime, hasCompletedOnboarding: true))

        var snapshots = harness.repository.snapshots().makeAsyncIterator()

        #expect(try #require(await snapshots.next()) == Self.expected(drinks, bedtime: bedtime))
    }

    @Test func withNoProfileTheBedtimeIsTheStandardOneAndOnboardingIsIncomplete() async throws {
        let harness = Self.harness(profile: nil)

        var snapshots = harness.repository.snapshots().makeAsyncIterator()

        #expect(try #require(await snapshots.next()) == Self.expected([], isOnboardingComplete: false))
    }

    @Test func everySubscriberGetsANewSnapshotAfterADrinkIsLogged() async throws {
        let harness = Self.harness()
        var one = harness.repository.snapshots().makeAsyncIterator()
        var two = harness.repository.snapshots().makeAsyncIterator()
        _ = await one.next()
        _ = await two.next()
        let drink = Self.drink(.espresso, 2, minutesAgo: 5)

        await harness.drinkLog.insert(drink)
        await harness.drinkLog.signalChange()

        #expect(try #require(await one.next()) == Self.expected([drink]))
        #expect(try #require(await two.next()) == Self.expected([drink]))
    }

    @Test func aProfileChangePublishesANewSnapshot() async throws {
        let harness = Self.harness()
        var snapshots = harness.repository.snapshots().makeAsyncIterator()
        _ = await snapshots.next()
        let bedtime = try #require(Bedtime(hour: 21, minute: 45))

        await harness.profile.replace(with: UserProfile(bedtime: bedtime, hasCompletedOnboarding: true))
        await harness.profile.signalChange()

        #expect(try #require(await snapshots.next()) == Self.expected([], bedtime: bedtime))
    }

    @Test func aHalfLifeChangePublishesANewSnapshot() async throws {
        let drinks = [Self.drink(.coldBrew, 2, minutesAgo: 60)]
        let harness = Self.harness(drinks: drinks)
        var snapshots = harness.repository.snapshots().makeAsyncIterator()
        _ = await snapshots.next()
        let halfLife = try #require(CaffeineHalfLife(seconds: 3 * 60 * 60))

        await harness.halfLife.change(to: halfLife)

        #expect(try #require(await snapshots.next()) == Self.expected(drinks, halfLife: halfLife))
    }

    @Test func itListensToTheDrinkLogOnceForEverySubscriber() async throws {
        let harness = Self.harness()
        var one = harness.repository.snapshots().makeAsyncIterator()
        var two = harness.repository.snapshots().makeAsyncIterator()

        _ = await one.next()
        _ = await two.next()

        #expect(await harness.drinkLog.subscriberCount == 1)
    }

    // MARK: - WSREPO-2: each snapshot is stored, then the widgets reload

    @Test func eachSnapshotIsStoredAndThenTheWidgetsReload() async throws {
        let harness = Self.harness()
        var snapshots = harness.repository.snapshots().makeAsyncIterator()

        let first = try #require(await snapshots.next())

        #expect(harness.events.value == ["store", "reload"])
        #expect(await harness.snapshots.stored == first)

        let drink = Self.drink(.matcha, 1, minutesAgo: 1)
        await harness.drinkLog.insert(drink)
        await harness.drinkLog.signalChange()
        let second = try #require(await snapshots.next())

        #expect(harness.events.value == ["store", "reload", "store", "reload"])
        #expect(await harness.snapshots.stored == second)
    }

    // MARK: - WSREPO-3: a failure publishes nothing and reloads nothing, and the next change recovers

    @Test func aFailedReadPublishesNothingUntilTheDrinksCanBeRead() async throws {
        let harness = Self.harness()
        await harness.drinkLog.failReads(with: DataSourceFailed())
        let collected = Collected(harness.repository.snapshots())
        defer { collected.cancel() }
        await Self.waitUntilListening(harness.drinkLog)

        #expect(await collected.settled().isEmpty)
        #expect(harness.events.value.isEmpty)

        await harness.drinkLog.failReads(with: nil)
        await harness.drinkLog.signalChange()

        #expect(await collected.waitForCount(1) == [Self.expected([])])
    }

    @Test func aFailedStorePublishesNothingAndReloadsNothing() async throws {
        let harness = Self.harness(storeError: DataSourceFailed())
        let collected = Collected(harness.repository.snapshots())
        defer { collected.cancel() }
        await Self.waitUntilListening(harness.drinkLog)

        #expect(await collected.settled().isEmpty)
        #expect(harness.events.value.isEmpty)
    }
}
