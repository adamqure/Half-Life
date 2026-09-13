//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LocalAuthenticationDataSource
//

import Foundation
import LocalAuthentication
import OSLog

/// Reads and asks to use the device's Face ID or Touch ID, through Local Authentication.
///
/// Each call uses a fresh `LAContext`, because a context remembers a successful evaluation. iOS has no separate
/// request for biometric permission: the system asks, with the Face ID purpose string, the first time the app
/// evaluates a biometric policy, and then scans. The system presents the prompt itself (constitution Article I.6).
/// See the Onboarding article.
struct LocalAuthenticationDataSource: BiometricAuthenticationDataSource {
    /// What one fresh `LAContext` reported about the device's biometrics.
    struct Check: Sendable, Equatable {
        /// The kind of biometrics the device has, or `.none`.
        let biometryType: LABiometryType
        /// Whether the biometric policy can be evaluated.
        let canEvaluate: Bool
        /// Why it can't be evaluated, if Local Authentication said.
        let errorCode: LAError.Code?
    }

    private static let logger = Logger(for: LocalAuthenticationDataSource.self)

    /// The prompt's outcomes that mean the user answered it. Each counts as having asked.
    private static let answers: Set<LAError.Code> = [
        .userCancel, .systemCancel, .appCancel, .userFallback, .authenticationFailed, .biometryNotAvailable,
    ]

    /// Checks the device's biometrics with a fresh context.
    let check: @Sendable () -> Check
    /// Evaluates the biometric policy with a fresh context, showing the given reason.
    let evaluate: @Sendable (_ reason: String) async throws -> Void

    /// Creates the data source.
    ///
    /// - Parameters:
    ///   - check: Checks the device's biometrics. Defaults to a fresh `LAContext`.
    ///   - evaluate: Evaluates the biometric policy. Defaults to a fresh `LAContext`.
    init(
        check: @escaping @Sendable () -> Check = { Self.checkWithFreshContext() },
        evaluate: @escaping @Sendable (_ reason: String) async throws -> Void = { reason in
            _ = try await LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        }
    ) {
        self.check = check
        self.evaluate = evaluate
    }

    /// Checks the device's biometrics with a new `LAContext`.
    static func checkWithFreshContext() -> Check {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        let code = error.flatMap { $0.domain == LAErrorDomain ? LAError.Code(rawValue: $0.code) : nil }
        return Check(biometryType: context.biometryType, canEvaluate: canEvaluate, errorCode: code)
    }

    /// Returns what the device's biometrics allow now.
    ///
    /// Biometrics that can be evaluated, or are locked out after too many failed scans, are available. Biometrics
    /// that aren't available on a device that has them are denied, which is what iOS reports once the user says no.
    func availability() -> BiometricAvailability {
        let check = check()
        guard let biometry = Self.biometry(for: check.biometryType) else { return .unavailable }
        if check.canEvaluate {
            return .available(biometry)
        }
        switch check.errorCode {
        case .biometryNotEnrolled?: return .notEnrolled(biometry)
        case .biometryNotAvailable?: return .denied(biometry)
        case .biometryLockout?: return .available(biometry)
        default: return .unavailable
        }
    }

    /// Shows the system's biometric prompt.
    ///
    /// The user allowing, cancelling, failing the scan, or saying no to Face ID all return normally, because each
    /// means the user answered.
    ///
    /// - Throws: Local Authentication's error if the prompt couldn't be shown or ended for another reason. It's
    ///   logged with its domain and code only.
    func authenticate() async throws {
        let reason = String(
            localized: "Allow Half-Life to check that it's you.",
            comment: "Touch ID prompt's reason when Half-Life asks to use biometrics, which the app lock uses.")
        do {
            try await evaluate(reason)
        } catch let error as LAError where Self.answers.contains(error.code) {
            return
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't show the biometric prompt: \(domain, privacy: .public) \(code, privacy: .public)")
            throw error
        }
    }

    private static func biometry(for type: LABiometryType) -> Biometry? {
        switch type {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        case .none: return nil
        @unknown default: return nil
        }
    }
}
