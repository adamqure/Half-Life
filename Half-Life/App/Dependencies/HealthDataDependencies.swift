//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HealthDataDependencies
//

import ComposableArchitecture
import Foundation
import OSLog

extension DependencyValues {
    /// The app's Health data repository (constitution Article I.15).
    ///
    /// Live, it's one app-scoped ``LiveHealthDataRepository`` over HealthKit and the demo data sources, with its switch
    /// in the shared ``DemoHealthDataFlagDataSourceKey`` data source, which the sleep tolerance repository also reads.
    /// Under a UI test, ``SimulatedHealthDataSource`` stands in for HealthKit, holding the Health data the launch
    /// environment chose, and the switch is in a new temporary file. In previews, Health holds nothing. In tests, using
    /// it without overriding it reports an issue.
    var healthDataRepository: any HealthDataRepository {
        get { self[HealthDataRepositoryKey.self] }
        set { self[HealthDataRepositoryKey.self] = newValue }
    }

    /// Observes today's Health summary through the app-scoped ``healthDataRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeHealthSummary: ObserveHealthSummaryUseCase {
        get { self[ObserveHealthSummaryUseCaseKey.self] }
        set { self[ObserveHealthSummaryUseCaseKey.self] = newValue }
    }

    /// Observes the demo Health data switch through the app-scoped ``healthDataRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeDemoHealthData: ObserveDemoHealthDataUseCase {
        get { self[ObserveDemoHealthDataUseCaseKey.self] }
        set { self[ObserveDemoHealthDataUseCaseKey.self] = newValue }
    }

    /// Turns the demo Health data switch on or off through the app-scoped ``healthDataRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var setDemoHealthData: SetDemoHealthDataUseCase {
        get { self[SetDemoHealthDataUseCaseKey.self] }
        set { self[SetDemoHealthDataUseCaseKey.self] = newValue }
    }

    /// Observes the sleep that followed each of the last 7 days through the app-scoped ``healthDataRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeSleepWeek: ObserveSleepWeekUseCase {
        get { self[ObserveSleepWeekUseCaseKey.self] }
        set { self[ObserveSleepWeekUseCaseKey.self] = newValue }
    }

    /// Observes the kinds of Health data with any data in the last 30 days through the app-scoped
    /// ``healthDataRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeAvailableHealthData: ObserveAvailableHealthDataUseCase {
        get { self[ObserveAvailableHealthDataUseCaseKey.self] }
        set { self[ObserveAvailableHealthDataUseCaseKey.self] = newValue }
    }

    /// Observes the resting heart rate on the days after a caffeine night, against the other days, through the
    /// app-scoped ``sleepToleranceRepository`` and ``healthDataRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeRestingHeartRateComparison: ObserveRestingHeartRateComparisonUseCase {
        get { self[HeartRateComparisonUseCaseKey.self] }
        set { self[HeartRateComparisonUseCaseKey.self] = newValue }
    }

    /// Observes the steps on the days after a caffeine night, against the other days, through the app-scoped
    /// ``sleepToleranceRepository`` and ``healthDataRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeStepsComparison: ObserveStepsComparisonUseCase {
        get { self[ObserveStepsComparisonUseCaseKey.self] }
        set { self[ObserveStepsComparisonUseCaseKey.self] = newValue }
    }
}

/// Registers the one demo Health data switch that ``HealthDataRepository`` and ``SleepToleranceRepository`` share, so
/// turning it on in Settings reaches both (constitution Article I.15).
enum DemoHealthDataFlagDataSourceKey: DependencyKey {
    /// The app's switch file in Application Support. Under a UI test, a new temporary file, so UI tests never touch the
    /// device's switch.
    static let liveValue: any DemoHealthDataFlagDataSource = makeLiveValue(configuration: .current)

    /// A switch in a new temporary file.
    static let previewValue: any DemoHealthDataFlagDataSource = temporaryFlag()

    /// A switch in a new temporary file. Only live and preview repositories read it.
    static let testValue: any DemoHealthDataFlagDataSource = temporaryFlag()

    private static let logger = Logger(for: DemoHealthDataFlagDataSourceKey.self)

