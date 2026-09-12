//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests LocalAuthenticationDataSourceTests
//

import LocalAuthentication
import Testing

@testable import Half_Life

/// Checks how the Local Authentication data source reads biometric availability and classifies a prompt's outcome,
/// through stand-ins for `LAContext`, so no test shows a Face ID prompt.
struct LocalAuthenticationDataSourceTests {

    struct Unrelated: Error {}

    typealias Check = LocalAuthenticationDataSource.Check

    static func availability(
        _ type: LABiometryType, canEvaluate: Bool, error: LAError.Code? = nil
    ) -> BiometricAvailability {
        LocalAuthenticationDataSource(
            check: { Check(biometryType: type, canEvaluate: canEvaluate, errorCode: error) },
            evaluate: { _ in }
        ).availability()
    }

    static func dataSource(
        evaluating result: @escaping @Sendable () throws -> Void, reasons: Recorded<[String]> = Recorded([])
    ) -> LocalAuthenticationDataSource {
        LocalAuthenticationDataSource(
            check: { Check(biometryType: .faceID, canEvaluate: true, errorCode: nil) },
            evaluate: { reason in
                reasons.update { $0.append(reason) }
                try result()
            })
    }

    // MARK: - Availability

    @Test func evaluableBiometricsAreAvailable() {
        #expect(Self.availability(.faceID, canEvaluate: true) == .available(.faceID))
        #expect(Self.availability(.touchID, canEvaluate: true) == .available(.touchID))
        #expect(Self.availability(.opticID, canEvaluate: true) == .available(.opticID))
    }

    @Test func notEnrolledBiometricsAreNotEnrolled() {
        #expect(
            Self.availability(.faceID, canEvaluate: false, error: .biometryNotEnrolled) == .notEnrolled(.faceID))
    }

    @Test func biometricsNotAvailableWithHardwareAreDenied() {
        #expect(Self.availability(.faceID, canEvaluate: false, error: .biometryNotAvailable) == .denied(.faceID))
    }

    @Test func lockedOutBiometricsAreStillAvailable() {
        #expect(Self.availability(.touchID, canEvaluate: false, error: .biometryLockout) == .available(.touchID))
    }

    @Test func noBiometricHardwareIsUnavailable() {
        #expect(Self.availability(.none, canEvaluate: false, error: .biometryNotAvailable) == .unavailable)
        #expect(Self.availability(.none, canEvaluate: true) == .unavailable)
    }

    @Test func anyOtherErrorIsUnavailable() {
        #expect(Self.availability(.faceID, canEvaluate: false, error: .passcodeNotSet) == .unavailable)
        #expect(Self.availability(.faceID, canEvaluate: false, error: nil) == .unavailable)
    }

    @Test func eachCheckAsksAgain() {
        let checks = Recorded(0)
        let source = LocalAuthenticationDataSource(
            check: {
                checks.update { $0 += 1 }
                return Check(biometryType: .faceID, canEvaluate: true, errorCode: nil)
            },
            evaluate: { _ in })

        _ = source.availability()
        _ = source.availability()

        #expect(checks.value == 2)
    }

    // MARK: - Authentication

    @Test func aSuccessfulScanReturnsWithAReason() async throws {
        let reasons = Recorded<[String]>([])

        try await Self.dataSource(evaluating: {}, reasons: reasons).authenticate()

        #expect(reasons.value.count == 1)
        #expect(reasons.value.allSatisfy { !$0.isEmpty })
    }

    @Test(arguments: [
        LAError.Code.userCancel, .systemCancel, .appCancel, .userFallback, .authenticationFailed,
        .biometryNotAvailable,
    ])
    func anAnswerToThePromptReturnsWithoutThrowing(_ answer: LAError.Code) async throws {
        try await Self.dataSource(evaluating: { throw LAError(answer) }).authenticate()
    }

    @Test func otherLocalAuthenticationErrorsThrow() async {
        let error = await #expect(throws: LAError.self) {
            try await Self.dataSource(evaluating: { throw LAError(.biometryLockout) }).authenticate()
        }
        #expect(error?.code == .biometryLockout)
    }

    @Test func unrelatedErrorsThrow() async {
        await #expect(throws: Unrelated.self) {
            try await Self.dataSource(evaluating: { throw Unrelated() }).authenticate()
        }
    }
}
