//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepWindow
//

import Foundation

/// Tonight's best time to sleep: when the caffeine already logged falls to the sleep threshold, and the 90 minutes to
/// fall asleep in.
///
/// ``SleepWindowRule`` calculates it. Its times and levels are derived from caffeine intake, which is health data, so
/// no part of it is ever logged (constitution Article XI.6). See the Insights article.
struct SleepWindow: Sendable, Equatable {
    /// 6pm, when the night starts, and where the chart starts.
    let evening: Date
    /// The night's bedtime: the first time the user's bedtime comes round at or after ``evening``.
    let bedtime: Date
    /// The first whole minute after which the caffeine stays at or below the threshold until noon the next day, or
    /// `nil` if it's still over it then. It's ``evening`` when nothing is over the threshold from then on.
    let clearsAt: Date?
    /// The 90 minutes to fall asleep in, from the later of ``clearsAt`` and ``bedtime``, or `nil` when caffeine
    /// doesn't clear.
    let window: DateInterval?
    /// Where the chart ends: 4am, the window's end when that's later, or noon when there's no window.
    let chartEnd: Date
    /// The most caffeine the window allows in the body.
    let threshold: SleepThreshold
    /// The level at every whole minute from ``evening`` to ``chartEnd``.
    let levels: [CaffeineLevel]

    /// Whether caffeine clears at or before the bedtime, so the window starts at the bedtime.
    var clearsBeforeBedtime: Bool {
        clearsAt.map { $0 <= bedtime } ?? false
    }
}
