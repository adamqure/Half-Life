//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests SwiftDataStoreTests
//

import Testing

/// The parent of every suite that opens a SwiftData store. It's serialized, so no two of its tests open stores at
/// the same time.
///
/// A full parallel run on 2026-09-11 crashed the test host inside Core Data while a test opened an in-memory store
/// (`EXC_BAD_ACCESS` in `-[NSSQLEntity_DerivedAttributesExtension _generateTriggerSQL]`). Opening 64 stores at once,
/// ten times over, didn't reproduce it, so the cause isn't pinned down. Serializing the tests that open stores was
/// enough for the next full run. The app itself opens one store.
@Suite(.serialized)
enum SwiftDataStoreTests {}
