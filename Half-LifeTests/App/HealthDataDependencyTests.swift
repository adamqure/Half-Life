//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests HealthDataDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the Health data registrations against DEP-HEALTH in the Apple Health Card article (constitution Article
/// I.15).
///
/// Tests never read the `.live` context. The preview repository reads no Health data and stores its switch in a
/// temporary file, so the `.preview` context checks the wiring safely.
struct HealthDataDependencyTests {

    @Test func previewHealthDataRepositoryIsTheLiveRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.healthDataRepository) var repository
            #expect(repository is LiveHealthDataRepository)
        }
    }

    @Test func eachUseCaseHoldsTheAppScopedRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.healthDataRepository) var repository
            @Dependency(\.observeHealthSummary) var observeHealthSummary
            @Dependency(\.observeDemoHealthData) var observeDemoHealthData
            @Dependency(\.setDemoHealthData) var setDemoHealthData
            #expect((observeHealthSummary.repository as AnyObject) === (repository as AnyObject))
            #expect((observeDemoHealthData.repository as AnyObject) === (repository as AnyObject))
            #expect((setDemoHealthData.repository as AnyObject) === (repository as AnyObject))
        }
    }

    @Test func testSummaryReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeHealthSummary) var observeHealthSummary
            for await _ in observeHealthSummary.execute(Calendar(identifier: .gregorian)) {}
        }
    }

    @Test func testSwitchReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeDemoHealthData) var observeDemoHealthData
            for await _ in observeDemoHealthData.execute(()) {}
        }
    }

    @Test func testSettingTheSwitchReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.setDemoHealthData) var setDemoHealthData
            try await setDemoHealthData.execute(true)
        }
    }
}
