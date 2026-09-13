//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LanguageModelToolTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the language model's tools against LMTOOL-1 to LMTOOL-7 and LMTOOL-9 in the Language Model article.
///
/// Each test calls a tool directly, against fake repositories, so no test needs the model. Times are in New York, in
/// the `en_US` locale, on Monday, 2026-09-07, at 3:05pm unless a test says otherwise.
struct LanguageModelToolTests {

    struct StoreFailed: Error {}

    static func newYork() throws -> Calendar {
        try LanguageModelFormatTests.calendar("America/New_York")
    }

    static func format() throws -> LanguageModelFormat {
        LanguageModelFormat(calendar: try newYork())
    }

    /// A moment in September 2026, in New York.
    static func date(day: Int, hour: Int, minute: Int, second: Int = 0) throws -> Date {
        try #require(
            newYork().date(
                from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute, second: second)))
    }

    static func now() throws -> Date {
        try date(day: 7, hour: 15, minute: 5, second: 30)
    }

    // MARK: - LMTOOL-1 and LMTOOL-7: getCaffeineStatus

    @Test func theStatusReportsTheLevelNowAtBedtimeAndWhenTheLastDrinkIsHalfGone() async throws {
        let format = try Self.format()
        let bedtime = try Self.date(day: 7, hour: 22, minute: 30)
        let halfGone = try Self.date(day: 7, hour: 16, minute: 27)
        let status = CaffeineStatus(
            level: CaffeineLevel(date: try Self.now(), milligrams: 84.6), activeIntakes: [],
            lastIntakeHalfGoneAt: halfGone, levelAtBedtime: CaffeineLevel(date: bedtime, milligrams: 34.2))
        let later = CaffeineStatus(
            level: CaffeineLevel(date: try Self.now(), milligrams: 500), activeIntakes: [], lastIntakeHalfGoneAt: nil,
            levelAtBedtime: nil)
        let timeZone = format.calendar.timeZone
        let tool = CaffeineStatusTool(
            caffeineDecay: FakeCaffeineDecayRepository(statuses: { $0.timeZone == timeZone ? [status, later] : [] }),
            format: format)

        let output = try await tool.call(arguments: .init())

        #expect(
            output == """
                Caffeine in the body now: 85 mg.
                At bedtime, \(format.time(bedtime)): 34 mg.
                The last drink is half gone at \(format.time(halfGone)).
                """)
    }

    @Test func theStatusLeavesOutWhatItDoesntHave() async throws {
        let status = CaffeineStatus(
            level: CaffeineLevel(date: try Self.now(), milligrams: 0), activeIntakes: [], lastIntakeHalfGoneAt: nil,
            levelAtBedtime: nil)
        let tool = CaffeineStatusTool(
            caffeineDecay: FakeCaffeineDecayRepository(statuses: { _ in [status] }), format: try Self.format())

        #expect(try await tool.call(arguments: .init()) == "Caffeine in the body now: 0 mg.")
    }

    @Test func theStatusSaysWhenItIsntAvailable() async throws {
        let tool = CaffeineStatusTool(caffeineDecay: FakeCaffeineDecayRepository(), format: try Self.format())

        #expect(try await tool.call(arguments: .init()) == "The caffeine level isn't available.")
    }

    // MARK: - LMTOOL-2 and LMTOOL-7: getCaffeineCutoff

    @Test func theCutoffReportsTheLatestTimeForTheUsualDrink() async throws {
        let format = try Self.format()
        let bedtime = try Self.date(day: 7, hour: 22, minute: 30)
        let latestCup = try Self.date(day: 7, hour: 13, minute: 0)
        let cutoff = CaffeineCutoff(
            drink: FavouriteDrink(type: .latte, quantity: 2), latestCup: latestCup, bedtime: bedtime,
            threshold: .standard)
        let timeZone = format.calendar.timeZone
        let tool = CaffeineCutoffTool(
            caffeineDecay: FakeCaffeineDecayRepository(cutoffs: { $0.timeZone == timeZone ? [cutoff] : [] }),
            format: format)

        #expect(
            try await tool.call(arguments: .init())
                == "The latest time to have the usual drink (latte, 2 shots) and still be at or under 40 mg at "
                + "bedtime, \(format.time(bedtime)), is \(format.time(latestCup)).")
    }

    @Test func theCutoffSaysWhenThereIsNoTimeLeftToday() async throws {
        let format = try Self.format()
        let bedtime = try Self.date(day: 7, hour: 22, minute: 30)
        let cutoff = CaffeineCutoff(
            drink: FavouriteDrink(type: .latte, quantity: 2), latestCup: nil, bedtime: bedtime, threshold: .standard)
        let tool = CaffeineCutoffTool(
            caffeineDecay: FakeCaffeineDecayRepository(cutoffs: { _ in [cutoff] }), format: format)

        #expect(
            try await tool.call(arguments: .init())
                == "There's no time left today to have the usual drink (latte, 2 shots) and still be at or under "
                + "40 mg at bedtime, \(format.time(bedtime)).")
    }

    @Test func theCutoffSaysWhenItIsntAvailable() async throws {
        let tool = CaffeineCutoffTool(caffeineDecay: FakeCaffeineDecayRepository(), format: try Self.format())

        #expect(try await tool.call(arguments: .init()) == "The cutoff isn't available.")
    }

    // MARK: - LMTOOL-3 and LMTOOL-7: getCaffeineLevelAt

    /// A curve like the repository's: 1,440 levels, one a minute, from 12 hours before the current minute. Every level
    /// is 0 except the ones given, by date.
    static func curve(levels: [Date: Double]) throws -> [CaffeineLevel] {
        let start = try date(day: 7, hour: 3, minute: 5)
        return (0..<1_440).map { minute in
            let date = start.addingTimeInterval(Double(minute) * 60)
            return CaffeineLevel(date: date, milligrams: levels[date] ?? 0)
        }
    }

    static func levelTool(curves: [[CaffeineLevel]]) throws -> CaffeineLevelTool {
        CaffeineLevelTool(
            caffeineDecay: FakeCaffeineDecayRepository(curves: curves),
            currentTime: FakeCurrentTimeRepository(date: try now()), format: try format())
    }

    @Test func theLevelIsTheCurvesSampleForTheNextTimeTheClockShowsIt() async throws {
        let eleven = try Self.date(day: 7, hour: 23, minute: 0)
        let tool = try Self.levelTool(curves: [try Self.curve(levels: [eleven: 34.2])])

        #expect(
            try await tool.call(arguments: .init(hour: 23, minute: 0))
                == "Caffeine in the body at \(try Self.format().time(eleven)): 34 mg.")
    }

    @Test func theCurrentMinuteCountsAsTheNextTimeTheClockShowsIt() async throws {
        let currentMinute = try Self.date(day: 7, hour: 15, minute: 5)
        let tool = try Self.levelTool(curves: [try Self.curve(levels: [currentMinute: 84.6])])

        #expect(
            try await tool.call(arguments: .init(hour: 15, minute: 5))
                == "Caffeine in the body at \(try Self.format().time(currentMinute)): 85 mg.")
    }

    @Test func aTimeBeyondTheCurveIsOutOfReach() async throws {
        let fourTomorrow = try Self.date(day: 8, hour: 4, minute: 0)
        let tool = try Self.levelTool(curves: [try Self.curve(levels: [:])])

        #expect(
            try await tool.call(arguments: .init(hour: 4, minute: 0))
                == "The caffeine curve only reaches 12 hours ahead, so the level at "
                + "\(try Self.format().time(fourTomorrow)) isn't available.")
    }

    @Test func theLevelSaysWhenTheCurveIsntAvailable() async throws {
        let tool = try Self.levelTool(curves: [])

        #expect(try await tool.call(arguments: .init(hour: 23, minute: 0)) == "The caffeine level isn't available.")
    }

    // MARK: - LMTOOL-4 and LMTOOL-7: getDrinksOnDay

    static func drinksTool(days: @escaping @Sendable (Date, Calendar) -> [DrinkLogDay]) throws -> DrinksOnDayTool {
        DrinksOnDayTool(
            drinkLog: FakeDrinkLogRepository(days: days), currentTime: FakeCurrentTimeRepository(date: try now()),
            format: try format())
    }

    @Test func theDayListsEachDrinkMarksDemoDrinksAndGivesTheTotal() async throws {
        let format = try Self.format()
        let latte = LoggedDrink(
            type: .latte, quantity: 2, milligrams: 125.4, consumedAt: try Self.date(day: 6, hour: 8, minute: 5))
        let cola = LoggedDrink(
            type: .cola, quantity: 1, milligrams: 34, consumedAt: try Self.date(day: 6, hour: 13, minute: 30),
            isDemo: true)
        let yesterday = try Self.date(day: 6, hour: 0, minute: 0)
        let day = DrinkLogDay(intake: DailyCaffeineIntake(day: yesterday, milligrams: 159.4), drinks: [latte, cola])
        let timeZone = format.calendar.timeZone
        let tool = try Self.drinksTool { date, calendar in
            calendar.timeZone == timeZone && calendar.isDate(date, inSameDayAs: yesterday) ? [day] : []
        }

        #expect(
            try await tool.call(arguments: .init(daysAgo: 1)) == """
                Drinks logged on Sunday, September 6:
                - \(format.time(latte.consumedAt)): latte, 2 shots, 125 mg
                - \(format.time(cola.consumedAt)): cola, 1 can, 34 mg (demo data)
                Total: 159 mg.
                """)
    }

    @Test func theDaySaysWhenNothingWasLogged() async throws {
        let today = try Self.date(day: 7, hour: 0, minute: 0)
        let empty = DrinkLogDay(intake: DailyCaffeineIntake(day: today, milligrams: 0), drinks: [])
        let tool = try Self.drinksTool { _, _ in [empty] }

        #expect(try await tool.call(arguments: .init(daysAgo: 0)) == "No drinks were logged on Monday, September 7.")
    }

    @Test func theDaySaysWhenItIsntAvailable() async throws {
        let tool = try Self.drinksTool { _, _ in [] }

        #expect(
            try await tool.call(arguments: .init(daysAgo: 0))
                == "The drinks logged on Monday, September 7 aren't available.")
    }

    // MARK: - LMTOOL-5 and LMTOOL-6: logDrink

    static func logTool(drinkLog: FakeDrinkLogRepository) throws -> LogDrinkTool {
        let currentTime = FakeCurrentTimeRepository(date: try now())
        return LogDrinkTool(
            logDrink: LogDrinkUseCase(currentTime: currentTime, drinkLog: drinkLog), currentTime: currentTime,
            format: try format())
    }

    @Test func loggingLogsTheDrinkThroughTheUseCaseAndReportsIt() async throws {
        let drinkLog = FakeDrinkLogRepository()
        let consumedAt = try Self.now().addingTimeInterval(-30 * 60)

        let output = try await Self.logTool(drinkLog: drinkLog).call(
            arguments: .init(drink: .latte, quantity: 2, minutesAgo: 30))

        let logged = await drinkLog.logged
        try #require(logged.count == 1)
        #expect(logged[0].type == .latte)
        #expect(logged[0].quantity == 2)
        #expect(logged[0].milligrams == DrinkType.latte.estimatedMilligrams(quantity: 2))
        #expect(logged[0].consumedAt == consumedAt)
        #expect(!logged[0].isDemo)
        #expect(output == "Logged latte, 2 shots, 125 mg, at \(try Self.format().time(consumedAt)).")
    }

    @Test(arguments: [
        (DrinkLogRule.Violation.quantityBelowOne, "Not logged: the quantity has to be at least 1."),
        (.consumedInFuture, "Not logged: a drink can't be logged in the future."),
    ])
    func loggingReportsWhyTheRuleRefusedTheDrink(violation: DrinkLogRule.Violation, expected: String) async throws {
        let tool = try Self.logTool(drinkLog: FakeDrinkLogRepository(logError: violation))

        #expect(try await tool.call(arguments: .init(drink: .cola, quantity: 1, minutesAgo: 0)) == expected)
    }

    @Test func loggingThrowsAnyOtherError() async throws {
        let tool = try Self.logTool(drinkLog: FakeDrinkLogRepository(logError: StoreFailed()))

        await #expect(throws: StoreFailed.self) {
            try await tool.call(arguments: .init(drink: .cola, quantity: 1, minutesAgo: 0))
        }
    }

    // MARK: - LMTOOL-9: GeneratedDrinkType mirrors DrinkType

    @Test func everyDrinkHasExactlyOneMirror() {
        let mirrored = GeneratedDrinkType.allCases.map(\.drinkType)

        #expect(mirrored.count == DrinkType.allCases.count)
        #expect(Set(mirrored) == Set(DrinkType.allCases))
    }
}
