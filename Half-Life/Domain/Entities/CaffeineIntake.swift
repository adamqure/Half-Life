//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life CaffeineIntake
//

import Foundation

/// One drink's caffeine entering the body: the dose, and the moment it was consumed.
///
/// An intake holds only what the decay model needs. A drink's name, size, and other details belong to the drink
/// composer's own types. See the Caffeine Decay Model article.
nonisolated struct CaffeineIntake: Identifiable, Sendable, Equatable {
    /// Identifies the intake, so it can be listed, edited, deleted, or marked negligible.
    let id: UUID
    /// The caffeine in the drink, in milligrams.
    let milligrams: Double
    /// When the drink was consumed. It can be earlier than when it was logged.
    let consumedAt: Date
}
