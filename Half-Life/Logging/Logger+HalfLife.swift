//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life Logger+HalfLife
//

import OSLog

extension Logger {
    /// Creates a logger in Half-Life's subsystem, categorized by the type that owns it (constitution Article XI.2).
    ///
    /// - Parameter owner: The type that logs. Its name becomes the category.
    init<Owner>(for owner: Owner.Type) {
        self.init(subsystem: "com.quillanq.Half-Life", category: String(describing: owner))
    }
}
