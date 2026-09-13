//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LastNightSleep
//

import Foundation

/// What the Apple Health card shows for last night: the time asleep, or, when no sleep was recorded, the time in bed.
///
/// ``LastNightSleepRule`` makes it. Time in bed on its own says nothing about sleep, so analysis never uses
/// ``inBedOnly(seconds:)``. See the Apple Health Card article.
enum LastNightSleep: Sendable, Equatable {
    /// Health recorded sleep last night. The value is the time asleep, in seconds.
    case asleep(seconds: TimeInterval)
    /// Health recorded time in bed last night, but no sleep. The value is the time in bed, in seconds.
    case inBedOnly(seconds: TimeInterval)
}
