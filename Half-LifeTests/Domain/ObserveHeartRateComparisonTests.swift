//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ObserveHeartRateComparisonTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks that ``ObserveRestingHeartRateComparisonUseCase`` combines the last 30 days' heart rates with the caffeine
/// nights before them, and streams ``RestingHeartRateComparisonRule``'s comparison (RHRUSE-1 to RHRUSE-3 in the
/// Insights article).
///
/// The fakes' streams send their values and finish, in an order the test can't fix, so each test checks what holds
/// whichever stream is read first.
struct ObserveHeartRateComparisonTests {

    let rule = RestingHeartRateComparisonRule()
    let tokyo: Calendar

    init() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        self.tokyo = tokyo
    }

    static func day(_ index: Int) -> Date {
        Date(timeIntervalSinceReferenceDate: Double(index) * 86_400)
    }

    /// Nights on days 0 and 1, with the given caffeine at their recorded sleep onsets.
    static func nights(_ first: Double, _ second: Double) -> CaffeineNightHistory {
        CaffeineNightHistory(
            nights: [first, second].enumerated().map { index, milligrams in
                CaffeineNight(
                    day: day(index), moment: day(index).addingTimeInterval(82_800), measuredAt: .sleepOnset,
                    milligrams: milligrams, isCaffeineNight: milligrams > 40)
            },
            threshold: .standard, isDemo: false)
    }

    /// Heart rates on days 1 and 2.
    static func heartRates(_ first: Double, _ second: Double, isDemo: Bool = false) -> RestingHeartRateHistory {
        RestingHeartRateHistory(
            days: [
                RestingHeartRateDay(day: day(1), beatsPerMinute: first),
                RestingHeartRateDay(day: day(2), beatsPerMinute: second),
            ],
            isDemo: isDemo)
    }

    /// Every comparison the use case streams, for fake repositories that send `nights` and `heartRates` for 30 days in
    /// Tokyo, and nothing otherwise.
    func received(
        nights: [CaffeineNightHistory], heartRates: [RestingHeartRateHistory]
    ) async throws -> [RestingHeartRateComparison] {
        let timeZone = tokyo.timeZone
        let sleepTolerance = FakeSleepToleranceRepository(caffeineNights: { count, calendar in
            count == 30 && calendar.timeZone == timeZone ? nights : []
        })
        let healthData = FakeHealthDataRepository(restingHeartRates: { count, calendar in
            count == 30 && calendar.timeZone == timeZone ? heartRates : []
        })
        let observe = ObserveRestingHeartRateComparisonUseCase(sleepTolerance: sleepTolerance, healthData: healthData)
        var received: [RestingHeartRateComparison] = []
        for await comparison in try await executeThroughProtocol(observe, tokyo) {
            received.append(comparison)
        }
        return received
    }

    func comparison(_ heartRates: RestingHeartRateHistory, _ nights: CaffeineNightHistory)
        -> RestingHeartRateComparison
    {
        rule.comparison(of: heartRates, with: nights, calendar: tokyo)
    }

    // MARK: - RHRUSE-1: once both have arrived, it streams the rule's comparison, for 30 days in the given calendar

    @Test func streamsTheComparisonOfTheLast30DaysInTheGivenCalendar() async throws {
        let nights = Self.nights(80, 10)
        let heartRates = Self.heartRates(62, 57, isDemo: true)

        let received = try await received(nights: [nights], heartRates: [heartRates])

        #expect(received == [comparison(heartRates, nights)])
        #expect(ObserveRestingHeartRateComparisonUseCase.dayCount == 30)
    }

    @Test func sendsNothingUntilBothHaveArrived() async throws {
        #expect(try await received(nights: [Self.nights(80, 10)], heartRates: []).isEmpty)
        #expect(try await received(nights: [], heartRates: [Self.heartRates(62, 57)]).isEmpty)
    }

    // MARK: - RHRUSE-2: a new value from either repository sends the comparison of the latest two

    @Test func aNewValueFromEitherSendsTheComparisonOfTheLatestTwo() async throws {
        let (firstNights, laterNights) = (Self.nights(80, 10), Self.nights(10, 80))
        let (firstRates, laterRates) = (Self.heartRates(62, 57), Self.heartRates(58, 64))

        let received = try await received(nights: [firstNights, laterNights], heartRates: [firstRates, laterRates])

        let possible = [firstRates, laterRates].flatMap { rates in
            [firstNights, laterNights].map { comparison(rates, $0) }
        }
        #expect(received.last == comparison(laterRates, laterNights))
        #expect(received.allSatisfy { possible.contains($0) })
    }

    // MARK: - RHRUSE-3: a comparison the same as the last one sent isn't sent again

    @Test func theSameComparisonIsNotSentTwice() async throws {
        let nights = Self.nights(80, 10)
        let heartRates = Self.heartRates(62, 57)

        let received = try await received(nights: [nights, nights], heartRates: [heartRates, heartRates])

        #expect(received == [comparison(heartRates, nights)])
    }
}
