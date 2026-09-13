//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineDecayRepositoryThresholdTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that the live decay repository follows the sleep threshold as it changes, so the cutoff adopts each caffeine
/// tolerance as soon as it's stored (TOLDECAY-1 in the Insights article).
@Suite(.timeLimit(.minutes(1)))
struct CaffeineDecayRepositoryThresholdTests {

    /// A threshold data source whose threshold a test can change, signalling the change as the personal one does.
    actor ChangingThresholdDataSource: SleepThresholdDataSource {
        private var value: SleepThreshold
        private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

        init(value: SleepThreshold) {
            self.value = value
        }

        func threshold() -> SleepThreshold {
            value
        }

        func changes() -> AsyncStream<Void> {
            let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
            continuations[UUID()] = continuation
            return stream
        }

        /// Changes the threshold and signals every subscriber.
        func change(to threshold: SleepThreshold) {
            value = threshold
            for continuation in continuations.values {
                continuation.yield()
            }
        }
    }

    typealias Cutoff = LiveCaffeineDecayRepositoryCutoffTests

    // MARK: - TOLDECAY-1: a change the threshold data source signals sends the cutoff for the new threshold

    @Test func aThresholdChangeSendsTheCutoffForTheNewThreshold() async throws {
        let drinks = [Cutoff.drink(hours: 8)]
        let threshold = ChangingThresholdDataSource(value: .standard)
        let repository = LiveCaffeineDecayRepository(
            drinkLog: FakeDrinkLogDataSource(drinks: drinks), halfLife: FakeHalfLifeDataSource(value: .standard),
            absorption: FakeAbsorptionRateDataSource(value: .standard),
            bedtime: FakeBedtimeDataSource(value: .standard),
            clock: FakeClockDataSource(date: Cutoff.now, minuteDates: []), threshold: threshold)
        let cutoffs = Collected(repository.cutoff(in: Cutoff.utc))
        _ = await cutoffs.waitForCount(1)
        let lower = try #require(SleepThreshold(milligrams: 25))

        await threshold.change(to: lower)

        let inputs = CaffeineCutoffRule.Inputs(
            drink: Cutoff.latte, intakes: drinks.map(\.intake), kinetics: .standard, threshold: lower,
            bedtime: .standard)
        let expected = try #require(CaffeineCutoffRule().cutoff(inputs, now: Cutoff.now, calendar: Cutoff.utc))
        #expect(await cutoffs.waitForCount(2).last == expected)
    }
}
