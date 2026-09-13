//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HalfLifeEstimateDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the half-life estimator's registrations (constitution Article I.15). None of these tests opens a store or
/// reads Health.
struct HalfLifeEstimateDependencyTests {

    static let estimate = HalfLifeEstimate(
        halfLife: .standard, lowerBound: .standard, upperBound: .standard, prior: .standard, nightsUsed: 0,
        calculatedAt: Date(timeIntervalSinceReferenceDate: 0))

    @Test func testRepositoryReportsAnIssueForEveryOperation() async {
        @Dependency(\.halfLifeEstimateRepository) var repository
        await withKnownIssue {
            for await _ in repository.estimate() {}
        }
        await withKnownIssue {
            await repository.refresh()
        }
    }

    @Test func testUseCasesReportAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeHalfLifeEstimate) var observeHalfLifeEstimate
            for await _ in observeHalfLifeEstimate.execute(()) {}
        }
        await withKnownIssue {
            @Dependency(\.refreshHalfLifeEstimate) var refreshHalfLifeEstimate
            await refreshHalfLifeEstimate.execute(())
        }
    }

    @Test func testEstimateDataSourceReportsAnIssueForEveryOperation() async {
        let source = HalfLifeEstimateDataSourceKey.testValue
        await withKnownIssue {
            _ = try await source.storedEstimate()
        }
        await withKnownIssue {
            try await source.store(Self.estimate)
        }
        await withKnownIssue {
            for await _ in await source.changes() {}
        }
    }

    @Test func aUITestGetsATemporaryEstimateFile() throws {
        let configuration = UITestLaunchConfiguration(
            environment: [LaunchEnvironmentKey.profile: LaunchEnvironmentKey.completed])

        let source = try #require(
            HalfLifeEstimateDataSourceKey.makeLiveValue(configuration: configuration)
                as? FileHalfLifeEstimateDataSource)

        #expect(source.fileURL != (try FileHalfLifeEstimateDataSource.defaultFileURL()))
    }

    @Test func outsideUITestsTheEstimateIsInTheAppsOwnFile() throws {
        let source = HalfLifeEstimateDataSourceKey.makeLiveValue(
            configuration: UITestLaunchConfiguration(environment: [:]))
        let defaultURL = try FileHalfLifeEstimateDataSource.defaultFileURL()

        #expect((source as? FileHalfLifeEstimateDataSource)?.fileURL == defaultURL)
    }
}

extension SwiftDataStoreTests {

    /// Checks the preview registrations, which open an empty in-memory drink store. It runs inside the serialized
    /// `SwiftDataStoreTests`, because it opens a store.
    @Suite(.timeLimit(.minutes(1)))
    struct HalfLifeEstimatePreviewDependencyTests {

        @Test func previewRepositoryIsTheLiveRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.halfLifeEstimateRepository) var repository
                #expect(repository is LiveHalfLifeEstimateRepository)
            }
        }

        @Test func previewUseCasesUseTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.halfLifeEstimateRepository) var repository
                @Dependency(\.observeHalfLifeEstimate) var observeHalfLifeEstimate
                @Dependency(\.refreshHalfLifeEstimate) var refreshHalfLifeEstimate
                #expect((observeHalfLifeEstimate.repository as AnyObject) === (repository as AnyObject))
                #expect((refreshHalfLifeEstimate.repository as AnyObject) === (repository as AnyObject))
            }
        }

        /// The preview repository runs end to end. Previews never read Health, so it has no nights, and the estimate
        /// is the survey's.
        @Test func previewRepositoryPublishesTheSurveysHalfLife() async throws {
            let repository = withDependencies {
                $0.context = .preview
            } operation: { () -> any HalfLifeEstimateRepository in
                @Dependency(\.halfLifeEstimateRepository) var repository
                return repository
            }

            var estimates = repository.estimate().makeAsyncIterator()
            let estimate = try #require(await estimates.next())

            #expect(estimate.nightsUsed == 0)
            #expect(estimate.halfLife == .standard)
        }
    }
}
