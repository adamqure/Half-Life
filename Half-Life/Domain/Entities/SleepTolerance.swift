//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepTolerance
//

import Foundation

/// The user's caffeine tolerance: the most caffeine they can have in them at sleep onset before their time asleep
/// starts to drop.
///
/// ``SleepToleranceRule`` finds it in the user's last 30 nights, and the app adopts it as the sleep threshold in place
/// of ``SleepThreshold/standard``, so the cutoff, the composer's warning, the reminders, and the sleep window all
/// follow it. It's derived from sleep, so it's health data: it's stored only on the device, and never logged
/// (constitution Articles V and XI.6). See the Insights article.
struct SleepTolerance: Sendable, Equatable {
    /// The tolerance, in milligrams: a whole 5 mg from 20 to 80 mg.
    let milligrams: Double
    /// How many nights had caffeine at or under it at sleep onset.
    let nightsUnder: Int
    /// How many nights had more caffeine than it at sleep onset.
    let nightsOver: Int
}
