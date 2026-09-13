//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineDecayDependencies
//

import ComposableArchitecture
import Foundation

extension DependencyValues {
    /// The app's caffeine decay repository (constitution Article I.15).
    ///
    /// Live and in previews, it's one app-scoped ``LiveCaffeineDecayRepository``. It reads drinks from the shared
    /// ``DrinkLogDataSourceKey`` data source, and the bedtime from the shared ``ProfileDataSourceKey`` data source. It
    /// reads the half-life through ``EstimatedHalfLifeDataSource``: the personal estimate from the shared
    /// ``HalfLifeEstimateDataSourceKey`` data source, or the survey's from the profile. It reads the sleep threshold
    /// through ``PersonalSleepThresholdDataSource``: the caffeine tolerance from the shared
    /// ``SleepToleranceDataSourceKey`` data source, or the standard 40 mg. It reads the absorption rate from
    /// ``StandardAbsorptionRateDataSource``, and the time from ``SystemClockDataSource``. In tests, using it without
    /// overriding it reports an issue.
    var caffeineDecayRepository: any CaffeineDecayRepository {
        get { self[CaffeineDecayRepositoryKey.self] }
        set { self[CaffeineDecayRepositoryKey.self] = newValue }
    }

    /// Observes the active caffeine curve through the app-scoped ``caffeineDecayRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeCaffeineCurve: ObserveCaffeineCurveUseCase {
        get { self[ObserveCaffeineCurveUseCaseKey.self] }
        set { self[ObserveCaffeineCurveUseCaseKey.self] = newValue }
    }

    /// Observes the caffeine status through the app-scoped ``caffeineDecayRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeCaffeineStatus: ObserveCaffeineStatusUseCase {
        get { self[ObserveCaffeineStatusUseCaseKey.self] }
        set { self[ObserveCaffeineStatusUseCaseKey.self] = newValue }
    }

    /// Observes the caffeine cutoff through the app-scoped ``caffeineDecayRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeCaffeineCutoff: ObserveCaffeineCutoffUseCase {
        get { self[ObserveCaffeineCutoffUseCaseKey.self] }
        set { self[ObserveCaffeineCutoffUseCaseKey.self] = newValue }
    }

    /// Observes the cutoffs for the next several nights through the app-scoped ``caffeineDecayRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeUpcomingCutoffs: ObserveUpcomingCutoffsUseCase {
        get { self[ObserveUpcomingCutoffsUseCaseKey.self] }
        set { self[ObserveUpcomingCutoffsUseCaseKey.self] = newValue }
    }

    /// Observes tonight's sleep window through the app-scoped ``caffeineDecayRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeSleepWindow: ObserveSleepWindowUseCase {
        get { self[ObserveSleepWindowUseCaseKey.self] }
        set { self[ObserveSleepWindowUseCaseKey.self] = newValue }
    }

    /// Observes the drink composer's cutoff warning through the app-scoped ``caffeineDecayRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeCutoffWarning: ObserveCutoffWarningUseCase {
        get { self[ObserveCutoffWarningUseCaseKey.self] }
        set { self[ObserveCutoffWarningUseCaseKey.self] = newValue }
    }
}

// Built from the repository key's values directly, not through `@Dependency`, following the Architecture article's
// "Registering a repository and its use cases".
private enum ObserveCutoffWarningUseCaseKey: DependencyKey {
    static let liveValue = ObserveCutoffWarningUseCase(repository: CaffeineDecayRepositoryKey.liveValue)
    static let previewValue = ObserveCutoffWarningUseCase(repository: CaffeineDecayRepositoryKey.previewValue)
    static let testValue = ObserveCutoffWarningUseCase(repository: CaffeineDecayRepositoryKey.testValue)
}

// Built from the repository key's values directly, not through `@Dependency`, following the Architecture article's
// "Registering a repository and its use cases".
private enum ObserveSleepWindowUseCaseKey: DependencyKey {
    static let liveValue = ObserveSleepWindowUseCase(repository: CaffeineDecayRepositoryKey.liveValue)
    static let previewValue = ObserveSleepWindowUseCase(repository: CaffeineDecayRepositoryKey.previewValue)
    static let testValue = ObserveSleepWindowUseCase(repository: CaffeineDecayRepositoryKey.testValue)
}

// Built from the repository key's values directly, not through `@Dependency`, following the Architecture article's
// "Registering a repository and its use cases".
private enum ObserveUpcomingCutoffsUseCaseKey: DependencyKey {
    static let liveValue = ObserveUpcomingCutoffsUseCase(repository: CaffeineDecayRepositoryKey.liveValue)
    static let previewValue = ObserveUpcomingCutoffsUseCase(repository: CaffeineDecayRepositoryKey.previewValue)
    static let testValue = ObserveUpcomingCutoffsUseCase(repository: CaffeineDecayRepositoryKey.testValue)
}

