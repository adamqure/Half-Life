//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests WidgetSnapshotRuleTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the widget snapshot rule against WSNAP-1 to WSNAP-3 in the Widgets article.
struct WidgetSnapshotRuleTests {

    /// A whole 5-minute mark: 06:30 GMT.
    static let mark = Date(timeIntervalSinceReferenceDate: 800_001_000)
    /// The current time, 2 minutes 10 seconds after the mark.
    static let now = mark.addingTimeInterval(130)
    static let hour: TimeInterval = 60 * 60
    static let rule = WidgetSnapshotRule()
    static let decay = CaffeineDecayRule()

    static func intake(_ milligrams: Double, minutesAgo: Double) -> CaffeineIntake {
        CaffeineIntake(id: UUID(), milligrams: milligrams, consumedAt: now.addingTimeInterval(-minutesAgo * 60))
    }

    static func drink(_ type: DrinkType, _ quantity: Int, minutesAgo: Double) -> LoggedDrink {
        LoggedDrink(
            type: type, quantity: quantity, milligrams: type.estimatedMilligrams(quantity: quantity),
            consumedAt: now.addingTimeInterval(-minutesAgo * 60))
    }

    // MARK: - WSNAP-1: a level every 5 minutes, from 12 hours before the current mark, as the decay rule gives it

    @Test func theForecastStartsTwelveHoursBeforeTheCurrentMark() throws {
        let forecast = Self.rule.forecast(from: [Self.intake(128, minutesAgo: 90)], kinetics: .standard, now: Self.now)

        #expect(try #require(forecast.first).date == Self.mark.addingTimeInterval(-12 * Self.hour))
    }

    @Test func theForecastHasALevelEveryFiveMinutes() {
        let forecast = Self.rule.forecast(from: [Self.intake(128, minutesAgo: 90)], kinetics: .standard, now: Self.now)

        #expect(zip(forecast, forecast.dropFirst()).allSatisfy { $1.date.timeIntervalSince($0.date) == 5 * 60 })
    }

    @Test func eachLevelIsTheDecayRulesLevelAtItsMark() {
        let intakes = [Self.intake(128, minutesAgo: 90), Self.intake(63, minutesAgo: 400)]

        let forecast = Self.rule.forecast(from: intakes, kinetics: .standard, now: Self.now)

        #expect(forecast.allSatisfy { $0 == Self.decay.level(at: $0.date, from: intakes, kinetics: .standard) })
    }

    // MARK: - WSNAP-2: it ends at the first mark, at least 24 hours after its start, at which no intake still counts

    @Test func withNothingLoggedItCoversExactlyTwentyFourHoursAtZero() throws {
        let forecast = Self.rule.forecast(from: [], kinetics: .standard, now: Self.now)

        #expect(forecast.count == 24 * 12 + 1)
        #expect(try #require(forecast.last).date == Self.mark.addingTimeInterval(12 * Self.hour))
        #expect(forecast.allSatisfy { $0.milligrams == 0 })
    }

    @Test func aDrinkThatClearsSoonStillGivesTwentyFourHours() throws {
        let forecast = Self.rule.forecast(from: [Self.intake(5, minutesAgo: 600)], kinetics: .standard, now: Self.now)

        #expect(try #require(forecast.last).date == Self.mark.addingTimeInterval(12 * Self.hour))
    }

    @Test func aDrinkStillCountingRunsTheForecastUntilItStopsCounting() throws {
        let intakes = [Self.intake(400, minutesAgo: 10)]

        let forecast = Self.rule.forecast(from: intakes, kinetics: .standard, now: Self.now)

        let last = try #require(forecast.last)
        let beforeLast = forecast[forecast.count - 2]
        #expect(last.date > Self.mark.addingTimeInterval(12 * Self.hour))
        #expect(intakes.allSatisfy { !Self.decay.isCounting($0, at: last.date, kinetics: .standard) })
        #expect(intakes.contains { Self.decay.isCounting($0, at: beforeLast.date, kinetics: .standard) })
    }

    @Test func theForecastNeverRunsMoreThanSevenDaysPastTheCurrentMark() throws {
        let month = try #require(CaffeineHalfLife(seconds: 30 * 24 * Self.hour))
        let kinetics = CaffeineKinetics(halfLife: month, absorption: .standard)

        let forecast = Self.rule.forecast(from: [Self.intake(400, minutesAgo: 10)], kinetics: kinetics, now: Self.now)

        #expect(try #require(forecast.last).date == Self.mark.addingTimeInterval(7 * 24 * Self.hour))
    }

    // MARK: - WSNAP-3: the snapshot holds the bedtime, the favourites, the last cup, and onboarding

    @Test func theSnapshotHoldsWhatTheWidgetsShow() throws {
        let drinks = [Self.drink(.matcha, 1, minutesAgo: 30), Self.drink(.cola, 1, minutesAgo: 300)]
        let bedtime = try #require(Bedtime(hour: 23, minute: 15))

        let snapshot = Self.rule.snapshot(
            drinks: drinks, intakes: drinks.map(\.intake), kinetics: .standard,
            profile: UserProfile(bedtime: bedtime, hasCompletedOnboarding: true), now: Self.now)

        #expect(snapshot.forecast == Self.rule.forecast(from: drinks.map(\.intake), kinetics: .standard, now: Self.now))
        #expect(snapshot.bedtime == bedtime)
        #expect(snapshot.favourites == FavouriteDrinksRule().favourites(from: drinks))
        #expect(snapshot.latestDrinkAt == drinks[0].consumedAt)
        #expect(snapshot.isOnboardingComplete)
        #expect(snapshot.writtenAt == Self.now)
    }

    @Test func withNothingLoggedThereIsNoLatestDrinkAndTheStartersAreTheFavourites() {
        let snapshot = Self.rule.snapshot(
            drinks: [], intakes: [], kinetics: .standard, profile: nil, now: Self.now)

        #expect(snapshot.latestDrinkAt == nil)
        #expect(snapshot.favourites == FavouriteDrinksRule.starters)
        #expect(!snapshot.isOnboardingComplete)
    }
}
