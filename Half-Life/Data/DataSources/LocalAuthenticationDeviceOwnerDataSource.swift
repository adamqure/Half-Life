//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LocalAuthenticationDeviceOwnerDataSource
//

import Foundation
import LocalAuthentication
import OSLog

/// Asks to unlock the app with Local Authentication's device owner policy: Face ID or Touch ID, then the passcode.
///
/// The passcode fallback means a failed scan or a biometric lockout never locks the user out of their own data. Each
/// prompt uses a fresh `LAContext`, because a context remembers a successful evaluation. See the App Lock article,
/// LOCKSRC-2.
struct LocalAuthenticationDeviceOwnerDataSource: DeviceOwnerAuthenticationDataSource {
    /// What one fresh `LAContext` reported about the device owner policy.
    struct Check: Sendable, Equatable {
        /// Whether the policy can be evaluated.
        let canEvaluate: Bool
        /// Why it can't be evaluated, if Local Authentication said.
        let errorCode: LAError.Code?
    }

    private static let logger = Logger(for: LocalAuthenticationDeviceOwnerDataSource.self)

    /// The prompt's outcomes that mean the user didn't pass, so the app stays locked.
    private static let declines: Set<LAError.Code> = [
        .userCancel, .systemCancel, .appCancel, .authenticationFailed, .notInteractive,
    ]

    /// Checks the device owner policy with a fresh context.
    let check: @Sendable () -> Check
    /// Evaluates the device owner policy with a fresh context, showing the given reason.
    let evaluate: @Sendable (_ reason: String) async throws -> Void

    /// Creates the data source.
    ///
    /// - Parameters:
    ///   - check: Checks the policy. Defaults to a fresh `LAContext`.
    ///   - evaluate: Evaluates the policy. Defaults to a fresh `LAContext`.
    init(
        check: @escaping @Sendable () -> Check = { Self.checkWithFreshContext() },
        evaluate: @escaping @Sendable (_ reason: String) async throws -> Void = { reason in
            _ = try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        }
    ) {
        self.check = check
        self.evaluate = evaluate
    }

    /// Checks the device owner policy with a new `LAContext`.
    static func checkWithFreshContext() -> Check {
        var error: NSError?
        let canEvaluate = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        let code = error.flatMap { $0.domain == LAErrorDomain ? LAError.Code(rawValue: $0.code) : nil }
        return Check(canEvaluate: canEvaluate, errorCode: code)
    }

    /// Shows the system's prompt, and returns how it ended.
    ///
    /// Only a missing passcode skips the prompt. Anything else the check reports is left to the prompt, so the app
    /// never unlocks without asking because of it.
    ///
    /// - Throws: Local Authentication's error if the prompt couldn't be shown or ended for another reason. It's
    ///   logged with its domain and code only.
    func authenticate() async throws -> DeviceOwnerAuthenticationOutcome {
        let check = check()
        if !check.canEvaluate, check.errorCode == .passcodeNotSet {
            Self.logger.notice("The device has no passcode, so the app lock can't ask.")
            return .unavailable
        }
        let reason = String(
            localized: "Unlock Half-Life to see your caffeine and health data.",
            comment: "The unlock prompt's reason. iOS shows it for Touch ID, and when asking for the passcode.")
        do {
            try await evaluate(reason)
            return .passed
        } catch let error as LAError where error.code == .passcodeNotSet {
            Self.logger.notice("The device has no passcode, so the app lock can't ask.")
            return .unavailable
        } catch let error as LAError where Self.declines.contains(error.code) {
            return .declined
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't show the unlock prompt: \(domain, privacy: .public) \(code, privacy: .public)")
            throw error
        }
    }
}
