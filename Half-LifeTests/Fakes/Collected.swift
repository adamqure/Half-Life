//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests Collected
//

/// Collects every value a stream sends, in the background, so a test can wait for a number of them, or check that no
/// more arrive.
final class Collected<Element: Sendable>: Sendable {
    private let received = Recorded<[Element]>([])
    private let task: Task<Void, Never>

    init(_ stream: AsyncStream<Element>) {
        let received = received
        task = Task {
            for await value in stream {
                received.update { $0.append(value) }
            }
        }
    }

    /// The values received so far, in order.
    var values: [Element] {
        received.value
    }

    /// Waits until `count` values have arrived, or `timeout` has passed, and returns the values received by then.
    func waitForCount(_ count: Int, timeout: Duration = .seconds(2)) async -> [Element] {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while received.value.count < count, clock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
        return received.value
    }

    /// Waits long enough for any value already on its way to arrive, and returns the values received by then.
    func settled() async -> [Element] {
        try? await Task.sleep(for: .milliseconds(200))
        return received.value
    }

    /// Stops listening, which ends the subscription.
    func cancel() {
        task.cancel()
    }
}
