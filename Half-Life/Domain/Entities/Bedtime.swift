//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life Bedtime
//

/// The time of day the user wants to be asleep by.
///
/// It's a time of day, not a date: the decay card finds the next time it comes round, in the user's calendar. It's
/// always a real time of day, from 0:00 to 23:59. See the Today Screen article, BED-1 and BED-2.
nonisolated struct Bedtime: Sendable, Equatable {
    /// 10:30pm, the prototype's example. It applies until the user sets their own bedtime.
    static let standard = Bedtime(validHour: 22, minute: 30)

    /// The hour, from 0 to 23.
    let hour: Int
    /// The minute, from 0 to 59.
    let minute: Int

    /// Creates a bedtime, or returns `nil` if `hour` and `minute` aren't a time of day.
    ///
    /// - Parameters:
    ///   - hour: The hour, from 0 to 23.
    ///   - minute: The minute, from 0 to 59.
    init?(hour: Int, minute: Int) {
        guard (0..<24).contains(hour), (0..<60).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }

    private init(validHour hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
}
