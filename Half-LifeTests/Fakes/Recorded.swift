//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests Recorded
//

import Synchronization

/// A value that a stand-in's closures record into, guarded by a mutex.
///
/// It's a class, so escaping `@Sendable` closures can capture it. A `Mutex` on its own is noncopyable, and an
/// escaping closure can't capture one.
final class Recorded<Value: Sendable>: Sendable {
    private let mutex: Mutex<Value>

    init(_ initial: Value) {
        mutex = Mutex(initial)
    }

    /// The value now.
    var value: Value {
        mutex.withLock { $0 }
    }

    /// Changes the value.
    func update(_ change: (inout Value) -> Void) {
        mutex.withLock { change(&$0) }
    }
}
