//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DemoRestingHeartRateDataSource
//

import Foundation

/// The demo resting heart rate data source: the daily averages of ``DemoHealthScript``, in place of Apple Health's
/// while the demo switch is on.
///
/// Today's appears only from 9am, so its change stream signals at every whole minute, and the Apple Health card picks
/// it up when it arrives. It never touches HealthKit (constitution Article V.3.5). The Apple Health Card article lists
/// its requirement, DEMOHEALTH-5.
struct DemoRestingHeartRateDataSource: RestingHeartRateDataSource {
    /// The current time, whose minutes today's reading appears at.
    let clock: any ClockDataSource
    /// The calendar, and so the time zone, whose days are averaged over.
    let calendar: Calendar
    private let script = DemoHealthScript()

    /// Creates the data source.
    ///
    /// - Parameters:
    ///   - clock: The current time, and its minutes.
    ///   - calendar: The calendar whose days are averaged over. Defaults to the user's current calendar.
    init(clock: any ClockDataSource, calendar: Calendar = .autoupdatingCurrent) {
        self.clock = clock
        self.calendar = calendar
    }

    /// Returns the demo resting heart rate on the day that contains `day`, in beats per minute, or `nil` outside the
    /// demo's days, and today before 9am.
    ///
    /// - Parameter day: Any moment in the day to average.
    func averageRestingHeartRate(on day: Date) -> Double? {
        script.restingHeartRate(on: day, now: clock.now(), calendar: calendar)
    }

    /// Returns a stream that signals at every whole minute the clock streams, so today's reading is picked up when it
    /// appears. It ends when its subscriber stops listening.
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
