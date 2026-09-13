//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life HalfLifeEstimateDependencies
//

import ComposableArchitecture
import Foundation
import OSLog

extension DependencyValues {
    /// The app's half-life estimate repository (constitution Article I.15).
    ///
    /// Live, it's one app-scoped ``LiveHalfLifeEstimateRepository``. It reads drinks from the shared
    /// ``DrinkLogDataSourceKey`` data source, the survey's half-life from the shared ``ProfileDataSourceKey`` data
    /// source, and sleep, steps, and resting heart rate from HealthKit. It stores the estimate in the shared
    /// ``HalfLifeEstimateDataSourceKey`` data source, where the decay model reads it. Under a UI test and in previews,
    /// ``UnavailableHealthDataSource`` stands in for HealthKit, so neither reads real Health data. In tests, using it
    /// without overriding it reports an issue.
    var halfLifeEstimateRepository: any HalfLifeEstimateRepository {
        get { self[HalfLifeEstimateRepositoryKey.self] }
        set { self[HalfLifeEstimateRepositoryKey.self] = newValue }
    }

    /// Observes the personal half-life estimate through the app-scoped ``halfLifeEstimateRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeHalfLifeEstimate: ObserveHalfLifeEstimateUseCase {
        get { self[ObserveHalfLifeEstimateUseCaseKey.self] }
        set { self[ObserveHalfLifeEstimateUseCaseKey.self] = newValue }
    }

    /// Refreshes the personal half-life estimate through the app-scoped ``halfLifeEstimateRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var refreshHalfLifeEstimate: RefreshHalfLifeEstimateUseCase {
        get { self[RefreshHalfLifeEstimateUseCaseKey.self] }
        set { self[RefreshHalfLifeEstimateUseCaseKey.self] = newValue }
    }
}

/// Registers the one estimate data source that ``HalfLifeEstimateRepository`` and ``CaffeineDecayRepository`` share
/// (constitution Article I.15).
///
/// It has no `DependencyValues` property, because only repositories use data sources. The estimate repository stores
/// through it, and the decay repository reads it through ``EstimatedHalfLifeDataSource``, so a store signals the
/// curve.
enum HalfLifeEstimateDataSourceKey: DependencyKey {
    /// The app's estimate file in Application Support. Under a UI test, a new temporary file, so UI tests never touch
    /// the device's estimate.
    static let liveValue: any HalfLifeEstimateDataSource = makeLiveValue(configuration: .current)

    /// A new temporary file.
    static let previewValue: any HalfLifeEstimateDataSource = temporaryDataSource()

    /// A data source that reports an issue when a test uses it.
    static let testValue: any HalfLifeEstimateDataSource = UnimplementedHalfLifeEstimateDataSource()

    private static let logger = Logger(for: HalfLifeEstimateDataSourceKey.self)

    /// The live data source for a launch with `configuration`.
    ///
    /// - Parameter configuration: How a UI test asked the app to start, if one did.
    /// - Returns: The app's estimate file outside UI tests, or a new temporary one under a UI test.
    static func makeLiveValue(configuration: UITestLaunchConfiguration) -> any HalfLifeEstimateDataSource {
        guard !configuration.isUITest else { return temporaryDataSource() }
        do {
            return FileHalfLifeEstimateDataSource(fileURL: try FileHalfLifeEstimateDataSource.defaultFileURL())
        } catch {
            let error = error as NSError
            logger.fault(
                "Application Support is missing: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return temporaryDataSource()
        }
    }

    /// A data source over a new temporary file.
    static func temporaryDataSource() -> FileHalfLifeEstimateDataSource {
        FileHalfLifeEstimateDataSource(
            fileURL: FileManager.default.temporaryDirectory
                .appending(path: UUID().uuidString, directoryHint: .isDirectory)
                .appending(path: "HalfLifeEstimate.json"))
    }
}

/// Registers the app-scoped estimate repository. It's private, because only the use cases in this file are built
/// from it.
private enum HalfLifeEstimateRepositoryKey: DependencyKey {
    static let liveValue: any HalfLifeEstimateRepository = makeRepository(
        drinkLog: DrinkLogDataSourceKey.liveValue, prior: ProfileDataSourceKey.liveValue,
        estimates: HalfLifeEstimateDataSourceKey.liveValue, readsHealth: !UITestLaunchConfiguration.current.isUITest)
    static let previewValue: any HalfLifeEstimateRepository = makeRepository(
        drinkLog: DrinkLogDataSourceKey.previewValue, prior: ProfileDataSourceKey.previewValue,
        estimates: HalfLifeEstimateDataSourceKey.previewValue, readsHealth: false)
    static let testValue: any HalfLifeEstimateRepository = UnimplementedHalfLifeEstimateRepository()

