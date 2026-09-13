//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DemoStepCountDataSource
//

import Foundation

/// The demo step count data source: the daily totals of ``DemoHealthScript``, in place of Apple Health's while the
/// demo switch is on.
///
/// Today's steps grow with the clock, so its change stream signals at every whole minute. It never touches HealthKit
/// (constitution Article V.3.5). The Apple Health Card article lists its requirement, DEMOHEALTH-4.
struct DemoStepCountDataSource: StepCountDataSource {
    /// The current time, whose minutes today's steps grow with.
    let clock: any ClockDataSource
    /// The calendar, and so the time zone, whose days are totalled.
    let calendar: Calendar
    private let script = DemoHealthScript()

    /// Creates the data source.
    ///
    /// - Parameters:
    ///   - clock: The current time, and its minutes.
    ///   - calendar: The calendar whose days are totalled. Defaults to the user's current calendar.
    init(clock: any ClockDataSource, calendar: Calendar = .autoupdatingCurrent) {
        self.clock = clock
        self.calendar = calendar
    }

    /// Returns the demo steps on the day that contains `day`, or `nil` outside the demo's days, and today before 7am.
    ///
    /// - Parameter day: Any moment in the day to total.
    func stepCount(on day: Date) -> Int? {
        script.stepCount(on: day, now: clock.now(), calendar: calendar)
    }

    /// Returns a stream that signals at every whole minute the clock streams, because today's steps grow with it. It
    /// ends when its subscriber stops listening.
    func changes() -> AsyncStream<Void> {
        let minutes = clock.minutes()
        return AsyncStream { continuation in
            let listener = Task {
                for await _ in minutes {
                    continuation.yield()
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in listener.cancel() }
        }
    }
}
