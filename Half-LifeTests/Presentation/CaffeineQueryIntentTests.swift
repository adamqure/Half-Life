//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineQueryIntentTests
//

import AppIntents
import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// INTENT-QUERY-1 to INTENT-QUERY-5 and INTENT-AUTH-1 in the App Intents article, with the use cases built on fakes.
///
/// Each fake publishes only for New York's time zone, so an intent that answers has read the calendar it was given.
struct CaffeineQueryIntentTests {

    // MARK: - INTENT-QUERY-1: the status

    @Test func theStatusIntentAnswersFromTheFirstStatus() async throws {
        let calendar = try AppIntentTesting.newYork()
        let status = try AppIntentTesting.status()
        let repository = FakeCaffeineDecayRepository(statuses: {
            $0.timeZone == calendar.timeZone ? [status] : []
        })
        let intent = withDependencies {
            $0.calendar = calendar
            $0.observeCaffeineStatus = ObserveCaffeineStatusUseCase(repository: repository)
        } operation: {
            GetCaffeineStatusIntent()
        }

        _ = try await intent.perform()
    }

    @Test func theStatusIntentFailsWhenThereIsNoStatus() async throws {
        let calendar = try AppIntentTesting.newYork()
        let intent = withDependencies {
            $0.calendar = calendar
            $0.observeCaffeineStatus = ObserveCaffeineStatusUseCase(repository: FakeCaffeineDecayRepository())
        } operation: {
            GetCaffeineStatusIntent()
        }

        await #expect(throws: IntentFailure.unavailable) {
            _ = try await intent.perform()
        }
    }

    // MARK: - INTENT-QUERY-2: the last cup

    @Test func theLastCupIntentAnswersFromTheFirstCutoff() async throws {
        let calendar = try AppIntentTesting.newYork()
        let cutoff = try AppIntentTesting.cutoff()
        let repository = FakeCaffeineDecayRepository(cutoffs: { $0.timeZone == calendar.timeZone ? [cutoff] : [] })
        let intent = withDependencies {
            $0.calendar = calendar
            $0.observeCaffeineCutoff = ObserveCaffeineCutoffUseCase(repository: repository)
        } operation: {
            GetLastCupIntent()
        }

        _ = try await intent.perform()
    }

    @Test func theLastCupIntentFailsWhenThereIsNoCutoff() async throws {
        let calendar = try AppIntentTesting.newYork()
        let intent = withDependencies {
            $0.calendar = calendar
            $0.observeCaffeineCutoff = ObserveCaffeineCutoffUseCase(repository: FakeCaffeineDecayRepository())
        } operation: {
            GetLastCupIntent()
        }

        await #expect(throws: IntentFailure.unavailable) {
            _ = try await intent.perform()
        }
    }

    // MARK: - INTENT-QUERY-3: a day's intake

    /// An intake intent over a log that has `day` only for the moment `published`.
    static func intakeIntent(publishing day: DrinkLogDay, at published: Date) throws -> GetCaffeineIntakeIntent {
        let calendar = try AppIntentTesting.newYork()
        let now = try AppIntentTesting.now()
        let drinkLog = FakeDrinkLogRepository(days: { date, dayCalendar in
            date == published && dayCalendar.timeZone == calendar.timeZone ? [day] : []
        })
        return withDependencies {
            $0.calendar = calendar
            $0.observeTimeOfDay = ObserveTimeOfDayUseCase(currentTime: FakeCurrentTimeRepository(date: now))
            $0.observeDrinkLogDay = ObserveDrinkLogDayUseCase(repository: drinkLog)
        } operation: {
            GetCaffeineIntakeIntent()
        }
    }

    @Test func withoutADayTheIntakeIntentAnswersForToday() async throws {
        let intent = try Self.intakeIntent(publishing: try AppIntentTesting.day(7), at: try AppIntentTesting.now())

        _ = try await intent.perform()
    }

    @Test func withADayTheIntakeIntentAnswersForThatDay() async throws {
        let tuesday = try AppIntentTesting.date(day: 1, hour: 12, minute: 0)
        let intent = try Self.intakeIntent(publishing: try AppIntentTesting.day(1), at: tuesday)
        intent.day = tuesday

        _ = try await intent.perform()
    }

    @Test func theIntakeIntentFailsWhenTheDayIsntPublished() async throws {
        let tuesday = try AppIntentTesting.date(day: 1, hour: 12, minute: 0)
        let intent = try Self.intakeIntent(publishing: try AppIntentTesting.day(1), at: tuesday)

        await #expect(throws: IntentFailure.unavailable) {
            _ = try await intent.perform()
        }
    }

    // MARK: - INTENT-QUERY-4: the sleep time

    @Test func theSleepTimeIntentAnswersFromTheFirstWindow() async throws {
        let calendar = try AppIntentTesting.newYork()
        let window = try AppIntentTesting.sleepWindow(clearHour: 23, clearMinute: 10)
        let repository = FakeCaffeineDecayRepository(sleepWindows: {
            $0.timeZone == calendar.timeZone ? [window] : []
        })
        let intent = withDependencies {
            $0.calendar = calendar
            $0.observeSleepWindow = ObserveSleepWindowUseCase(repository: repository)
        } operation: {
            GetSleepTimeIntent()
        }

        _ = try await intent.perform()
    }

    @Test func theSleepTimeIntentFailsWhenThereIsNoWindow() async throws {
        let calendar = try AppIntentTesting.newYork()
        let intent = withDependencies {
            $0.calendar = calendar
            $0.observeSleepWindow = ObserveSleepWindowUseCase(repository: FakeCaffeineDecayRepository())
        } operation: {
            GetSleepTimeIntent()
        }

        await #expect(throws: IntentFailure.unavailable) {
            _ = try await intent.perform()
        }
    }

    // MARK: - INTENT-AUTH-1 and INTENT-QUERY-5: how the intents run

    @Test func everyIntentNeedsThePhoneUnlocked() {
        #expect(LogDrinkIntent.authenticationPolicy == .requiresLocalDeviceAuthentication)
        #expect(GetCaffeineStatusIntent.authenticationPolicy == .requiresLocalDeviceAuthentication)
        #expect(GetLastCupIntent.authenticationPolicy == .requiresLocalDeviceAuthentication)
        #expect(GetCaffeineIntakeIntent.authenticationPolicy == .requiresLocalDeviceAuthentication)
        #expect(GetSleepTimeIntent.authenticationPolicy == .requiresLocalDeviceAuthentication)
        #expect(AskHalfLifeIntent.authenticationPolicy == .requiresLocalDeviceAuthentication)
    }

    @Test func everyIntentRunsInTheBackgroundAndOnlyAskCanOpenTheApp() {
        #expect(LogDrinkIntent.supportedModes == .background)
        #expect(GetCaffeineStatusIntent.supportedModes == .background)
        #expect(GetLastCupIntent.supportedModes == .background)
        #expect(GetCaffeineIntakeIntent.supportedModes == .background)
        #expect(GetSleepTimeIntent.supportedModes == .background)
        #expect(AskHalfLifeIntent.supportedModes == [.background, .foreground(.dynamic)])
    }
}
