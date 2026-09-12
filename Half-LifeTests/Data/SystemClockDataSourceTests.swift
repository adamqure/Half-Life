//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SystemClockDataSourceTests
//

import Foundation
import Synchronization
import Testing

@testable import Half_Life

/// Checks the system clock against requirements CLOCK-1 to CLOCK-4 in the Today Screen article, and CLOCK-5 in the
/// Drink Composer article.
struct SystemClockDataSourceTests {

    /// A clock that only moves when a test sleeps on it. Each sleep advances the time by `advance(duration)`,
    /// and the sleep after `sleepsBeforeCancel` sleeps throws, as a cancelled sleep does.
    final class ManualClock: Sendable {
        let time: Mutex<Date>
        let sleeps = Mutex<[TimeInterval]>([])
        let sleepsBeforeCancel: Int
        let advance: @Sendable (TimeInterval) -> TimeInterval

        init(
            _ start: Date, sleepsBeforeCancel: Int,
            advance: @escaping @Sendable (TimeInterval) -> TimeInterval = { $0 }
        ) {
            time = Mutex(start)
            self.sleepsBeforeCancel = sleepsBeforeCancel
            self.advance = advance
        }

        var dataSource: SystemClockDataSource {
            SystemClockDataSource(
                clock: { self.time.withLock { $0 } },
                sleep: { duration in
                    let count = self.sleeps.withLock { sleeps in
                        sleeps.append(duration)
                        return sleeps.count
                    }
                    guard count <= self.sleepsBeforeCancel else { throw CancellationError() }
                    self.time.withLock { $0.addTimeInterval(self.advance(duration)) }
                })
        }
    }

    /// 12:15:30 on 2026-09-11, UTC: halfway through a minute.
    static let midMinute = Date(timeIntervalSince1970: 1_789_128_930)
    /// 12:16:00, the next whole minute.
    static let nextMinute = Date(timeIntervalSince1970: 1_789_128_960)

    static func collect(_ stream: AsyncStream<Date>) async -> [Date] {
        var received: [Date] = []
        for await date in stream {
            received.append(date)
        }
        return received
    }

    @Test func fixturesSitOnAndBetweenWholeMinutes() {
        #expect(Self.midMinute.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60) == 30)
        #expect(Self.nextMinute.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60) == 0)
    }

    // MARK: - CLOCK-1: the current time as soon as it's subscribed to

    @Test func yieldsTheCurrentTimeFirst() async {
        let clock = ManualClock(Self.midMinute, sleepsBeforeCancel: 0)

        #expect(await Self.collect(clock.dataSource.minutes()) == [Self.midMinute])
    }

    // MARK: - CLOCK-2: after each value, it sleeps until the next whole minute

    @Test func sleepsUntilEachWholeMinute() async {
        let clock = ManualClock(Self.midMinute, sleepsBeforeCancel: 2)

        let received = await Self.collect(clock.dataSource.minutes())

        #expect(received == [Self.midMinute, Self.nextMinute, Self.nextMinute.addingTimeInterval(60)])
        #expect(clock.sleeps.withLock { $0 } == [30, 60, 60])
    }

    // MARK: - CLOCK-3: the later of the current time and the minute it slept until

    @Test func yieldsTheWakeTimeAfterOversleeping() async {
        let clock = ManualClock(Self.midMinute, sleepsBeforeCancel: 1, advance: { $0 + 125 })

        let received = await Self.collect(clock.dataSource.minutes())

        #expect(received == [Self.midMinute, Self.nextMinute.addingTimeInterval(125)])
    }

    @Test func yieldsTheMinuteAfterWakingEarly() async {
        let clock = ManualClock(Self.midMinute, sleepsBeforeCancel: 1, advance: { $0 - 0.5 })

        let received = await Self.collect(clock.dataSource.minutes())

        #expect(received == [Self.midMinute, Self.nextMinute])
    }

    // MARK: - CLOCK-4: a cancelled sleep finishes the stream

    @Test func finishesWhenSleepingIsCancelled() async {
        let clock = ManualClock(Self.midMinute, sleepsBeforeCancel: 0)

        let received = await Self.collect(clock.dataSource.minutes())

        #expect(received.count == 1)
        #expect(clock.sleeps.withLock { $0 }.count == 1)
    }

    @Test func stopsWhenTheSubscriberStops() async {
        var first: Date?
        for await date in SystemClockDataSource().minutes() {
            first = date
            break
        }

        #expect(first != nil)
    }

    // MARK: - CLOCK-5: now() is the current time

    @Test func nowReadsTheClock() {
        #expect(ManualClock(Self.midMinute, sleepsBeforeCancel: 0).dataSource.now() == Self.midMinute)
    }

    @Test func nowReadsTheSystemClockByDefault() {
        let before = Date.now
        let now = SystemClockDataSource().now()

        #expect(now >= before)
        #expect(now <= Date.now)
    }
}