    /// The live switch for a launch with `configuration`: the app's file outside UI tests, and a new temporary one
    /// under a UI test.
    private static func makeLiveValue(configuration: UITestLaunchConfiguration) -> any DemoHealthDataFlagDataSource {
        guard !configuration.isUITest else { return temporaryFlag() }
        do {
            return FileDemoHealthDataFlagDataSource(fileURL: try FileDemoHealthDataFlagDataSource.defaultFileURL())
        } catch {
            let error = error as NSError
            logger.fault(
                "Application Support is missing: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return temporaryFlag()
        }
    }

    /// A switch in a new temporary file.
    private static func temporaryFlag() -> FileDemoHealthDataFlagDataSource {
        FileDemoHealthDataFlagDataSource(
            fileURL: FileManager.default.temporaryDirectory
                .appending(path: UUID().uuidString, directoryHint: .isDirectory)
                .appending(path: "DemoHealthData.json"))
    }
}

/// Registers the app-scoped Health data repository. It's private, because only the use cases in this file are built
/// from it.
private enum HealthDataRepositoryKey: DependencyKey {
    static let liveValue: any HealthDataRepository = makeLiveValue(configuration: .current)
    static let previewValue: any HealthDataRepository = makeRepository(
        live: LiveHealthDataRepository.Sources(UnavailableHealthDataSource()),
        authorization: RequestedHealthAccessDataSource(), flag: DemoHealthDataFlagDataSourceKey.previewValue)
    static let testValue: any HealthDataRepository = UnimplementedHealthDataRepository()

    /// The live repository for a launch with `configuration`: over HealthKit outside UI tests, and over simulated
    /// Health data under one.
    private static func makeLiveValue(configuration: UITestLaunchConfiguration) -> LiveHealthDataRepository {
        guard configuration.isUITest else {
            return makeRepository(
                live: LiveHealthDataRepository.Sources(
                    sleep: HealthKitSleepDataSource(), steps: HealthKitStepCountDataSource(),
                    restingHeartRate: HealthKitRestingHeartRateDataSource()),
                authorization: HealthKitAuthorizationDataSource(), flag: DemoHealthDataFlagDataSourceKey.liveValue)
        }
        return makeRepository(
            live: LiveHealthDataRepository.Sources(
                SimulatedHealthDataSource(holding: configuration.healthData, clock: SystemClockDataSource())),
            authorization: RequestedHealthAccessDataSource(), flag: DemoHealthDataFlagDataSourceKey.liveValue)
    }

