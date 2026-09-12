//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CurrentTimeDependencies
//

import ComposableArchitecture
import Foundation

extension DependencyValues {
    /// The app's current time repository (constitution Article I.15).
    ///
    /// Live and in previews, it's one app-scoped ``LiveCurrentTimeRepository`` that reads the system clock. In tests,
    /// using it without overriding it reports an issue.
    var currentTimeRepository: any CurrentTimeRepository {
        get { self[CurrentTimeRepositoryKey.self] }
        set { self[CurrentTimeRepositoryKey.self] = newValue }
    }

    /// Observes the time of day through the app-scoped ``currentTimeRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeTimeOfDay: ObserveTimeOfDayUseCase {
        get { self[ObserveTimeOfDayUseCaseKey.self] }
        set { self[ObserveTimeOfDayUseCaseKey.self] = newValue }
    }
}

/// Registers the app-scoped current time repository.
///
/// It's internal so that every use case that reads the time can be built from these values directly. Dependency
/// values are cached, so a use case that looked its repository up through `@Dependency` would capture whichever
/// repository was current the first time, including a test's override.
enum CurrentTimeRepositoryKey: DependencyKey {
    /// The one app-scoped repository, reading the system clock.
    static let liveValue: any CurrentTimeRepository = LiveCurrentTimeRepository(dataSource: SystemClockDataSource())
    /// The live repository. Previews show the real time.
    static let previewValue: any CurrentTimeRepository = liveValue
    /// A repository that reports an issue when a test uses it without overriding it.
    static let testValue: any CurrentTimeRepository = UnimplementedCurrentTimeRepository()
}

private enum ObserveTimeOfDayUseCaseKey: DependencyKey {
    static let liveValue = ObserveTimeOfDayUseCase(currentTime: CurrentTimeRepositoryKey.liveValue)
    static let previewValue = ObserveTimeOfDayUseCase(currentTime: CurrentTimeRepositoryKey.previewValue)
    static let testValue = ObserveTimeOfDayUseCase(currentTime: CurrentTimeRepositoryKey.testValue)
}

/// The current time repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedCurrentTimeRepository: CurrentTimeRepository {
    func now() -> Date {
        reportIssue("A test read the current time without overriding \\.currentTimeRepository.")
        return Date(timeIntervalSinceReferenceDate: 0)
    }

    func currentTime() -> AsyncStream<Date> {
        reportIssue("A test observed the current time without overriding \\.currentTimeRepository.")
        return AsyncStream { $0.finish() }
    }
}
