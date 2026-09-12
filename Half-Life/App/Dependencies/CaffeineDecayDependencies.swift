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
    /// ``DrinkLogDataSourceKey`` data source, the half-life from ``StandardHalfLifeDataSource``, the absorption rate
    /// from ``StandardAbsorptionRateDataSource``, the bedtime from ``StandardBedtimeDataSource``, and the time from
    /// ``SystemClockDataSource``. In tests, using it without overriding it reports an issue.
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
}

/// Registers the app-scoped caffeine decay repository. It's private, because only the use cases in this file are
/// built from it.
private enum CaffeineDecayRepositoryKey: DependencyKey {
    static let liveValue: any CaffeineDecayRepository = LiveCaffeineDecayRepository(
        drinkLog: DrinkLogDataSourceKey.liveValue, halfLife: StandardHalfLifeDataSource(),
        absorption: StandardAbsorptionRateDataSource(), bedtime: StandardBedtimeDataSource(),
        clock: SystemClockDataSource())
    static let previewValue: any CaffeineDecayRepository = LiveCaffeineDecayRepository(
        drinkLog: DrinkLogDataSourceKey.previewValue, halfLife: StandardHalfLifeDataSource(),
        absorption: StandardAbsorptionRateDataSource(), bedtime: StandardBedtimeDataSource(),
        clock: SystemClockDataSource())
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
}
