//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests UserNotificationsAuthorizationTests
//

import Testing
import UserNotifications

@testable import Half_Life

/// Checks how ``UserNotificationsAuthorizationDataSource`` reads and requests permission, through stand-ins for the
/// notification center, so no test shows the system's alert. The name is shortened to fit SwiftLint's type name limit.
struct UserNotificationsAuthorizationTests {

    struct RequestFailed: Error {}

    static func dataSource(
        status: UNAuthorizationStatus = .notDetermined,
        requestedOptions: Recorded<[UNAuthorizationOptions]> = Recorded([]),
        requestError: (any Error)? = nil
    ) -> UserNotificationsAuthorizationDataSource {
        UserNotificationsAuthorizationDataSource(
            authorizationStatus: { status },
            request: { options in
                requestedOptions.update { $0.append(options) }
                if let requestError { throw requestError }
                return true
            })
    }

    @Test func notDeterminedIsNotRequested() async {
        #expect(await Self.dataSource(status: .notDetermined).status() == .notRequested)
    }

    @Test func deniedIsDenied() async {
        #expect(await Self.dataSource(status: .denied).status() == .denied)
    }

    @Test func authorizedProvisionalAndEphemeralAreAllowed() async {
        #expect(await Self.dataSource(status: .authorized).status() == .allowed)
        #expect(await Self.dataSource(status: .provisional).status() == .allowed)
        #expect(await Self.dataSource(status: .ephemeral).status() == .allowed)
    }

    @Test func requestsAlertsAndSounds() async throws {
        let requested = Recorded<[UNAuthorizationOptions]>([])

        try await Self.dataSource(requestedOptions: requested).requestAuthorization()

        #expect(requested.value == [[.alert, .sound]])
    }

    @Test func aFailedRequestThrowsTheCentersError() async {
        await #expect(throws: RequestFailed.self) {
            try await Self.dataSource(requestError: RequestFailed()).requestAuthorization()
        }
    }
}
