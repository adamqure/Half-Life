//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthKitRestingHeartRateChangesTests
//

import Foundation
import HealthKit
import Synchronization
import Testing

@testable import Half_Life

/// Checks the HealthKit resting heart rate data source's change stream against RHR-6 to RHR-8 in the Resting Heart
/// Rate article.
///
/// Each test replaces HealthKit's observer query with a stand-in that records what it's asked and lets the test report
/// changes, so no test reads real Health data (constitution Article V.3.5).
struct HealthKitRestingHeartRateChangesTests {

    /// Stands in for HealthKit's observer query. It records every observer, and lets a test report changes to them.
    final class ObserverStandIn: Sendable {
        let observedTypes = Mutex<[HKSampleType]>([])
        let handlers = Mutex<[@Sendable ((any Error)?) -> Void]>([])
        let stopCount = Mutex(0)

        var dataSource: HealthKitRestingHeartRateDataSource {
            HealthKitRestingHeartRateDataSource(
                averageQuantity: { _ in nil },
                observe: { type, handler in
                    self.observedTypes.withLock { $0.append(type) }
                    self.handlers.withLock { $0.append(handler) }
                    return { self.stopCount.withLock { $0 += 1 } }
                })
        }

        /// Reports a change, or an error, to every observer started so far, as HealthKit's observer query does.
        func report(_ error: (any Error)? = nil) {
            for handler in handlers.withLock({ $0 }) {
                handler(error)
            }
        }
    }

    /// Counts the signals `changes` delivers for `work`. Signals are buffered, so after a short wait every signal the
    /// work sent has been counted, and cancelling ends the count.
    static func signalCount(_ changes: AsyncStream<Void>, during work: () -> Void) async throws -> Int {
        let counter = Task {
            var count = 0
            for await _ in changes {
                count += 1
            }
            return count
        }
        work()
        try await Task.sleep(for: .milliseconds(200))
        counter.cancel()
        return await counter.value
    }

    // MARK: - RHR-6: each subscriber observes resting heart rate, and gets a signal per change HealthKit reports

    @Test func eachSubscriberObservesRestingHeartRate() {
        let standIn = ObserverStandIn()
        let source = standIn.dataSource

        let first = source.changes()
        let second = source.changes()

        #expect(
            standIn.observedTypes.withLock { $0 }
                == [HKQuantityType(.restingHeartRate), HKQuantityType(.restingHeartRate)])
        withExtendedLifetime((first, second)) {}
    }

    @Test func signalsOncePerReportedChange() async throws {
        let standIn = ObserverStandIn()
        let changes = standIn.dataSource.changes()

        let count = try await Self.signalCount(changes) {
            standIn.report()
            standIn.report()
        }

        #expect(count == 2)
    }

    // MARK: - RHR-7: an error HealthKit reports signals nothing

    @Test func aReportedErrorSignalsNothing() async throws {
        let standIn = ObserverStandIn()
        let changes = standIn.dataSource.changes()

        let count = try await Self.signalCount(changes) {
            standIn.report(HKError(.errorAuthorizationNotDetermined))
        }

        #expect(count == 0)
    }

    // MARK: - RHR-8: the observer stops when its subscriber stops listening

    @Test func stopsObservingWhenTheSubscriberStops() async {
        let standIn = ObserverStandIn()
        let changes = standIn.dataSource.changes()

        let listener = Task {
            for await _ in changes {}
        }
        listener.cancel()
        await listener.value

        #expect(standIn.stopCount.withLock { $0 } == 1)
    }
}
