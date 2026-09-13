//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests FileInsightFeedbackDataSourceTests
//

import Foundation
import Testing

@testable import Half_Life

/// Checks the file that keeps the "Feel right?" answers, on a temporary directory, against FEEDSTORE-1 to FEEDSTORE-5
/// in the Insights article.
struct FileInsightFeedbackDataSourceTests {

    static func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "InsightFeedback.json")
    }

    static let first = InsightFeedback(
        answer: .disagree, confidence: .earlySign, headline: "Late caffeine, shorter nights",
        sentence: "On 6 nights you slept less.", answeredAt: Date(timeIntervalSinceReferenceDate: 60))
    static let second = InsightFeedback(
        answer: .agree, confidence: .consistent, headline: "A steady pattern", sentence: "Across 12 nights.",
        answeredAt: Date(timeIntervalSinceReferenceDate: 120))

    // MARK: - FEEDSTORE-1: with no file, there are no answers

    @Test func withNoFileThereAreNoAnswers() async throws {
        #expect(try await FileInsightFeedbackDataSource(fileURL: Self.temporaryFile()).answers().isEmpty)
    }

    // MARK: - FEEDSTORE-2: every answer is kept, in order, across instances

    @Test func everyAnswerIsKeptInOrderAcrossInstances() async throws {
        let file = Self.temporaryFile()
        try await FileInsightFeedbackDataSource(fileURL: file).record(Self.first)
        try await FileInsightFeedbackDataSource(fileURL: file).record(Self.second)

        #expect(try await FileInsightFeedbackDataSource(fileURL: file).answers() == [Self.first, Self.second])
    }

    // MARK: - FEEDSTORE-3: the file is written atomically, with complete protection

    /// The simulator doesn't report a file's protection class, so this checks the options the file is written with.
    @Test func theFileIsWrittenAtomicallyWithCompleteProtection() async throws {
        let options = Recorded<[Data.WritingOptions]>([])
        let source = FileInsightFeedbackDataSource(fileURL: Self.temporaryFile()) { data, url, writingOptions in
            options.update { $0.append(writingOptions) }
            try data.write(to: url, options: writingOptions)
        }

        try await source.record(Self.first)

        #expect(options.value == [[.atomic, .completeFileProtection]])
    }

    // MARK: - FEEDSTORE-4: a file that can't be read throws

    @Test func anUnreadableFileThrows() async throws {
        let file = Self.temporaryFile()
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: file)

        await #expect(throws: (any Error).self) {
            try await FileInsightFeedbackDataSource(fileURL: file).answers()
        }
    }

    // MARK: - FEEDSTORE-5: the default file is in Application Support

    @Test func theDefaultFileIsInApplicationSupport() {
        #expect(
            FileInsightFeedbackDataSource().fileURL
                == URL.applicationSupportDirectory.appending(path: "InsightFeedback.json"))
    }
}
