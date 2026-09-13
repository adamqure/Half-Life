//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life InsightFeedbackDependencies
//

import ComposableArchitecture
import Foundation

extension DependencyValues {
    /// The app's insight feedback repository (constitution Article I.15).
    ///
    /// Live, it's one app-scoped ``LiveInsightFeedbackRepository`` over ``FileInsightFeedbackDataSource`` in
    /// Application Support. Under a UI test and in previews, the file is a new temporary one, so they never touch the
    /// device's answers. In tests, using it without overriding it reports an issue.
    var insightFeedbackRepository: any InsightFeedbackRepository {
        get { self[InsightFeedbackRepositoryKey.self] }
        set { self[InsightFeedbackRepositoryKey.self] = newValue }
    }

    /// Observes the "Feel right?" answers through the app-scoped ``insightFeedbackRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeInsightFeedback: ObserveInsightFeedbackUseCase {
        get { self[ObserveInsightFeedbackUseCaseKey.self] }
        set { self[ObserveInsightFeedbackUseCaseKey.self] = newValue }
    }

    /// Stores a "Feel right?" answer, at the current time, through the app-scoped ``insightFeedbackRepository``.
    ///
    /// In tests, using it without overriding it reports an issue.
    var recordInsightFeedback: RecordInsightFeedbackUseCase {
        get { self[RecordInsightFeedbackUseCaseKey.self] }
        set { self[RecordInsightFeedbackUseCaseKey.self] = newValue }
    }

    /// Observes what the Insights tab's first card shows, through the app-scoped sleep tolerance, insight feedback, and
    /// language model repositories.
    ///
    /// In tests, using it without overriding it reports an issue.
    var observeInsightCard: ObserveInsightCardUseCase {
        get { self[ObserveInsightCardUseCaseKey.self] }
        set { self[ObserveInsightCardUseCaseKey.self] = newValue }
    }
}

/// Registers the app-scoped insight feedback repository. It's private, because only the use cases in this file are
/// built from it.
private enum InsightFeedbackRepositoryKey: DependencyKey {
    static let liveValue: any InsightFeedbackRepository = LiveInsightFeedbackRepository(
        dataSource: UITestLaunchConfiguration.current.isUITest
            ? FileInsightFeedbackDataSource(fileURL: temporaryFile()) : FileInsightFeedbackDataSource())
    static let previewValue: any InsightFeedbackRepository = LiveInsightFeedbackRepository(
        dataSource: FileInsightFeedbackDataSource(fileURL: temporaryFile()))
    static let testValue: any InsightFeedbackRepository = UnimplementedInsightFeedbackRepository()

    /// A file in a new temporary directory, so UI tests and previews never touch the device's answers.
    private static func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "InsightFeedback.json")
    }
}

// Each use case's values are built from the repository key's values directly, not through `@Dependency`, following
// the Architecture article's "Registering a repository and its use cases".
private enum ObserveInsightFeedbackUseCaseKey: DependencyKey {
    static let liveValue = ObserveInsightFeedbackUseCase(repository: InsightFeedbackRepositoryKey.liveValue)
    static let previewValue = ObserveInsightFeedbackUseCase(repository: InsightFeedbackRepositoryKey.previewValue)
    static let testValue = ObserveInsightFeedbackUseCase(repository: InsightFeedbackRepositoryKey.testValue)
}

private enum RecordInsightFeedbackUseCaseKey: DependencyKey {
    static let liveValue = RecordInsightFeedbackUseCase(
        currentTime: CurrentTimeRepositoryKey.liveValue, repository: InsightFeedbackRepositoryKey.liveValue)
    static let previewValue = RecordInsightFeedbackUseCase(
        currentTime: CurrentTimeRepositoryKey.previewValue, repository: InsightFeedbackRepositoryKey.previewValue)
    static let testValue = RecordInsightFeedbackUseCase(
        currentTime: CurrentTimeRepositoryKey.testValue, repository: InsightFeedbackRepositoryKey.testValue)
}

private enum ObserveInsightCardUseCaseKey: DependencyKey {
    static let liveValue = ObserveInsightCardUseCase(
        sleepTolerance: SleepToleranceRepositoryKey.liveValue, insightFeedback: InsightFeedbackRepositoryKey.liveValue,
        languageModel: LanguageModelRepositoryKey.liveValue)
    static let previewValue = ObserveInsightCardUseCase(
        sleepTolerance: SleepToleranceRepositoryKey.previewValue,
        insightFeedback: InsightFeedbackRepositoryKey.previewValue,
        languageModel: LanguageModelRepositoryKey.previewValue)
    static let testValue = ObserveInsightCardUseCase(
        sleepTolerance: SleepToleranceRepositoryKey.testValue, insightFeedback: InsightFeedbackRepositoryKey.testValue,
        languageModel: LanguageModelRepositoryKey.testValue)
}

private struct UnimplementedInsightFeedbackError: Error {}

/// The insight feedback repository in tests that haven't overridden it. Using it reports an issue.
private struct UnimplementedInsightFeedbackRepository: InsightFeedbackRepository {
    func feedback() -> AsyncStream<[InsightFeedback]> {
        reportIssue("A test observed the insight feedback without overriding \\.insightFeedbackRepository.")
        return AsyncStream { $0.finish() }
    }

    func record(_ feedback: InsightFeedback) async throws {
        reportIssue("A test recorded insight feedback without overriding \\.insightFeedbackRepository.")
        throw UnimplementedInsightFeedbackError()
    }
}
