//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthKitAuthorizationDataSourceTests
//

import HealthKit
import Synchronization
import Testing

@testable import Half_Life

/// Checks the HealthKit authorization data source against PERM-2 and PERM-3 in the Onboarding article.
///
/// Each test replaces HealthKit's availability check, status request, and authorization request with stand-ins that
/// record what they're asked, so no test asks real HealthKit for anything (constitution Article V.3.5).
struct HealthKitAuthorizationDataSourceTests {

    /// The type identifiers one call was asked about.
    struct Asked: Sendable, Equatable {
        let share: Set<String>
        let read: Set<String>
    }

    /// Stands in for HealthKit. It records each status request and authorization request.
    final class HealthKitStandIn: Sendable {
        let statusRequests = Mutex<[Asked]>([])
        let authorizationRequests = Mutex<[Asked]>([])
        let isAvailable: Bool
        let status: @Sendable () throws -> HKAuthorizationRequestStatus
        let authorizationError: (any Error)?

        init(
            isAvailable: Bool = true,
            status: @escaping @Sendable () throws -> HKAuthorizationRequestStatus = { .shouldRequest },
            authorizationError: (any Error)? = nil
        ) {
            self.isAvailable = isAvailable
            self.status = status
            self.authorizationError = authorizationError
        }

        static func asked(_ share: Set<HKSampleType>, _ read: Set<HKObjectType>) -> Asked {
            Asked(share: Set(share.map(\.identifier)), read: Set(read.map(\.identifier)))
        }

        var dataSource: HealthKitAuthorizationDataSource {
            HealthKitAuthorizationDataSource(
                isHealthDataAvailable: { self.isAvailable },
                requestStatus: { share, read in
                    self.statusRequests.withLock { $0.append(Self.asked(share, read)) }
                    return try self.status()
                },
                requestAuthorization: { share, read in
                    self.authorizationRequests.withLock { $0.append(Self.asked(share, read)) }
                    if let error = self.authorizationError { throw error }
                })
        }
    }

    /// Sleep analysis, step count, and resting heart rate, and nothing else.
    static let expectedReadTypes: Set<String> = [
        HKCategoryTypeIdentifier.sleepAnalysis.rawValue, HKQuantityTypeIdentifier.stepCount.rawValue,
        HKQuantityTypeIdentifier.restingHeartRate.rawValue,
    ]

    // MARK: - PERM-2: not requested until the request has been made, and requested after

    @Test func notRequestedWhileHealthKitSaysItShouldRequest() async {
        let standIn = HealthKitStandIn(status: { .shouldRequest })

        #expect(await standIn.dataSource.status() == .notRequested)
    }

    @Test func requestedOnceHealthKitSaysARequestIsUnnecessary() async {
        let standIn = HealthKitStandIn(status: { .unnecessary })

        #expect(await standIn.dataSource.status() == .requested)
    }

    @Test func anUnknownStatusCountsAsNotRequested() async {
        let standIn = HealthKitStandIn(status: { .unknown })

        #expect(await standIn.dataSource.status() == .notRequested)
    }

    @Test func aFailedStatusRequestCountsAsNotRequested() async {
        let standIn = HealthKitStandIn(status: { throw HKError(.errorDatabaseInaccessible) })

        #expect(await standIn.dataSource.status() == .notRequested)
    }

    @Test func unavailableWithoutHealthAndNothingIsAsked() async {
        let standIn = HealthKitStandIn(isAvailable: false)

        #expect(await standIn.dataSource.status() == .unavailable)
        #expect(standIn.statusRequests.withLock { $0 }.isEmpty)
    }

    // MARK: - PERM-3: exactly sleep, steps, and resting heart rate, read only

    @Test func requestsReadAccessToExactlySleepStepsAndRestingHeartRate() async throws {
        let standIn = HealthKitStandIn()

        try await standIn.dataSource.requestAccess()

        #expect(
            standIn.authorizationRequests.withLock { $0 } == [Asked(share: [], read: Self.expectedReadTypes)])
    }

    @Test func checksTheStatusOfTheSameTypes() async {
        let standIn = HealthKitStandIn()

        _ = await standIn.dataSource.status()

        #expect(standIn.statusRequests.withLock { $0 } == [Asked(share: [], read: Self.expectedReadTypes)])
    }

    @Test func aFailedRequestThrowsHealthKitsError() async {
        let standIn = HealthKitStandIn(authorizationError: HKError(.errorAuthorizationDenied))

        let error = await #expect(throws: HKError.self) {
            try await standIn.dataSource.requestAccess()
        }
        #expect(error?.code == .errorAuthorizationDenied)
    }
}
