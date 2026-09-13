//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FakeInsightFeedbackDataSource
//

import Foundation

@testable import Half_Life

/// An in-memory store of "Feel right?" answers, for repository tests. It can be told to fail reads or records.
actor FakeInsightFeedbackDataSource: InsightFeedbackDataSource {
    /// The answers it holds, in order.
    private(set) var stored: [InsightFeedback]
    private var readError: (any Error)?
    private var recordError: (any Error)?

    init(answers: [InsightFeedback] = []) {
        stored = answers
    }

    /// Makes every read throw `error`, or read normally again when it's `nil`.
    func failReads(with error: (any Error)?) {
        readError = error
    }

    /// Makes every record throw `error`, or record normally again when it's `nil`.
    func failRecords(with error: (any Error)?) {
        recordError = error
    }

    func answers() throws -> [InsightFeedback] {
        if let readError { throw readError }
        return stored
    }

    func record(_ feedback: InsightFeedback) throws {
        if let recordError { throw recordError }
        stored.append(feedback)
    }
}
