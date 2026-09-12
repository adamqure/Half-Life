//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests BedtimeTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the bedtime entity (BED-1 to BED-3 in the Today Screen article).
struct BedtimeTests {

    /// BED-1: until the user sets one, the bedtime is 10:30pm, the prototype's example.
    @Test func standardBedtimeIsTenThirtyPM() {
        #expect(Bedtime.standard.hour == 22)
        #expect(Bedtime.standard.minute == 30)
    }

    /// BED-2: a bedtime is a real time of day, from 0:00 to 23:59.
    @Test(arguments: [(0, 0), (23, 59), (22, 30)])
    func acceptsATimeOfDay(hour: Int, minute: Int) throws {
        let bedtime = try #require(Bedtime(hour: hour, minute: minute))
        #expect(bedtime.hour == hour)
        #expect(bedtime.minute == minute)
    }

    /// BED-2: anything else isn't a bedtime.
    @Test(arguments: [(24, 0), (-1, 0), (22, 60), (22, -1)])
    func rejectsAnythingThatIsNotATimeOfDay(hour: Int, minute: Int) {
        #expect(Bedtime(hour: hour, minute: minute) == nil)
    }

    /// BED-3: the next bedtime is tonight's before it and exactly at it, and tomorrow's after it. The arguments are
    /// hours after midnight UTC.
    @Test(arguments: [(20.0, 22.5), (22.5, 22.5), (23.0, 46.5)])
    func nextBedtimeIsTheFirstAtOrAfterTheGivenMoment(hours: Double, expected: Double) {
        let midnight = Date(timeIntervalSinceReferenceDate: 0)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt

        let next = Bedtime.standard.next(atOrAfter: midnight.addingTimeInterval(hours * 3_600), in: utc)

        #expect(next == midnight.addingTimeInterval(expected * 3_600))
    }

    /// BED-3: the bedtime is a time of day in the given calendar. 10:30pm in Tokyo is 1:30pm UTC.
    @Test func nextBedtimeIsInTheGivenCalendar() throws {
        let midnight = Date(timeIntervalSinceReferenceDate: 0)
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))

        let next = Bedtime.standard.next(atOrAfter: midnight, in: tokyo)

        #expect(next == midnight.addingTimeInterval(13.5 * 3_600))
    }
}
