//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DeviceOwnerAuthenticationTests
//

import LocalAuthentication
import Testing

@testable import Half_Life

/// Checks how the unlock prompt's data source classifies each outcome (LOCKSRC-2 in the App Lock article), through
/// stand-ins for `LAContext`, so no test shows a prompt.
struct DeviceOwnerAuthenticationTests {

    struct Unrelated: Error {}

    typealias Check = LocalAuthenticationDeviceOwnerDataSource.Check

    static func dataSource(
        canEvaluate: Bool = true, error: LAError.Code? = nil,
        evaluating result: @escaping @Sendable () throws -> Void = {}, reasons: Recorded<[String]> = Recorded([])
    ) -> LocalAuthenticationDeviceOwnerDataSource {
        LocalAuthenticationDeviceOwnerDataSource(
            check: { Check(canEvaluate: canEvaluate, errorCode: error) },
            evaluate: { reason in
                reasons.update { $0.append(reason) }
                try result()
            })
    }

    @Test func aPassedPromptPassesWithAReason() async throws {
        let reasons = Recorded<[String]>([])

        let outcome = try await Self.dataSource(reasons: reasons).authenticate()

        #expect(outcome == .passed)
        #expect(reasons.value.count == 1)
        #expect(reasons.value.allSatisfy { !$0.isEmpty })
    }

    @Test(arguments: [LAError.Code.userCancel, .systemCancel, .appCancel, .authenticationFailed, .notInteractive])
    func aPromptTheUserDidntPassIsDeclined(_ answer: LAError.Code) async throws {
        let outcome = try await Self.dataSource(evaluating: { throw LAError(answer) }).authenticate()

        #expect(outcome == .declined)
    }

    @Test func withNoPasscodeItsUnavailableWithoutAPrompt() async throws {
        let reasons = Recorded<[String]>([])

        let outcome = try await Self.dataSource(canEvaluate: false, error: .passcodeNotSet, reasons: reasons)
            .authenticate()

        #expect(outcome == .unavailable)
        #expect(reasons.value.isEmpty)
    }

    @Test func aPasscodeThatsGoneByThePromptIsUnavailable() async throws {
        let outcome = try await Self.dataSource(evaluating: { throw LAError(.passcodeNotSet) }).authenticate()

        #expect(outcome == .unavailable)
    }

    /// Only a missing passcode skips the prompt. Anything else the check reports is left to the prompt, so the app
    /// never unlocks without asking because of it.
    @Test func anyOtherCheckFailureStillAsks() async throws {
        let reasons = Recorded<[String]>([])

        let outcome = try await Self.dataSource(canEvaluate: false, error: .biometryLockout, reasons: reasons)
            .authenticate()

        #expect(outcome == .passed)
        #expect(reasons.value.count == 1)
    }

    @Test func otherLocalAuthenticationErrorsThrow() async {
        let error = await #expect(throws: LAError.self) {
            try await Self.dataSource(evaluating: { throw LAError(.invalidContext) }).authenticate()
        }
        #expect(error?.code == .invalidContext)
    }

    @Test func unrelatedErrorsThrow() async {
        await #expect(throws: Unrelated.self) {
            try await Self.dataSource(evaluating: { throw Unrelated() }).authenticate()
        }
    }

    /// A fresh context can check the policy without showing anything. The simulator used for tests has no passcode,
    /// so this only checks that the check runs and says why when it can't evaluate.
    @Test func aFreshContextChecksThePolicy() {
        let check = LocalAuthenticationDeviceOwnerDataSource.checkWithFreshContext()

        #expect(check.canEvaluate || check.errorCode != nil)
    }
}
