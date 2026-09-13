//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LanguageModelDependencies
//

import ComposableArchitecture
import Foundation

extension DependencyValues {
    /// The app's language model repository (constitution Article I.15).
    ///
    /// Live, it's one app-scoped ``LiveLanguageModelRepository`` over ``FoundationModelLanguageModelDataSource``,
    /// whose tools read the app-scoped caffeine decay, drink log, and current time repositories. Under a UI test, it's
    /// over ``SimulatedLanguageModelDataSource``, which is unavailable unless the launch asked for it. In previews,
    /// the tools read the preview repositories, over an empty in-memory store. In tests, using it without overriding
    /// it reports an issue.
    var languageModelRepository: any LanguageModelRepository {
        get { self[LanguageModelRepositoryKey.self] }
        set { self[LanguageModelRepositoryKey.self] = newValue }
    }

    /// Observes whether the language model can be used, through the app-scoped ``languageModelRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeLanguageModelAvailability: ObserveLanguageModelAvailabilityUseCase {
        get { self[LanguageModelAvailabilityUseCaseKey.self] }
        set { self[LanguageModelAvailabilityUseCaseKey.self] = newValue }
    }

    /// Answers one instruction through the app-scoped ``languageModelRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var respondToInstruction: RespondToInstructionUseCase {
        get { self[RespondToInstructionUseCaseKey.self] }
        set { self[RespondToInstructionUseCaseKey.self] = newValue }
    }

    /// Writes the Insights tab's first finding through the app-scoped ``languageModelRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var writeInsight: WriteInsightUseCase {
        get { self[WriteInsightUseCaseKey.self] }
        set { self[WriteInsightUseCaseKey.self] = newValue }
    }
}

/// Registers the app-scoped language model repository.
///
/// It's internal so that the Insights tab's first card, whose use case also reads the sleep tolerance and insight
/// feedback repositories, is built from the same repository as the use cases in this file, as the Architecture
/// article's "Registering a repository and its use cases" explains.
enum LanguageModelRepositoryKey: DependencyKey {
    static let liveValue: any LanguageModelRepository = makeLiveValue(configuration: .current)
    static let previewValue: any LanguageModelRepository = LiveLanguageModelRepository(
        dataSource: FoundationModelLanguageModelDataSource(
            caffeineDecay: CaffeineDecayRepositoryKey.previewValue, drinkLog: DrinkLogRepositoryKey.previewValue,
            currentTime: CurrentTimeRepositoryKey.previewValue),
        clock: SystemClockDataSource())
    static let testValue: any LanguageModelRepository = UnimplementedLanguageModelRepository()

    /// The live repository for a launch with `configuration`: over the on-device model outside UI tests, and over the
    /// simulated one under a UI test, which is unavailable unless the test asked for it (DEP-LM-UI).
    static func makeLiveValue(configuration: UITestLaunchConfiguration) -> any LanguageModelRepository {
        guard configuration.isUITest else {
            return LiveLanguageModelRepository(
                dataSource: FoundationModelLanguageModelDataSource(
                    caffeineDecay: CaffeineDecayRepositoryKey.liveValue, drinkLog: DrinkLogRepositoryKey.liveValue,
                    currentTime: CurrentTimeRepositoryKey.liveValue),
                clock: SystemClockDataSource())
        }
        return LiveLanguageModelRepository(
            dataSource: SimulatedLanguageModelDataSource(
                isAvailable: configuration.usesSimulatedLanguageModel, calendar: .autoupdatingCurrent),
            clock: SystemClockDataSource())
    }
}

// Built from the repository key's values directly, not through `@Dependency`, following the Architecture article's
// "Registering a repository and its use cases".
private enum LanguageModelAvailabilityUseCaseKey: DependencyKey {
    static let liveValue = ObserveLanguageModelAvailabilityUseCase(repository: LanguageModelRepositoryKey.liveValue)
    static let previewValue = ObserveLanguageModelAvailabilityUseCase(
        repository: LanguageModelRepositoryKey.previewValue)
    static let testValue = ObserveLanguageModelAvailabilityUseCase(repository: LanguageModelRepositoryKey.testValue)
}

// Built from the repository key's values directly, not through `@Dependency`, following the Architecture article's
// "Registering a repository and its use cases".
private enum RespondToInstructionUseCaseKey: DependencyKey {
    static let liveValue = RespondToInstructionUseCase(repository: LanguageModelRepositoryKey.liveValue)
    static let previewValue = RespondToInstructionUseCase(repository: LanguageModelRepositoryKey.previewValue)
    static let testValue = RespondToInstructionUseCase(repository: LanguageModelRepositoryKey.testValue)
}

// Built from the repository key's values directly, not through `@Dependency`, following the Architecture article's
// "Registering a repository and its use cases".
private enum WriteInsightUseCaseKey: DependencyKey {
    static let liveValue = WriteInsightUseCase(repository: LanguageModelRepositoryKey.liveValue)
    static let previewValue = WriteInsightUseCase(repository: LanguageModelRepositoryKey.previewValue)
    static let testValue = WriteInsightUseCase(repository: LanguageModelRepositoryKey.testValue)
}

/// The error an unimplemented language model repository throws after reporting its issue.
private struct UnimplementedLanguageModel: Error {}

/// The language model repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedLanguageModelRepository: LanguageModelRepository {
    func availability() -> AsyncStream<LanguageModelAvailability> {
        reportIssue(
            "A test observed the language model's availability without overriding \\.languageModelRepository or "
                + "\\.observeLanguageModelAvailability.")
        return AsyncStream { $0.finish() }
    }

    func respond(to instruction: LanguageModelInstruction) async throws -> String {
        reportIssue(
            "A test responded to an instruction without overriding \\.languageModelRepository or "
                + "\\.respondToInstruction.")
        throw UnimplementedLanguageModel()
    }

    func writeInsight(_ request: InsightRequest) async throws -> Insight {
        reportIssue("A test wrote an insight without overriding \\.languageModelRepository or \\.writeInsight.")
        throw UnimplementedLanguageModel()
    }
}
