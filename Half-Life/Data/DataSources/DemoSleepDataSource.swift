//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DemoSleepDataSource
//

import Foundation

/// The demo sleep data source: the nights of ``DemoHealthScript``, in place of Apple Health's while the demo switch is
/// on.
///
/// It reads the current time from its clock, and never touches HealthKit, so the demo can be tried without Health
/// data (constitution Article V.3.5). Its nights are fixed, so its change stream finishes at once. The Apple Health
/// Card article lists its requirements, DEMOHEALTH-1 to DEMOHEALTH-3 and DEMOHEALTH-6.
struct DemoSleepDataSource: SleepDataSource {
    /// The current time, which fixes which day is today.
    let clock: any ClockDataSource
    /// The calendar, and so the time zone, whose clock times the nights follow.
    let calendar: Calendar
    private let script = DemoHealthScript()

    /// Creates the data source.
    ///
    /// - Parameters:
    ///   - clock: The current time.
    ///   - calendar: The calendar whose clock times the nights follow. Defaults to the user's current calendar.
    init(clock: any ClockDataSource, calendar: Calendar = .autoupdatingCurrent) {
        self.clock = clock
        self.calendar = calendar
    }

    /// Returns every demo sleep interval that overlaps `range`, in order of start.
    ///
    /// - Parameter range: The time to read sleep for.
    func sleepIntervals(in range: DateInterval) -> [SleepStageInterval] {
        script.sleepIntervals(in: range, now: clock.now(), calendar: calendar)
    }

    /// Returns a stream that finishes at once, because the demo nights never change.
    func changes() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}
