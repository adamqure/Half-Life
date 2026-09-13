//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthKitStepCountChangesTests
//

import Foundation
import HealthKit
import Synchronization
import Testing

@testable import Half_Life

/// Checks the HealthKit step count data source's change stream against STEPS-6 to STEPS-8 in the Step Count article.
///
/// Each test replaces HealthKit's observer query with a stand-in that records what it's asked and lets the test report
/// changes, so no test reads real Health data (constitution Article V.3.5).
struct HealthKitStepCountChangesTests {

    /// Stands in for HealthKit's observer query. It records every observer, and lets a test report changes to them.
    final class ObserverStandIn: Sendable {
        let observedTypes = Mutex<[HKSampleType]>([])
        let handlers = Mutex<[@Sendable ((any Error)?) -> Void]>([])
        let stopCount = Mutex(0)

        var dataSource: HealthKitStepCountDataSource {
            HealthKitStepCountDataSource(
                sumQuantity: { _ in nil },
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

    // MARK: - STEPS-6: each subscriber observes step count, and gets a signal per change HealthKit reports

    @Test func eachSubscriberObservesStepCount() {
        let standIn = ObserverStandIn()
        let source = standIn.dataSource

        let first = source.changes()
        let second = source.changes()

        #expect(standIn.observedTypes.withLock { $0 } == [HKQuantityType(.stepCount), HKQuantityType(.stepCount)])
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

    // MARK: - STEPS-7: an error HealthKit reports signals nothing

    @Test func aReportedErrorSignalsNothing() async throws {
        let standIn = ObserverStandIn()
        let changes = standIn.dataSource.changes()

        let count = try await Self.signalCount(changes) {
            standIn.report(HKError(.errorAuthorizationNotDetermined))
        }

        #expect(count == 0)
    }

    // MARK: - STEPS-8: the observer stops when its subscriber stops listening

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
