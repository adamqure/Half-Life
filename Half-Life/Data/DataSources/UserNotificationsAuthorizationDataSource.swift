//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life UserNotificationsAuthorizationDataSource
//

import Foundation
import OSLog
import UserNotifications

/// Reads and requests notification permission, through the current notification center.
///
/// Provisional and ephemeral permission count as allowed. The system presents its alert itself (constitution Article
/// I.6). See the Onboarding article.
struct UserNotificationsAuthorizationDataSource: NotificationAuthorizationDataSource {
    private static let logger = Logger(for: UserNotificationsAuthorizationDataSource.self)

    /// Reads the notification center's authorization status.
    let authorizationStatus: @Sendable () async -> UNAuthorizationStatus
    /// Asks the notification center for permission with the given options, and returns whether it was granted.
    let request: @Sendable (UNAuthorizationOptions) async throws -> Bool

    /// Creates the data source.
    ///
    /// - Parameters:
    ///   - authorizationStatus: Reads the authorization status. Defaults to the current notification center's.
    ///   - request: Requests permission. Defaults to asking the current notification center.
    init(
        authorizationStatus: @escaping @Sendable () async -> UNAuthorizationStatus = {
            await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        },
        request: @escaping @Sendable (UNAuthorizationOptions) async throws -> Bool = {
            try await UNUserNotificationCenter.current().requestAuthorization(options: $0)
        }
    ) {
        self.authorizationStatus = authorizationStatus
        self.request = request
    }

    /// Returns whether Half-Life may send notifications.
    func status() async -> NotificationPermission {
        switch await authorizationStatus() {
        case .notDetermined: return .notRequested
        case .denied: return .denied
        case .authorized, .provisional, .ephemeral: return .allowed
        @unknown default: return .notRequested
        }
    }

    /// Asks to send alerts and play sounds.
    ///
    /// - Throws: The notification center's error if the request couldn't be made. It's logged with its domain and
    ///   code only.
    func requestAuthorization() async throws {
        do {
            _ = try await request([.alert, .sound])
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't request notification permission: \(domain, privacy: .public) \(code, privacy: .public)")
            throw error
        }
    }
}
