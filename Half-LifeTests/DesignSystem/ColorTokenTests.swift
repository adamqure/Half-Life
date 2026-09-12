//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests ColorTokenTests
//

import Testing
import UIKit

@testable import Half_Life

/// Checks the asset catalog's color sets against the Design System article: their values, and that every
/// documented foreground/surface pairing meets its WCAG contrast threshold (constitution Article VI.3).
struct ColorTokenTests {

    struct Token: Sendable, CustomTestStringConvertible {
        let name: String
        let hex: UInt32
        var alpha: Double = 1

        var testDescription: String { name }
    }

    struct Pairing: Sendable, CustomTestStringConvertible {
        let foreground: String
        let surface: String
        let minimum: Double

        var testDescription: String { "\(foreground) on \(surface) ≥ \(minimum)" }
    }

    /// A color's sRGB channels scaled to 0–255, and its opacity as a percentage.
    struct RGBA: Equatable {
        let red: Int
        let green: Int
        let blue: Int
        let alphaPercent: Int
    }

    /// WCAG AA minimum for body text.
    static let text = 4.5
    /// WCAG AA minimum for large text and graphics.
    static let graphic = 3.0

    static let tokens: [Token] = [
        Token(name: "backgroundCanvasTop", hex: 0xF8F2E9),
        Token(name: "backgroundCanvasBottom", hex: 0xE5DBC9),
        Token(name: "backgroundCanvasGlow", hex: 0xFDFBF9),
        Token(name: "surfaceCard", hex: 0xF9F7F1),
        Token(name: "surfaceControl", hex: 0xFCFBF8),
        Token(name: "surfaceMuted", hex: 0xE1DBD3),
        Token(name: "surfaceEmphasis", hex: 0x3E2C1F),
        Token(name: "surfaceSelected", hex: 0x493B2D),
        Token(name: "surfaceHighlight", hex: 0xFBF9F6),
        Token(name: "textPrimary", hex: 0x2E271F),
        Token(name: "textSecondary", hex: 0x666058),
        Token(name: "textOnEmphasis", hex: 0xF6EFE3),
        Token(name: "textOnEmphasisSecondary", hex: 0xBBB0A0),
        Token(name: "textAccent", hex: 0x84572B),
        Token(name: "AccentColor", hex: 0xB87333),
        Token(name: "accentOnEmphasis", hex: 0xE6B173),
        Token(name: "actionPrimary", hex: 0x3B2C1E),
        Token(name: "controlSelected", hex: 0x3B2C1E),
        Token(name: "controlBorder", hex: 0x827C72),
        Token(name: "controlTrack", hex: 0xDAD4CA),
        Token(name: "separatorOnCard", hex: 0xE8E4DE),
        Token(name: "separatorOnEmphasis", hex: 0x5A4C3D),
        Token(name: "borderOnEmphasis", hex: 0x6C5F51),
        Token(name: "borderCard", hex: 0xFFFFFF, alpha: 0.7),
        Token(name: "feedbackCaution", hex: 0x8C3F1D),
        Token(name: "feedbackCautionBackground", hex: 0xEEDDD4),
        Token(name: "feedbackPositive", hex: 0x4F5E38),
        Token(name: "feedbackPositiveBackground", hex: 0xE3E2D7),
        Token(name: "dataCaffeine", hex: 0xB87333),
        Token(name: "dataCaffeineSubtle", hex: 0xEDDFD1),
        Token(name: "dataSleep", hex: 0x6E7795),
        Token(name: "dataSleepText", hex: 0x5A6486),
        Token(name: "dataSleepSubtle", hex: 0xE2E0E2),
        Token(name: "dataActivity", hex: 0x63713F),
        Token(name: "dataActivitySubtle", hex: 0xE3E3D8),
        Token(name: "dataHeart", hex: 0x9B4459),
        Token(name: "dataHeartSubtle", hex: 0xF1DFE1),
    ]

    /// Light surfaces that carry primary and secondary text.
    static let lightSurfaces = [
        "backgroundCanvasTop", "backgroundCanvasBottom", "surfaceCard", "surfaceControl", "surfaceMuted",
        "surfaceHighlight",
    ]

    /// Dark surfaces that carry on-emphasis text.
    static let darkSurfaces = ["surfaceEmphasis", "surfaceSelected", "actionPrimary", "controlSelected"]

    static let pairings: [Pairing] =
        pairs(["textPrimary", "textSecondary"], on: lightSurfaces, minimum: text)
        + pairs(["textOnEmphasis", "textOnEmphasisSecondary"], on: darkSurfaces, minimum: text)
        + pairs(["accentOnEmphasis"], on: ["surfaceEmphasis"], minimum: text)
        + pairs(["textAccent"], on: ["backgroundCanvasBottom", "surfaceCard", "surfaceControl"], minimum: text)
        + pairs(["feedbackCaution"], on: ["feedbackCautionBackground"], minimum: text)
        + pairs(["feedbackPositive"], on: ["feedbackPositiveBackground"], minimum: text)
        + pairs(["dataSleepText", "dataActivity", "dataHeart"], on: ["surfaceCard"], minimum: text)
        + pairs(["dataHeart"], on: ["backgroundCanvasBottom"], minimum: text)
        + pairs(["AccentColor"], on: ["surfaceCard", "surfaceHighlight"], minimum: graphic)
        + pairs(["dataCaffeine", "dataSleep"], on: ["surfaceCard"], minimum: graphic)
        + pairs(["controlBorder"], on: ["surfaceCard", "surfaceControl"], minimum: graphic)

    static func pairs(_ foregrounds: [String], on surfaces: [String], minimum: Double) -> [Pairing] {
        surfaces.flatMap { surface in
            foregrounds.map { Pairing(foreground: $0, surface: surface, minimum: minimum) }
        }
    }

    @Test(arguments: tokens)
    func colorSetHasDocumentedValue(_ token: Token) throws {
        let color = try #require(UIColor(named: token.name, in: .main, compatibleWith: nil))
        let expected = RGBA(
            red: Int(token.hex >> 16 & 0xFF),
            green: Int(token.hex >> 8 & 0xFF),
            blue: Int(token.hex & 0xFF),
            alphaPercent: Int((token.alpha * 100).rounded())
        )
        #expect(try components(of: color) == expected)
    }

    @Test(arguments: pairings)
    func pairingMeetsContrastMinimum(_ pairing: Pairing) throws {
        let foreground = try #require(UIColor(named: pairing.foreground, in: .main, compatibleWith: nil))
        let surface = try #require(UIColor(named: pairing.surface, in: .main, compatibleWith: nil))
        let first = try relativeLuminance(foreground)
        let second = try relativeLuminance(surface)
        let ratio = (max(first, second) + 0.05) / (min(first, second) + 0.05)
        #expect(ratio >= pairing.minimum, "\(pairing.testDescription) is \(ratio)")
    }

    private func components(of color: UIColor) throws -> RGBA {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        try #require(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        return RGBA(
            red: Int((red * 255).rounded()),
            green: Int((green * 255).rounded()),
            blue: Int((blue * 255).rounded()),
            alphaPercent: Int((alpha * 100).rounded())
        )
    }

    /// WCAG 2 relative luminance of an opaque sRGB color.
    private func relativeLuminance(_ color: UIColor) throws -> Double {
        let rgba = try components(of: color)
        func linear(_ channel: Int) -> Double {
            let value = Double(channel) / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(rgba.red) + 0.7152 * linear(rgba.green) + 0.0722 * linear(rgba.blue)
    }
}
