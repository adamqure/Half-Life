//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DeleteDrinkUseCaseTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks deleting a drink against HISTUSE-2 and HISTUSE-3 in the Today Screen article.
struct DeleteDrinkUseCaseTests {

    struct DeleteFailed: Error {}

    // MARK: - HISTUSE-2: it deletes the drink through the repository

    @Test func deletesTheDrinkThroughTheRepository() async throws {
        let drinkLog = FakeDrinkLogRepository()
        let id = UUID()

        try await executeThroughProtocol(DeleteDrinkUseCase(drinkLog: drinkLog), id)

        #expect(await drinkLog.deleted == [id])
    }

    // MARK: - HISTUSE-3: the repository's error reaches the caller

    @Test func throwsTheRepositorysError() async {
        let delete = DeleteDrinkUseCase(drinkLog: FakeDrinkLogRepository(deleteError: DeleteFailed()))

        await #expect(throws: DeleteFailed.self) {
            try await executeThroughProtocol(delete, UUID())
        }
    }
}
