//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LoggerHalfLifeTests
//

import Foundation
import OSLog
import Testing

@testable import Half_Life

/// Checks that `Logger(for:)` applies the convention in the Logging article: Half-Life's subsystem, and the owning
/// type's name as the category.
struct LoggerHalfLifeTests {

    @Test func logsInTheAppSubsystemUnderTheOwnersName() throws {
        let marker = UUID().uuidString
        Logger(for: LoggerHalfLifeTests.self).notice("Logger convention check \(marker, privacy: .public)")

        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let entries = try store.getEntries(matching: NSPredicate(format: "composedMessage CONTAINS %@", marker))
        let entry = try #require(entries.compactMap { $0 as? OSLogEntryLog }.first)

        #expect(entry.subsystem == "com.quillanq.Half-Life")
        #expect(entry.category == "LoggerHalfLifeTests")
    }
}
