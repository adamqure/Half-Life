//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests DrinkTypeAppEnumTests
//

import AppIntents
import Testing

@testable import Half_Life

/// INTENT-ENUM-1 and INTENT-ENUM-2 in the App Intents article.
struct DrinkTypeAppEnumTests {

    /// INTENT-ENUM-1: one case per drink, with the drink's raw value, which maps back to the same drink.
    @Test(arguments: DrinkType.allCases)
    func eachDrinkHasACaseWithItsRawValue(_ type: DrinkType) {
        let mirrored = DrinkTypeAppEnum(type)

        #expect(mirrored.rawValue == type.rawValue)
        #expect(mirrored.drinkType == type)
    }

    /// INTENT-ENUM-1: no case without a drink.
    @Test func thereAreNoExtraCases() {
        #expect(DrinkTypeAppEnum.allCases.count == DrinkType.allCases.count)
        #expect(Set(DrinkTypeAppEnum.allCases.map(\.drinkType)) == Set(DrinkType.allCases))
    }

    /// INTENT-ENUM-2: each case shows the composer's name for its drink.
    @Test(arguments: DrinkType.allCases)
    func eachCaseShowsTheComposersName(_ type: DrinkType) throws {
        let representation = try #require(DrinkTypeAppEnum.caseDisplayRepresentations[DrinkTypeAppEnum(type)])

        #expect(String(localized: representation.title) == String(localized: type.displayName))
    }
}
