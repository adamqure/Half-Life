//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveCurrentTimeRepository
//

import Foundation

/// The live current time repository. It reads the time from its injected ``ClockDataSource``.
///
/// It's an actor off the main actor, like every repository (constitution Article I.13). Its data is the clock, so
/// its stream publishes every minute on purpose. The Drink Composer article lists its requirements, TIME-1 and
/// TIME-2.
actor LiveCurrentTimeRepository: CurrentTimeRepository {
    private let dataSource: any ClockDataSource

    /// Creates the repository.
    ///
    /// - Parameter dataSource: The clock to read.
    init(dataSource: any ClockDataSource) {
        self.dataSource = dataSource
    }

    /// Returns the data source's current time.
    nonisolated func now() -> Date {
        dataSource.now()
    }

    /// Streams the data source's current time: once immediately, then at the start of each whole minute.
    nonisolated func currentTime() -> AsyncStream<Date> {
        dataSource.minutes()
    }
}
