//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life InsightNumberRule
//

import Foundation

/// The check that the model's finding holds no number the facts don't: a guard on the Insights tab's first card.
///
/// The rules calculate, and the model only phrases (see the Language Model article). So every number in the model's
/// headline and sentence has to be one the facts in its prompt gave it. A finding with any other number is
/// discarded, and the card stays hidden. Numbers are runs of decimal digits in any script, so "٦" and "6" are the same.
/// Numbers written as words aren't caught. It holds no state. See the Insights article, NUMCHECK-1 to NUMCHECK-4.
struct InsightNumberRule {
    /// Returns whether every number in `text` is also in `facts`.
    ///
    /// - Parameters:
    ///   - text: The model's headline and sentence.
    ///   - facts: What the tool gave the model.
    func isGrounded(_ text: String, in facts: String) -> Bool {
        numbers(in: text).isSubset(of: numbers(in: facts))
    }

    /// The runs of decimal digits in `text`, each written with ASCII digits.
    private func numbers(in text: String) -> Set<String> {
        var numbers: Set<String> = []
        var current = ""
        for character in text {
            if let digit = Self.decimalDigit(character) {
                current.append(String(digit))
            } else if !current.isEmpty {
                numbers.insert(current)
                current = ""
            }
        }
        if !current.isEmpty {
            numbers.insert(current)
        }
        return numbers
    }

    /// The value of `character` if it's a decimal digit in any script, such as "7" or "٧".
    private static func decimalDigit(_ character: Character) -> Int? {
        guard character.unicodeScalars.count == 1, let scalar = character.unicodeScalars.first,
            scalar.properties.numericType == .decimal, let value = character.wholeNumberValue
        else { return nil }
        return value
    }
}