/// Registers the app-scoped caffeine decay repository.
///
/// It's internal so that the language model's tools can read the same repository as the use cases in this file, as
/// the Architecture article's "Registering a repository and its use cases" explains.
enum CaffeineDecayRepositoryKey: DependencyKey {
    static let liveValue: any CaffeineDecayRepository = LiveCaffeineDecayRepository(
        drinkLog: DrinkLogDataSourceKey.liveValue,
        halfLife: EstimatedHalfLifeDataSource(
            estimates: HalfLifeEstimateDataSourceKey.liveValue, prior: ProfileDataSourceKey.liveValue),
        absorption: StandardAbsorptionRateDataSource(), bedtime: ProfileDataSourceKey.liveValue,
        clock: SystemClockDataSource(),
        threshold: PersonalSleepThresholdDataSource(tolerances: SleepToleranceDataSourceKey.liveValue))
    static let previewValue: any CaffeineDecayRepository = LiveCaffeineDecayRepository(
        drinkLog: DrinkLogDataSourceKey.previewValue,
        halfLife: EstimatedHalfLifeDataSource(
            estimates: HalfLifeEstimateDataSourceKey.previewValue, prior: ProfileDataSourceKey.previewValue),
        absorption: StandardAbsorptionRateDataSource(), bedtime: ProfileDataSourceKey.previewValue,
        clock: SystemClockDataSource(),
        threshold: PersonalSleepThresholdDataSource(tolerances: SleepToleranceDataSourceKey.previewValue))
    static let testValue: any CaffeineDecayRepository = UnimplementedCaffeineDecayRepository()
}

// Built from the repository key's values directly, not through `@Dependency`, following the Architecture article's
// "Registering a repository and its use cases".
private enum ObserveCaffeineStatusUseCaseKey: DependencyKey {
    static let liveValue = ObserveCaffeineStatusUseCase(repository: CaffeineDecayRepositoryKey.liveValue)
    static let previewValue = ObserveCaffeineStatusUseCase(repository: CaffeineDecayRepositoryKey.previewValue)
    static let testValue = ObserveCaffeineStatusUseCase(repository: CaffeineDecayRepositoryKey.testValue)
}

// Built from the repository key's values directly, not through `@Dependency`, following the Architecture article's
// "Registering a repository and its use cases".
private enum ObserveCaffeineCurveUseCaseKey: DependencyKey {
    static let liveValue = ObserveCaffeineCurveUseCase(repository: CaffeineDecayRepositoryKey.liveValue)
    static let previewValue = ObserveCaffeineCurveUseCase(repository: CaffeineDecayRepositoryKey.previewValue)
    static let testValue = ObserveCaffeineCurveUseCase(repository: CaffeineDecayRepositoryKey.testValue)
}

/// The decay repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedCaffeineDecayRepository: CaffeineDecayRepository {
    func curve() -> AsyncStream<[CaffeineLevel]> {
        reportIssue("A test observed the caffeine curve without overriding \\.caffeineDecayRepository.")
        return AsyncStream { $0.finish() }
    }

    func status(in calendar: Calendar) -> AsyncStream<CaffeineStatus> {
        reportIssue("A test observed the caffeine status without overriding \\.caffeineDecayRepository.")
        return AsyncStream { $0.finish() }
    }

    func cutoff(in calendar: Calendar) -> AsyncStream<CaffeineCutoff> {
        reportIssue("A test observed the caffeine cutoff without overriding \\.caffeineDecayRepository.")
        return AsyncStream { $0.finish() }
    }

    func upcomingCutoffs(nights: Int, in calendar: Calendar) -> AsyncStream<[CaffeineCutoff]> {
        reportIssue("A test observed the upcoming cutoffs without overriding \\.caffeineDecayRepository.")
        return AsyncStream { $0.finish() }
    }

    func sleepWindow(in calendar: Calendar) -> AsyncStream<SleepWindow> {
        reportIssue("A test observed the sleep window without overriding \\.caffeineDecayRepository.")
        return AsyncStream { $0.finish() }
    }
    func cutoffWarning(
        for drink: FavouriteDrink, secondsAgo: TimeInterval, in calendar: Calendar
    ) -> AsyncStream<CutoffWarning?> {
        reportIssue("A test observed the cutoff warning without overriding \\.caffeineDecayRepository.")
        return AsyncStream { $0.finish() }
    }
}

// Built from the repository key's values directly, not through `@Dependency`, following the Architecture article's
// "Registering a repository and its use cases".
private enum ObserveCaffeineCutoffUseCaseKey: DependencyKey {
    static let liveValue = ObserveCaffeineCutoffUseCase(repository: CaffeineDecayRepositoryKey.liveValue)
    static let previewValue = ObserveCaffeineCutoffUseCase(repository: CaffeineDecayRepositoryKey.previewValue)
    static let testValue = ObserveCaffeineCutoffUseCase(repository: CaffeineDecayRepositoryKey.testValue)
}