    /// A repository over HealthKit when `readsHealth` is true, and over ``UnavailableHealthDataSource`` otherwise.
    private static func makeRepository(
        drinkLog: any DrinkLogDataSource, prior: any HalfLifeDataSource, estimates: any HalfLifeEstimateDataSource,
        readsHealth: Bool
    ) -> LiveHalfLifeEstimateRepository {
        let sleep: any SleepDataSource
        let steps: any StepCountDataSource
        let restingHeartRate: any RestingHeartRateDataSource
        if readsHealth {
            sleep = HealthKitSleepDataSource()
            steps = HealthKitStepCountDataSource()
            restingHeartRate = HealthKitRestingHeartRateDataSource()
        } else {
            let unavailable = UnavailableHealthDataSource()
            sleep = unavailable
            steps = unavailable
            restingHeartRate = unavailable
        }
        return LiveHalfLifeEstimateRepository(
            drinkLog: drinkLog, sleep: sleep, steps: steps, restingHeartRate: restingHeartRate, prior: prior,
            estimates: estimates, absorption: StandardAbsorptionRateDataSource(), clock: SystemClockDataSource())
    }
}

// Each use case's values are built from the repository key's values directly, not through `@Dependency`, following
// the Architecture article's "Registering a repository and its use cases".
private enum ObserveHalfLifeEstimateUseCaseKey: DependencyKey {
    static let liveValue = ObserveHalfLifeEstimateUseCase(repository: HalfLifeEstimateRepositoryKey.liveValue)
    static let previewValue = ObserveHalfLifeEstimateUseCase(repository: HalfLifeEstimateRepositoryKey.previewValue)
    static let testValue = ObserveHalfLifeEstimateUseCase(repository: HalfLifeEstimateRepositoryKey.testValue)
}

private enum RefreshHalfLifeEstimateUseCaseKey: DependencyKey {
    static let liveValue = RefreshHalfLifeEstimateUseCase(repository: HalfLifeEstimateRepositoryKey.liveValue)
    static let previewValue = RefreshHalfLifeEstimateUseCase(repository: HalfLifeEstimateRepositoryKey.previewValue)
    static let testValue = RefreshHalfLifeEstimateUseCase(repository: HalfLifeEstimateRepositoryKey.testValue)
}

/// The estimate repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedHalfLifeEstimateRepository: HalfLifeEstimateRepository {
    func estimate() -> AsyncStream<HalfLifeEstimate> {
        reportIssue("A test observed the half-life estimate without overriding \\.halfLifeEstimateRepository.")
        return AsyncStream { $0.finish() }
    }

    func refresh() async {
        reportIssue("A test refreshed the half-life estimate without overriding \\.halfLifeEstimateRepository.")
    }
}

private struct UnimplementedEstimateSourceError: Error {}

/// The estimate data source in tests that haven't overridden a repository. Using it reports an issue.
private struct UnimplementedHalfLifeEstimateDataSource: HalfLifeEstimateDataSource {
    func storedEstimate() async throws -> HalfLifeEstimate? {
        throw unimplemented("read the half-life estimate")
    }

    func store(_ estimate: HalfLifeEstimate) async throws {
        throw unimplemented("stored the half-life estimate")
    }

    func changes() async -> AsyncStream<Void> {
        _ = unimplemented("observed the half-life estimate's changes")
        return AsyncStream { $0.finish() }
    }

    private func unimplemented(_ action: String) -> UnimplementedEstimateSourceError {
        reportIssue("A test \(action) through the estimate data source without overriding a repository.")
        return UnimplementedEstimateSourceError()
    }
}
