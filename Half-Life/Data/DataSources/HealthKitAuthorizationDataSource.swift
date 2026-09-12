//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthKitAuthorizationDataSource
//

import HealthKit
import OSLog

/// Reads and requests read access to Apple Health, on the app's shared health store.
///
/// It asks, in one sheet, to read sleep analysis, step count, and resting heart rate, the types the app's HealthKit
/// data sources read, and to write nothing. It's the only data source that requests Health access (constitution
/// Article V.3.1), and HealthKit presents the sheet itself (Article I.6). The Onboarding article lists its
/// requirements, PERM-2 and PERM-3.
struct HealthKitAuthorizationDataSource: HealthAuthorizationDataSource {
    /// A HealthKit call about the types to share and the types to read.
    typealias TypesCall<Result> = @Sendable (Set<HKSampleType>, Set<HKObjectType>) async throws -> Result

    private static let logger = Logger(for: HealthKitAuthorizationDataSource.self)

    /// The types Half-Life asks to read: sleep analysis, step count, and resting heart rate.
    static var readTypes: Set<HKObjectType> {
        [HKCategoryType(.sleepAnalysis), HKQuantityType(.stepCount), HKQuantityType(.restingHeartRate)]
    }

    /// Whether the device has Apple Health.
    let isHealthDataAvailable: @Sendable () -> Bool
    /// Asks HealthKit whether requesting the types would show its sheet.
    let requestStatus: TypesCall<HKAuthorizationRequestStatus>
    /// Asks HealthKit for access to the types, showing its sheet if it hasn't been shown for them.
    let requestAuthorization: TypesCall<Void>

    /// Creates the data source.
    ///
    /// - Parameters:
    ///   - isHealthDataAvailable: Whether the device has Apple Health. Defaults to asking HealthKit.
    ///   - requestStatus: Asks whether requesting the types would show Health's sheet. Defaults to asking the app's
    ///     shared health store, ``HealthKit/HKHealthStore/halfLife``.
    ///   - requestAuthorization: Requests access to the types. Defaults to requesting it from the shared store.
    init(
        isHealthDataAvailable: @escaping @Sendable () -> Bool = { HKHealthStore.isHealthDataAvailable() },
        requestStatus: @escaping TypesCall<HKAuthorizationRequestStatus> = {
            try await HKHealthStore.halfLife.statusForAuthorizationRequest(toShare: $0, read: $1)
        },
        requestAuthorization: @escaping TypesCall<Void> = {
            try await HKHealthStore.halfLife.requestAuthorization(toShare: $0, read: $1)
        }
    ) {
        self.isHealthDataAvailable = isHealthDataAvailable
        self.requestStatus = requestStatus
        self.requestAuthorization = requestAuthorization
    }

    /// Returns whether Half-Life has asked to read sleep, steps, and resting heart rate.
    ///
    /// It's `requested` once Health's sheet has been shown for all three, whatever the user chose, and `unavailable`
    /// on a device without Health. A failed check is logged, with the error's domain and code only, and counts as
    /// `notRequested`.
    func status() async -> HealthAccessStatus {
        guard isHealthDataAvailable() else { return .unavailable }
        do {
            switch try await requestStatus([], Self.readTypes) {
            case .unnecessary: return .requested
            case .shouldRequest, .unknown: return .notRequested
            @unknown default: return .notRequested
            }
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't check Health access: \(domain, privacy: .public) \(code, privacy: .public)")
            return .notRequested
        }
    }

    /// Asks to read sleep, steps, and resting heart rate, and to write nothing.
    ///
    /// - Throws: HealthKit's error if the request couldn't be made. It's logged with its domain and code only.
    func requestAccess() async throws {
        do {
            try await requestAuthorization([], Self.readTypes)
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't request Health access: \(domain, privacy: .public) \(code, privacy: .public)")
            throw error
        }
    }
}
