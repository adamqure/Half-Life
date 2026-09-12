//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LivePermissionsRepository
//

import Foundation
import OSLog

/// The live permissions repository: the source of truth for the Health, notification, and biometric permissions.
///
/// It reads each permission from its data source, and the permission history for biometrics, which iOS reports as
/// available both before the app asks and after the user allows it. It publishes the permissions to a new subscriber
/// at once, and to every subscriber whenever a request, a refresh, or a new subscriber finds that they changed. It's
/// an actor, off the main actor (constitution Article I.13). The Onboarding article lists its requirements, PERM-1 to
/// PERM-4.
actor LivePermissionsRepository: PermissionsRepository {
    private static let logger = Logger(for: LivePermissionsRepository.self)

    private let health: any HealthAuthorizationDataSource
    private let notifications: any NotificationAuthorizationDataSource
    private let biometrics: any BiometricAuthenticationDataSource
    private let history: any PermissionHistoryDataSource
    private let settings: any SystemSettingsDataSource
    private var subscribers: [UUID: AsyncStream<Permissions>.Continuation] = [:]
    private var lastPublished: Permissions?

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - health: Reads and requests Health access.
    ///   - notifications: Reads and requests notification permission.
    ///   - biometrics: Reads and asks to use Face ID or Touch ID.
    ///   - history: Remembers whether biometrics have been asked for.
    ///   - settings: Opens the Settings app.
    init(
        health: any HealthAuthorizationDataSource, notifications: any NotificationAuthorizationDataSource,
        biometrics: any BiometricAuthenticationDataSource, history: any PermissionHistoryDataSource,
        settings: any SystemSettingsDataSource
    ) {
        self.health = health
        self.notifications = notifications
        self.biometrics = biometrics
        self.history = history
        self.settings = settings
    }

    /// Streams the permissions: the current ones as soon as it's subscribed to, then each change. It never finishes.
    nonisolated func permissions() -> AsyncStream<Permissions> {
        let (stream, continuation) = AsyncStream.makeStream(of: Permissions.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        Task { await addSubscriber(id, continuation) }
        return stream
    }

    /// Asks to read Health, then publishes the permissions if they changed.
    ///
    /// - Throws: The data source's error if the request couldn't be made.
    func requestHealthAccess() async throws {
        Self.logger.notice("Requested Health access.")
        do {
            try await health.requestAccess()
        } catch {
            Self.logError("request Health access", error)
            throw error
        }
        await publishIfChanged()
    }

    /// Asks to send notifications, then publishes the permissions if they changed.
    ///
    /// - Throws: The data source's error if the request couldn't be made.
    func requestNotifications() async throws {
        do {
            try await notifications.requestAuthorization()
        } catch {
            Self.logError("request notification permission", error)
            throw error
        }
        let outcome = Self.name(of: await publishIfChanged().notifications)
        Self.logger.notice("Requested notification permission: \(outcome, privacy: .public)")
    }

    /// Asks to use biometrics, records that it asked, then publishes the permissions if they changed.
    ///
    /// Once the user has answered the prompt, whether they allowed it, cancelled, or failed the scan, the request is
    /// recorded, because iOS won't ask for permission again. A prompt that couldn't be shown isn't recorded.
    ///
    /// - Throws: The data source's error if the prompt couldn't be shown, or the history's if it couldn't be written.
    func requestBiometrics() async throws {
        do {
            try await biometrics.authenticate()
        } catch {
            Self.logError("ask for biometric permission", error)
            throw error
        }
        do {
            try await history.recordBiometricsRequested()
        } catch {
            Self.logError("record the biometric request", error)
            throw error
        }
        let outcome = Self.name(of: await publishIfChanged().biometrics)
        Self.logger.notice("Requested biometric permission: \(outcome, privacy: .public)")
    }

    /// Reads the permissions again, and publishes them if they changed.
    func refresh() async {
        await publishIfChanged()
    }

    /// Opens Half-Life's page in the Settings app.
    func openSettings() async {
        await settings.openSettings()
    }

    /// Tells every existing subscriber if the permissions changed, then sends the new subscriber the current ones.
    private func addSubscriber(_ id: UUID, _ continuation: AsyncStream<Permissions>.Continuation) async {
        let current = await publishIfChanged()
        subscribers[id] = continuation
        continuation.yield(current)
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    /// Reads the permissions and, if they differ from the last ones published, publishes them to every subscriber.
    ///
    /// - Returns: The permissions it read.
    @discardableResult
    private func publishIfChanged() async -> Permissions {
        let current = Permissions(
            health: await health.status(), notifications: await notifications.status(),
            biometrics: await readBiometrics())
        if current != lastPublished {
            lastPublished = current
            for subscriber in subscribers.values {
                subscriber.yield(current)
            }
        }
        return current
    }

    /// Combines what the device's biometrics allow with whether Half-Life has asked. An unreadable history is logged,
    /// and counts as not asked.
    private func readBiometrics() async -> BiometricPermission {
        switch biometrics.availability() {
        case .available(let biometry):
            let requested: Bool
            do {
                requested = try await history.hasRequestedBiometrics()
            } catch {
                Self.logError("read the permission history", error)
                requested = false
            }
            return requested ? .allowed(biometry) : .notRequested(biometry)
        case .denied(let biometry): return .denied(biometry)
        case .notEnrolled(let biometry): return .notEnrolled(biometry)
        case .unavailable: return .unavailable
        }
    }

    /// Logs a failure with the error's domain and code only (constitution Article XI.6.4).
    private static func logError(_ what: String, _ error: any Error) {
        let domain = (error as NSError).domain
        let code = (error as NSError).code
        logger.error("Couldn't \(what, privacy: .public): \(domain, privacy: .public) \(code, privacy: .public)")
    }

    private static func name(of permission: NotificationPermission) -> String {
        switch permission {
        case .notRequested: "not requested"
        case .allowed: "allowed"
        case .denied: "denied"
        }
    }

    private static func name(of permission: BiometricPermission) -> String {
        switch permission {
        case .notRequested: "not requested"
        case .allowed: "allowed"
        case .denied: "denied"
        case .notEnrolled: "not enrolled"
        case .unavailable: "unavailable"
        }
    }
}