    /// A repository over `live` and the demo data sources, on the system clock.
    private static func makeRepository(
        live: LiveHealthDataRepository.Sources, authorization: any HealthAuthorizationDataSource,
        flag: any DemoHealthDataFlagDataSource
    ) -> LiveHealthDataRepository {
        let clock = SystemClockDataSource()
        return LiveHealthDataRepository(
            live: live,
            demo: LiveHealthDataRepository.Sources(
                sleep: DemoSleepDataSource(clock: clock), steps: DemoStepCountDataSource(clock: clock),
                restingHeartRate: DemoRestingHeartRateDataSource(clock: clock)),
            authorization: authorization, flag: flag, clock: clock)
    }

}

// Each use case's values are built from the repository key's values directly, not through `@Dependency`, following
// the Architecture article's "Registering a repository and its use cases".
private enum ObserveHealthSummaryUseCaseKey: DependencyKey {
    static let liveValue = ObserveHealthSummaryUseCase(repository: HealthDataRepositoryKey.liveValue)
    static let previewValue = ObserveHealthSummaryUseCase(repository: HealthDataRepositoryKey.previewValue)
    static let testValue = ObserveHealthSummaryUseCase(repository: HealthDataRepositoryKey.testValue)
}

private enum ObserveDemoHealthDataUseCaseKey: DependencyKey {
    static let liveValue = ObserveDemoHealthDataUseCase(repository: HealthDataRepositoryKey.liveValue)
    static let previewValue = ObserveDemoHealthDataUseCase(repository: HealthDataRepositoryKey.previewValue)
    static let testValue = ObserveDemoHealthDataUseCase(repository: HealthDataRepositoryKey.testValue)
}

private enum SetDemoHealthDataUseCaseKey: DependencyKey {
    static let liveValue = SetDemoHealthDataUseCase(repository: HealthDataRepositoryKey.liveValue)
    static let previewValue = SetDemoHealthDataUseCase(repository: HealthDataRepositoryKey.previewValue)
    static let testValue = SetDemoHealthDataUseCase(repository: HealthDataRepositoryKey.testValue)
}

private enum ObserveSleepWeekUseCaseKey: DependencyKey {
    static let liveValue = ObserveSleepWeekUseCase(repository: HealthDataRepositoryKey.liveValue)
    static let previewValue = ObserveSleepWeekUseCase(repository: HealthDataRepositoryKey.previewValue)
    static let testValue = ObserveSleepWeekUseCase(repository: HealthDataRepositoryKey.testValue)
}

private enum ObserveAvailableHealthDataUseCaseKey: DependencyKey {
    static let liveValue = ObserveAvailableHealthDataUseCase(repository: HealthDataRepositoryKey.liveValue)
    static let previewValue = ObserveAvailableHealthDataUseCase(repository: HealthDataRepositoryKey.previewValue)
    static let testValue = ObserveAvailableHealthDataUseCase(repository: HealthDataRepositoryKey.testValue)
}

// Built from both repository keys' values directly, not through `@Dependency`, following the Architecture
// article's "Registering a repository and its use cases". `SleepToleranceRepositoryKey` is internal for this.
private enum HeartRateComparisonUseCaseKey: DependencyKey {
    static let liveValue = ObserveRestingHeartRateComparisonUseCase(
        sleepTolerance: SleepToleranceRepositoryKey.liveValue, healthData: HealthDataRepositoryKey.liveValue)
    static let previewValue = ObserveRestingHeartRateComparisonUseCase(
        sleepTolerance: SleepToleranceRepositoryKey.previewValue, healthData: HealthDataRepositoryKey.previewValue)
    static let testValue = ObserveRestingHeartRateComparisonUseCase(
        sleepTolerance: SleepToleranceRepositoryKey.testValue, healthData: HealthDataRepositoryKey.testValue)
}

// Built from both repository keys' values directly, like `HeartRateComparisonUseCaseKey`.
private enum ObserveStepsComparisonUseCaseKey: DependencyKey {
    static let liveValue = ObserveStepsComparisonUseCase(
        sleepTolerance: SleepToleranceRepositoryKey.liveValue, healthData: HealthDataRepositoryKey.liveValue)
    static let previewValue = ObserveStepsComparisonUseCase(
        sleepTolerance: SleepToleranceRepositoryKey.previewValue, healthData: HealthDataRepositoryKey.previewValue)
    static let testValue = ObserveStepsComparisonUseCase(
        sleepTolerance: SleepToleranceRepositoryKey.testValue, healthData: HealthDataRepositoryKey.testValue)
}

private struct UnimplementedHealthDataError: Error {}

/// The Health data repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedHealthDataRepository: HealthDataRepository {
    func summary(in calendar: Calendar) -> AsyncStream<HealthSummary> {
        reportIssue("A test observed the Health summary without overriding \\.healthDataRepository.")
        return AsyncStream { $0.finish() }
    }

    func usesDemoData() -> AsyncStream<Bool> {
        reportIssue("A test observed the demo Health data switch without overriding \\.healthDataRepository.")
        return AsyncStream { $0.finish() }
    }

    func setUsesDemoData(_ isOn: Bool) async throws {
        reportIssue("A test set the demo Health data switch without overriding \\.healthDataRepository.")
        throw UnimplementedHealthDataError()
    }

    func sleepHistory(days: Int, in calendar: Calendar) -> AsyncStream<SleepHistory> {
        reportIssue(
            "A test observed the sleep history without overriding \\.healthDataRepository or \\.observeSleepWeek.")
        return AsyncStream { $0.finish() }
    }

    func availableKinds(days: Int, in calendar: Calendar) -> AsyncStream<Set<HealthDataKind>> {
        reportIssue(
            "A test observed the available Health data without overriding \\.healthDataRepository or "
                + "\\.observeAvailableHealthData.")
        return AsyncStream { $0.finish() }
    }

    func restingHeartRates(days: Int, in calendar: Calendar) -> AsyncStream<RestingHeartRateHistory> {
        reportIssue("A test observed the resting heart rates without overriding \\.healthDataRepository.")
        return AsyncStream { $0.finish() }
    }

    func stepHistory(days: Int, in calendar: Calendar) -> AsyncStream<StepHistory> {
        reportIssue("A test observed the step history without overriding \\.healthDataRepository.")
        return AsyncStream { $0.finish() }
    }
}
