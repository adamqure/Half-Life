//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveSleepToleranceRepository+Storage
//

import Foundation
import OSLog

/// Storing the tolerance, where the decay model reads it as the sleep threshold. See the Insights article, TOLREPO-5.
extension LiveSleepToleranceRepository {
    /// Stores `tolerance`, or none, unless it's the one already stored. A failure is logged and otherwise ignored, so
    /// the next recalculation tries again.
    func storeIfChanged(_ tolerance: SleepTolerance?) async {
        if stored == nil {
            stored = await readStoredTolerance()
        }
        if let stored, stored == tolerance { return }
        do {
            try await tolerances.store(tolerance)
            stored = .some(tolerance)
            Self.logger.debug("Stored the caffeine tolerance")
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't store the tolerance: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
        }
    }

    /// Reads the stored tolerance, or returns `nil`, after logging, if it can't be read, so it's stored again.
    private func readStoredTolerance() async -> SleepTolerance?? {
        do {
            return .some(try await tolerances.storedTolerance())
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the stored tolerance: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return nil
        }
    }
}
