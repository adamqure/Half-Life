//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LanguageModelDependencyTests
//

import ComposableArchitecture
import Testing

@testable import Half_Life

/// Checks the language model's test registrations (DEP-LM in the Language Model article).
///
/// These tests use only the test values, which never reach the model or open a store.
struct LanguageModelDependencyTests {

    /// A test that observes the availability without overriding `\.observeLanguageModelAvailability` fails.
    @Test func observingTheAvailabilityWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeLanguageModelAvailability) var observeLanguageModelAvailability
            for await _ in observeLanguageModelAvailability.execute(()) {}
        }
    }

    /// A test that responds to an instruction without overriding `\.respondToInstruction` fails.
    @Test func respondingWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.respondToInstruction) var respondToInstruction
            _ = try? await respondToInstruction.execute(LanguageModelInstruction(prompt: "Hello", origin: .app))
        }
    }

    /// A test that writes an insight without overriding `\.writeInsight` fails.
    @Test func writingAnInsightWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.writeInsight) var writeInsight
            _ = try? await writeInsight.execute(.example)
        }
    }

    /// A test that uses the repository without overriding `\.languageModelRepository` fails.
    @Test func usingTheRepositoryWithoutOverridingItReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.languageModelRepository) var repository
            for await _ in repository.availability() {}
        }
    }
}

extension SwiftDataStoreTests {

    /// Checks the language model's preview registrations. The preview decay and drink log repositories open an empty
    /// in-memory store, so these run inside the serialized `SwiftDataStoreTests`.
    @Suite(.timeLimit(.minutes(1)))
    struct LanguageModelPreviewDependencyTests {

        /// DEP-LM: the three use cases hold the one app-scoped language model repository.
        @Test func previewUseCasesHoldTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.languageModelRepository) var repository
                @Dependency(\.observeLanguageModelAvailability) var observeLanguageModelAvailability
                @Dependency(\.respondToInstruction) var respondToInstruction
                @Dependency(\.writeInsight) var writeInsight
                #expect((observeLanguageModelAvailability.repository as AnyObject) === (repository as AnyObject))
                #expect((respondToInstruction.repository as AnyObject) === (repository as AnyObject))
                #expect((writeInsight.repository as AnyObject) === (repository as AnyObject))
            }
        }

        /// DEP-LM: the data source's tools read the app-scoped caffeine decay, drink log, and current time
        /// repositories.
        @Test func previewToolsReadTheAppScopedRepositories() throws {
            try withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.languageModelRepository) var repository
                @Dependency(\.caffeineDecayRepository) var caffeineDecay
                @Dependency(\.drinkLogRepository) var drinkLog
                @Dependency(\.currentTimeRepository) var currentTime
                let live = try #require(repository as? LiveLanguageModelRepository)
                let dataSource = try #require(live.dataSource as? FoundationModelLanguageModelDataSource)
                #expect((dataSource.caffeineDecay as AnyObject) === (caffeineDecay as AnyObject))
                #expect((dataSource.drinkLog as AnyObject) === (drinkLog as AnyObject))
                #expect((dataSource.currentTime as AnyObject) === (currentTime as AnyObject))
            }
        }
    }
}
