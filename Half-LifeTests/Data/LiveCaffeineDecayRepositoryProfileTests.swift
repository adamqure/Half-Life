//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LiveCaffeineDecayRepositoryProfileTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that the decay repository recalculates when the half-life or the bedtime changes (REPO-11 and REPO-12 in
/// the Onboarding article).
@Suite(.timeLimit(.minutes(1)))
struct LiveCaffeineDecayRepositoryProfileTests {

    static let afternoon = LiveCaffeineDecayRepositoryStatusTests.afternoon
    static let utc = LiveCaffeineDecayRepositoryStatusTests.utc
    static let dayOfDrinks = LiveCaffeineDecayRepositoryStatusTests.dayOfDrinks
    static let intakes = dayOfDrinks.map(\.intake)

    let halfLife = FakeHalfLifeDataSource(value: .standard)
    let bedtime = FakeBedtimeDataSource(value: .standard)

    func repository() -> LiveCaffeineDecayRepository {
        LiveCaffeineDecayRepository(
            drinkLog: FakeDrinkLogDataSource(drinks: Self.dayOfDrinks), halfLife: halfLife,
            absorption: FakeAbsorptionRateDataSource(value: .standard), bedtime: bedtime,
            clock: FakeClockDataSource(date: Self.afternoon, minuteDates: []))
    }

    static func kinetics(_ halfLife: CaffeineHalfLife) -> CaffeineKinetics {
        CaffeineKinetics(halfLife: halfLife, absorption: .standard)
    }

    // MARK: - REPO-11: a changed half-life recalculates the curve and the status

    @Test func aChangedHalfLifeRecalculatesTheCurve() async throws {
        let eightHours = try #require(CaffeineHalfLife(seconds: 28_800))
        let repository = repository()

        var curves = repository.curve().makeAsyncIterator()
        _ = try #require(await curves.next())
        await halfLife.change(to: eightHours)
        let updated = try #require(await curves.next())

        #expect(
            updated
                == CaffeineDecayRule().curve(
                    from: Self.intakes, kinetics: Self.kinetics(eightHours), now: Self.afternoon))
    }

    @Test func aChangedHalfLifeRecalculatesTheStatus() async throws {
        let eightHours = try #require(CaffeineHalfLife(seconds: 28_800))
        let repository = repository()

        var statuses = repository.status(in: Self.utc).makeAsyncIterator()
        _ = try #require(await statuses.next())
        await halfLife.change(to: eightHours)
        let updated = try #require(await statuses.next())

        #expect(
            updated
                == CaffeineStatusRule().status(
                    from: Self.intakes, kinetics: Self.kinetics(eightHours), bedtime: .standard, now: Self.afternoon,
                    calendar: Self.utc))
    }

    // MARK: - REPO-12: a changed bedtime recalculates the status

    @Test func aChangedBedtimeRecalculatesTheStatus() async throws {
        let late = try #require(Bedtime(hour: 23, minute: 45))
        let repository = repository()

        var statuses = repository.status(in: Self.utc).makeAsyncIterator()
        _ = try #require(await statuses.next())
        await bedtime.change(to: late)
        let updated = try #require(await statuses.next())

        #expect(
            updated
                == CaffeineStatusRule().status(
                    from: Self.intakes, kinetics: Self.kinetics(.standard), bedtime: late, now: Self.afternoon,
                    calendar: Self.utc))
    }
}
