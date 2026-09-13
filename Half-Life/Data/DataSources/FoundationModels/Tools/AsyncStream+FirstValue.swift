//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AsyncStream+FirstValue
//

extension AsyncStream {
    /// The first value the stream emits, or `nil` if it finishes without one.
    ///
    /// A repository's stream emits its current value first, so a tool reads the current value this way, and stops
    /// listening straight after.
    func firstValue() async -> Element? {
        for await value in self {
            return value
        }
        return nil
    }
}
