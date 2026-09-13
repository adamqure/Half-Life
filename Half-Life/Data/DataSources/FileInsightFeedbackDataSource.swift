//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life FileInsightFeedbackDataSource
//

import Foundation
import OSLog

/// The "Feel right?" answers, in a small JSON file on the device.
///
/// The file is written atomically with `NSFileProtectionComplete` (constitution Article V.4), and never syncs. With no
/// file, nothing has been answered. The answers are the user's reaction to their own sleep, so none of their contents
/// is ever logged (Article XI.6). See the Insights article, FEEDSTORE-1 to FEEDSTORE-5.
struct FileInsightFeedbackDataSource: InsightFeedbackDataSource {
    /// One answer, as the file holds it.
    private struct StoredAnswer: Codable {
        let agrees: Bool
        let confidence: String
        let headline: String
        let sentence: String
        let answeredAt: Date
    }

    /// The error for an answer whose confidence the file names but the app doesn't know.
    private struct UnknownConfidence: Error {}

    private static let logger = Logger(for: FileInsightFeedbackDataSource.self)

    /// `InsightFeedback.json` in the app's Application Support directory.
    static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(path: "InsightFeedback.json")
    }

    /// The file the answers are kept in.
    let fileURL: URL
    /// Writes data to a file with the given options.
    let write: @Sendable (Data, URL, Data.WritingOptions) throws -> Void

    /// Creates a store kept in `fileURL`.
    ///
    /// - Parameters:
    ///   - fileURL: The file the answers are kept in. Defaults to ``defaultFileURL``.
    ///   - write: Writes the file. Defaults to `Data`'s own write. Tests check the options through it, because the
    ///     simulator doesn't report a file's protection class.
    init(
        fileURL: URL = Self.defaultFileURL,
        write: @escaping @Sendable (Data, URL, Data.WritingOptions) throws -> Void = {
            try $0.write(to: $1, options: $2)
        }
    ) {
        self.fileURL = fileURL
        self.write = write
    }

    /// Returns every answer stored, in order. With no file, there are none.
    ///
    /// - Throws: An error if the file exists but couldn't be read. It's logged with its domain and code only.
    func answers() async throws -> [InsightFeedback] {
        do {
            return try read().map { try Self.feedback(from: $0) }
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't read the insight feedback: \(domain, privacy: .public) \(code, privacy: .public)")
            throw error
        }
    }

    /// Adds an answer after the others, creating the file's directory if needed.
    ///
    /// - Throws: An error if the file couldn't be read or written. It's logged with its domain and code only.
    func record(_ feedback: InsightFeedback) async throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(try read() + [Self.stored(from: feedback)])
            try write(data, fileURL, [.atomic, .completeFileProtection])
        } catch {
            let domain = (error as NSError).domain
            let code = (error as NSError).code
            Self.logger.error(
                "Couldn't write the insight feedback: \(domain, privacy: .public) \(code, privacy: .public)")
            throw error
        }
    }

    /// The answers in the file, or none if there's no file.
    private func read() throws -> [StoredAnswer] {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return [] }
        return try JSONDecoder().decode([StoredAnswer].self, from: Data(contentsOf: fileURL))
    }

    private static func stored(from feedback: InsightFeedback) -> StoredAnswer {
        let confidence: String =
            switch feedback.confidence {
            case .tooFew: "tooFew"
            case .earlySign: "earlySign"
            case .consistent: "consistent"
            }
        return StoredAnswer(
            agrees: feedback.answer == .agree, confidence: confidence, headline: feedback.headline,
            sentence: feedback.sentence, answeredAt: feedback.answeredAt)
    }

    private static func feedback(from stored: StoredAnswer) throws -> InsightFeedback {
        let confidence: SleepPattern.Confidence
        switch stored.confidence {
        case "tooFew": confidence = .tooFew
        case "earlySign": confidence = .earlySign
        case "consistent": confidence = .consistent
        default: throw UnknownConfidence()
        }
        return InsightFeedback(
            answer: stored.agrees ? .agree : .disagree, confidence: confidence, headline: stored.headline,
            sentence: stored.sentence, answeredAt: stored.answeredAt)
    }
}
