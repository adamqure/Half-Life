//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CutoffReminderDependencyTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the cutoff reminder's registrations (constitution Article I.15, DEP-REMINDER in the Cutoff Reminder article),
/// and the simulated data source that UI tests and previews schedule through.
struct CutoffReminderDependencyTests {

    static let reminder = CutoffReminder(
        date: Date(timeIntervalSinceReferenceDate: 13 * 3_600), title: "Last cup", body: "Tonight")
    static let tomorrow = CutoffReminder(
        date: Date(timeIntervalSinceReferenceDate: 37 * 3_600), title: "Last cup", body: "Tomorrow")

    /// A test that observes the reminders without overriding the repository fails.
    @Test func testCutoffReminderRepositoryReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.cutoffReminderRepository) var repository
            for await _ in repository.reminders() {}
        }
    }

    /// A test that schedules reminders without overriding the use case fails.
    @Test func testScheduleCutoffRemindersReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.scheduleCutoffReminders) var scheduleCutoffReminders
            try? await scheduleCutoffReminders.execute([Self.reminder])
        }
    }

    /// A test that observes the upcoming cutoffs without overriding the use case fails.
    @Test func testObserveUpcomingCutoffsReportsAnIssue() async {
        await withKnownIssue {
            @Dependency(\.observeUpcomingCutoffs) var observeUpcomingCutoffs
            let input = ObserveUpcomingCutoffsUseCase.Input(nights: 7, calendar: Calendar(identifier: .gregorian))
            for await _ in observeUpcomingCutoffs.execute(input) {}
        }
    }

    /// DEP-REMINDER: scheduling uses the one app-scoped reminder repository.
    @Test func previewScheduleCutoffRemindersUsesTheAppScopedRepository() {
        withDependencies {
            $0.context = .preview
        } operation: {
            @Dependency(\.cutoffReminderRepository) var repository
            @Dependency(\.scheduleCutoffReminders) var scheduleCutoffReminders
            #expect((scheduleCutoffReminders.repository as AnyObject) === (repository as AnyObject))
        }
    }

    /// The simulated data source keeps what it's given, soonest first, and touches no notification center.
    @Test func theSimulatedDataSourceKeepsTheRemindersSoonestFirst() async throws {
        let source = SimulatedCutoffReminderDataSource()
        #expect(await source.scheduled().isEmpty)

        try await source.replace(with: [Self.tomorrow, Self.reminder])

        #expect(await source.scheduled() == [Self.reminder, Self.tomorrow])
    }
}

extension SwiftDataStoreTests {

    /// Checks the upcoming cutoffs' preview registration, which opens an empty in-memory store. It runs inside the
    /// serialized `SwiftDataStoreTests`, because it opens a store.
    @Suite(.timeLimit(.minutes(1)))
    struct UpcomingCutoffsPreviewDependencyTests {

        /// DEP-REMINDER: observing the upcoming cutoffs uses the one app-scoped decay repository.
        @Test func previewObserveUpcomingCutoffsUsesTheAppScopedRepository() {
            withDependencies {
                $0.context = .preview
            } operation: {
                @Dependency(\.caffeineDecayRepository) var repository
                @Dependency(\.observeUpcomingCutoffs) var observeUpcomingCutoffs
                #expect((observeUpcomingCutoffs.repository as AnyObject) === (repository as AnyObject))
            }
        }
    }
}
