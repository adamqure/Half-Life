//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests UseCaseTesting
//

@testable import Half_Life

/// Runs `useCase` through the `UseCase` protocol. A use case that doesn't follow the pattern in constitution
/// Article I.7 fails to compile in its tests.
func executeThroughProtocol<U: UseCase>(_ useCase: U, _ input: U.Input) async throws -> U.Output {
    try await useCase.execute(input)
}
