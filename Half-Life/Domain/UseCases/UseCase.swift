//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life UseCase
//

/// A single business operation, run with ``execute(_:)`` (constitution Article I.7).
///
/// Every use case conforms to this protocol. It performs exactly one operation, holds nothing but references to
/// the repositories it uses, and lives only as long as the feature that owns it.
protocol UseCase: Sendable {
    /// The operation's input. It's `Void` for an operation that takes none.
    associatedtype Input: Sendable
    /// The operation's result. It's `Void` for an operation that returns nothing.
    associatedtype Output: Sendable

    /// Performs the operation.
    ///
    /// A conforming type whose operation neither suspends nor throws can leave out `async` or `throws`. Callers
    /// that use the concrete type then need no `try await`.
    ///
    /// - Parameter input: The operation's input.
    /// - Returns: The operation's result.
    func execute(_ input: Input) async throws -> Output
}
