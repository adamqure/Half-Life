//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life SleepToleranceDependencies
//

import ComposableArchitecture
import Foundation
import OSLog

extension DependencyValues {
    /// The app's sleep tolerance repository (constitution Article I.15).
    ///
    /// Live, it's one app-scoped ``LiveSleepToleranceRepository``. It reads sleep from HealthKit, or from the demo
    /// while the switch in the shared ``DemoHealthDataFlagDataSourceKey`` data source is on, and drinks from the shared
    /// ``DrinkLogDataSourceKey`` data source. It reads the half-life through ``EstimatedHalfLifeDataSource``, as the
    /// curve does, and stores the tolerance in the shared ``SleepToleranceDataSourceKey`` data source, where the decay
    /// model reads it. It reads the bedtime, for the caffeine nights, from the shared ``ProfileDataSourceKey`` data
    /// source. Under a UI test, ``SimulatedHealthDataSource`` stands in for HealthKit, and in previews, Health holds
    /// nothing. In tests, using it without overriding it reports an issue.
    var sleepToleranceRepository: any SleepToleranceRepository {
        get { self[SleepToleranceRepositoryKey.self] }
        set { self[SleepToleranceRepositoryKey.self] = newValue }
    }

    /// Observes the analysis of the user's nights through the app-scoped ``sleepToleranceRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeSleepCaffeineAnalysis: ObserveSleepCaffeineAnalysisUseCase {
        get { self[ObserveSleepCaffeineAnalysisUseCaseKey.self] }
        set { self[ObserveSleepCaffeineAnalysisUseCaseKey.self] = newValue }
    }

    /// Observes the caffeine in the user when each of the last 31 nights began through the app-scoped
    /// ``sleepToleranceRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeCaffeineNights: ObserveCaffeineNightsUseCase {
        get { self[ObserveCaffeineNightsUseCaseKey.self] }
        set { self[ObserveCaffeineNightsUseCaseKey.self] = newValue }
    }

    /// Keeps the caffeine tolerance current through the app-scoped ``sleepToleranceRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var keepSleepToleranceCurrent: KeepSleepToleranceCurrentUseCase {
        get { self[KeepSleepToleranceCurrentUseCaseKey.self] }
        set { self[KeepSleepToleranceCurrentUseCaseKey.self] = newValue }
    }
}

/// Registers the one tolerance data source that ``SleepToleranceRepository`` and ``CaffeineDecayRepository`` share
/// (constitution Article I.15).
///
/// It has no `DependencyValues` property, because only repositories use data sources. The tolerance repository stores
/// through it, and the decay repository reads it through ``PersonalSleepThresholdDataSource``, so a store signals the
/// cutoff.
enum SleepToleranceDataSourceKey: DependencyKey {
    /// The app's tolerance file in Application Support. Under a UI test, a new temporary file, so UI tests never touch
    /// the device's tolerance.
    static let liveValue: any SleepToleranceDataSource = makeLiveValue(configuration: .current)

    /// A new temporary file.
    static let previewValue: any SleepToleranceDataSource = temporaryDataSource()

    /// A data source that reports an issue when a test uses it.
    static let testValue: any SleepToleranceDataSource = UnimplementedSleepToleranceDataSource()

    private static let logger = Logger(for: SleepToleranceDataSourceKey.self)

    /// The live data source for a launch with `configuration`: the app's file outside UI tests, and a new temporary
    /// one under a UI test.
    private static func makeLiveValue(configuration: UITestLaunchConfiguration) -> any SleepToleranceDataSource {
        guard !configuration.isUITest else { return temporaryDataSource() }
        do {
            return FileSleepToleranceDataSource(fileURL: try FileSleepToleranceDataSource.defaultFileURL())
        } catch {
            let error = error as NSError
            logger.fault(
                "Application Support is missing: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return temporaryDataSource()
        }
    }

    /// A data source over a new temporary file.
    private static func temporaryDataSource() -> FileSleepToleranceDataSource {
        FileSleepToleranceDataSource(
            fileURL: FileManager.default.temporaryDirectory
                .appending(path: UUID().uuidString, directoryHint: .isDirectory)
                .appending(path: "SleepTolerance.json"))
    }
}

/// Registers the app-scoped sleep tolerance repository.
///
/// It's internal so that the resting heart rate comparison, which also reads the Health data repository, is built
/// from the same repository as the use cases in this file, as the Architecture article's "Registering a repository
/// and its use cases" explains.
enum SleepToleranceRepositoryKey: DependencyKey {
    static let liveValue: any SleepToleranceRepository = makeLiveValue(configuration: .current)
    static let previewValue: any SleepToleranceRepository = makeRepository(
        health: UnavailableHealthDataSource(), authorization: RequestedHealthAccessDataSource(), isLive: false)
    static let testValue: any SleepToleranceRepository = UnimplementedSleepToleranceRepository()

