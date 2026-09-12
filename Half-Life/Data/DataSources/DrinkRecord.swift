//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life DrinkRecord
//

import Foundation
import SwiftData

/// How SwiftData stores a logged drink and its negligible mark.
///
/// The record syncs to the user's private CloudKit database (constitution Article V.1), so it follows CloudKit's
/// rules: every property has a default value, and none is unique. The drink's type is stored as its raw value,
/// which is why a ``DrinkType`` case is never renamed or removed once shipped. Only
/// ``SwiftDataDrinkLogDataSource`` uses it.
@Model
final class DrinkRecord {
    /// The drink's identifier, shared with its ``LoggedDrink`` and its intake.
    var id: UUID = UUID()
    /// The raw value of the drink's ``DrinkType``.
    var typeRawValue: String = ""
    /// How many units of the drink's unit.
    var quantity: Int = 0
    /// The drink's total estimated caffeine, in milligrams.
    var milligrams: Double = 0
    /// When the drink was consumed.
    var consumedAt: Date = Date.distantPast
    /// Whether the decay repository has marked the drink negligible. Once set, it's never cleared.
    var isNegligible: Bool = false

    /// Creates a record from its stored values.
    ///
    /// - Parameters:
    ///   - id: The drink's identifier.
    ///   - typeRawValue: The raw value of the drink's type.
    ///   - quantity: How many units of the drink's unit.
    ///   - milligrams: The drink's total estimated caffeine, in milligrams.
    ///   - consumedAt: When the drink was consumed.
    ///   - isNegligible: Whether the drink is marked negligible.
    init(
        id: UUID, typeRawValue: String, quantity: Int, milligrams: Double, consumedAt: Date,
        isNegligible: Bool = false
    ) {
        self.id = id
        self.typeRawValue = typeRawValue
        self.quantity = quantity
        self.milligrams = milligrams
        self.consumedAt = consumedAt
        self.isNegligible = isNegligible
    }

    /// Creates an unmarked record of `drink`.
    ///
    /// - Parameter drink: The drink to store.
    convenience init(_ drink: LoggedDrink) {
        self.init(
            id: drink.id, typeRawValue: drink.type.rawValue, quantity: drink.quantity, milligrams: drink.milligrams,
            consumedAt: drink.consumedAt)
    }

    /// The logged drink this record stores, or `nil` if this version of the app doesn't know its type.
    var loggedDrink: LoggedDrink? {
        guard let type = DrinkType(rawValue: typeRawValue) else { return nil }
        return LoggedDrink(id: id, type: type, quantity: quantity, milligrams: milligrams, consumedAt: consumedAt)
    }
}
