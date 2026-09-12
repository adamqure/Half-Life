//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests PurposeStringTests
//

import Foundation
import Testing

/// Checks the purpose strings iOS shows when Half-Life asks for access to Health, Siri, or Face ID (PURPOSE-1 to
/// PURPOSE-3 in the Architecture article, constitution Articles V.3.2 and VII).
struct PurposeStringTests {

    /// Every purpose string the app declares.
    static let keys = [
        "NSFaceIDUsageDescription",
        "NSHealthClinicalHealthRecordsShareUsageDescription",
        "NSHealthShareUsageDescription",
        "NSHealthUpdateUsageDescription",
        "NSSiriUsageDescription",
    ]

    /// PURPOSE-1: the Info.plist declares the key, which App Store validation and the frameworks require.
    @Test(arguments: keys)
    func infoPlistDeclaresKey(_ key: String) throws {
        let placeholder = try #require(Bundle.main.infoDictionary?[key] as? String)
        #expect(!placeholder.isEmpty)
    }

    /// PURPOSE-2: every localization the app ships translates the key. A localization without it would show the
    /// Info.plist's placeholder instead.
    @Test(arguments: keys)
    func everyLocalizationTranslatesKey(_ key: String) throws {
        let placeholder = Bundle.main.infoDictionary?[key] as? String
        let localizations = Bundle.main.localizations.filter { $0 != "Base" }
        #expect(!localizations.isEmpty)
        for localization in localizations {
            let table = try #require(Self.infoPlistTable(for: localization), "\(localization) has no InfoPlist table")
            let text = try #require(table[key], "\(localization) doesn't translate \(key)")
            #expect(!text.isEmpty)
            #expect(text != placeholder)
        }
    }

    /// PURPOSE-3: the text the system looks up comes from the String Catalog, not the Info.plist's placeholder.
    @Test(arguments: keys)
    func lookupReturnsCatalogText(_ key: String) throws {
        let placeholder = Bundle.main.infoDictionary?[key] as? String
        let text = try #require(Bundle.main.object(forInfoDictionaryKey: key) as? String)
        #expect(!text.isEmpty)
        #expect(text != placeholder)
    }

    /// Reads the compiled `InfoPlist.strings` table for a localization.
    private static func infoPlistTable(for localization: String) -> [String: String]? {
        guard
            let url = Bundle.main.url(
                forResource: "InfoPlist", withExtension: "strings", subdirectory: nil, localization: localization),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
    }
}