    /// The live repository for a launch with `configuration`: over HealthKit outside UI tests, and over simulated
    /// Health data under one.
    private static func makeLiveValue(configuration: UITestLaunchConfiguration) -> LiveSleepToleranceRepository {
        let health: any SleepDataSource
        let authorization: any HealthAuthorizationDataSource
        if configuration.isUITest {
            health = SimulatedHealthDataSource(holding: configuration.healthData, clock: SystemClockDataSource())
            authorization = RequestedHealthAccessDataSource()
        } else {
            health = HealthKitSleepDataSource()
            authorization = HealthKitAuthorizationDataSource()
        }
        return makeRepository(health: health, authorization: authorization, isLive: true)
    }

    /// A repository over `health` and the demo's sleep, with the curve's half-life, on the system clock. It shares the
    /// other repositories' data sources: their live values when `isLive`, and their preview values otherwise.
    private static func makeRepository(
        health: any SleepDataSource, authorization: any HealthAuthorizationDataSource, isLive: Bool
    ) -> LiveSleepToleranceRepository {
        let clock = SystemClockDataSource()
        let profile = isLive ? ProfileDataSourceKey.liveValue : ProfileDataSourceKey.previewValue
        let estimates = isLive ? HalfLifeEstimateDataSourceKey.liveValue : HalfLifeEstimateDataSourceKey.previewValue
        return LiveSleepToleranceRepository(
            health: health, demo: DemoSleepDataSource(clock: clock), authorization: authorization,
            flag: isLive ? DemoHealthDataFlagDataSourceKey.liveValue : DemoHealthDataFlagDataSourceKey.previewValue,
            drinkLog: isLive ? DrinkLogDataSourceKey.liveValue : DrinkLogDataSourceKey.previewValue,
            halfLife: EstimatedHalfLifeDataSource(estimates: estimates, prior: profile),
            absorption: StandardAbsorptionRateDataSource(), bedtime: profile,
            tolerances: isLive ? SleepToleranceDataSourceKey.liveValue : SleepToleranceDataSourceKey.previewValue,
            clock: clock)
    }
}

// Each use case's values are built from the repository key's values directly, not through `@Dependency`, following
// the Architecture article's "Registering a repository and its use cases".
private enum ObserveSleepCaffeineAnalysisUseCaseKey: DependencyKey {
    static let liveValue = ObserveSleepCaffeineAnalysisUseCase(repository: SleepToleranceRepositoryKey.liveValue)
    static let previewValue = ObserveSleepCaffeineAnalysisUseCase(repository: SleepToleranceRepositoryKey.previewValue)
    static let testValue = ObserveSleepCaffeineAnalysisUseCase(repository: SleepToleranceRepositoryKey.testValue)
}

private enum ObserveCaffeineNightsUseCaseKey: DependencyKey {
    static let liveValue = ObserveCaffeineNightsUseCase(repository: SleepToleranceRepositoryKey.liveValue)
    static let previewValue = ObserveCaffeineNightsUseCase(repository: SleepToleranceRepositoryKey.previewValue)
    static let testValue = ObserveCaffeineNightsUseCase(repository: SleepToleranceRepositoryKey.testValue)
}

private enum KeepSleepToleranceCurrentUseCaseKey: DependencyKey {
    static let liveValue = KeepSleepToleranceCurrentUseCase(repository: SleepToleranceRepositoryKey.liveValue)
    static let previewValue = KeepSleepToleranceCurrentUseCase(repository: SleepToleranceRepositoryKey.previewValue)
    static let testValue = KeepSleepToleranceCurrentUseCase(repository: SleepToleranceRepositoryKey.testValue)
}

/// The sleep tolerance repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedSleepToleranceRepository: SleepToleranceRepository {
    func analysis() -> AsyncStream<SleepCaffeineAnalysis> {
        reportIssue("A test observed the sleep analysis without overriding \\.sleepToleranceRepository.")
        return AsyncStream { $0.finish() }
    }

    func caffeineNights(days: Int, in calendar: Calendar) -> AsyncStream<CaffeineNightHistory> {
        reportIssue("A test observed the caffeine nights without overriding \\.sleepToleranceRepository.")
        return AsyncStream { $0.finish() }
    }
}

private struct UnimplementedToleranceSourceError: Error {}

/// The tolerance data source in tests that haven't overridden a repository. Using it reports an issue.
private struct UnimplementedSleepToleranceDataSource: SleepToleranceDataSource {
    func storedTolerance() async throws -> SleepTolerance? {
        throw unimplemented("read the caffeine tolerance")
    }

    func store(_ tolerance: SleepTolerance?) async throws {
        throw unimplemented("stored the caffeine tolerance")
    }

    func changes() async -> AsyncStream<Void> {
        _ = unimplemented("observed the caffeine tolerance's changes")
        return AsyncStream { $0.finish() }
    }

    private func unimplemented(_ action: String) -> UnimplementedToleranceSourceError {
        reportIssue("A test \(action) through the tolerance data source without overriding a repository.")
        return UnimplementedToleranceSourceError()
    }
}
