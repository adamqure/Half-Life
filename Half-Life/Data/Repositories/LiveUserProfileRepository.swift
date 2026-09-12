//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life LiveUserProfileRepository
//

import Foundation
import OSLog

/// The app's user profile repository: the source of truth for what the user has told the app.
///
/// It holds the current profile in memory and stores every change through its data source. When the data source
/// signals a change, it re-reads the profile and publishes it to every subscriber, with the recommended sleep that
/// ``SleepNeedRule`` gives for it. It executes ``HalfLifePriorRule`` when the factors are saved, and stores the
/// half-life with them. It's an actor, off the main actor (constitution Article I.13). The Today Screen and
/// Onboarding articles list its requirements, PROF-1 to PROF-7.
actor LiveUserProfileRepository: UserProfileRepository {
    private static let logger = Logger(for: LiveUserProfileRepository.self)

    /// A recommended sleep subscriber: its stream, and the calendar its age is counted in.
    private struct SleepSubscriber {
        let calendar: Calendar
        let continuation: AsyncStream<RecommendedSleep>.Continuation
    }

    private let dataSource: any UserProfileDataSource
    private let clock: any ClockDataSource
    private let priorRule = HalfLifePriorRule()
    private let sleepRule = SleepNeedRule()
    /// The profile as last read or saved, or `nil` until it's first needed.
    private var current: UserProfile?
    private var profileSubscribers: [UUID: AsyncStream<UserProfile>.Continuation] = [:]
    private var sleepSubscribers: [UUID: SleepSubscriber] = [:]
    private var isListening = false
    private var changeListener: Task<Void, Never>?

    /// Creates the repository.
    ///
    /// - Parameters:
    ///   - dataSource: Where the profile is stored.
    ///   - clock: The current time, for the user's age.
    init(dataSource: any UserProfileDataSource, clock: any ClockDataSource) {
        self.dataSource = dataSource
        self.clock = clock
    }

    deinit {
        changeListener?.cancel()
    }

    /// Streams the profile: the current one as soon as it's subscribed to, then every change the data source signals.
    nonisolated func profile() -> AsyncStream<UserProfile> {
        let (stream, continuation) = AsyncStream.makeStream(of: UserProfile.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeProfileSubscriber(id) }
        }
        Task { await addProfileSubscriber(id, continuation) }
        return stream
    }

    /// Streams the recommended sleep for the user's age: the current range, then one after every change.
    ///
    /// - Parameter calendar: The calendar whose year the user's age is counted in.
    nonisolated func recommendedSleep(in calendar: Calendar) -> AsyncStream<RecommendedSleep> {
        let (stream, continuation) = AsyncStream.makeStream(of: RecommendedSleep.self)
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSleepSubscriber(id) }
        }
        Task { await addSleepSubscriber(id, SleepSubscriber(calendar: calendar, continuation: continuation)) }
        return stream
    }

    /// Saves the name and birth year, keeping the rest of the profile.
    func saveAboutYou(name: String?, birthYear: Int?) async throws {
        let profile = await loadedProfile()
        try await save(
            UserProfile(
                name: name, birthYear: birthYear, halfLifeFactors: profile.halfLifeFactors, bedtime: profile.bedtime,
                halfLife: profile.halfLife, hasCompletedOnboarding: profile.hasCompletedOnboarding))
    }

    /// Saves the factors, with the half-life ``HalfLifePriorRule`` gives for them.
    func saveHalfLifeFactors(_ factors: Set<HalfLifeFactor>) async throws {
        let profile = await loadedProfile()
        try await save(
            UserProfile(
                name: profile.name, birthYear: profile.birthYear, halfLifeFactors: factors, bedtime: profile.bedtime,
                halfLife: priorRule.halfLife(for: factors), hasCompletedOnboarding: profile.hasCompletedOnboarding))
    }

    /// Saves the bedtime, keeping the rest of the profile.
    func saveBedtime(_ bedtime: Bedtime) async throws {
        let profile = await loadedProfile()
        try await save(
            UserProfile(
                name: profile.name, birthYear: profile.birthYear, halfLifeFactors: profile.halfLifeFactors,
                bedtime: bedtime, halfLife: profile.halfLife, hasCompletedOnboarding: profile.hasCompletedOnboarding))
    }

    /// Records that onboarding is complete, keeping the rest of the profile.
    func completeOnboarding() async throws {
        let profile = await loadedProfile()
        try await save(
            UserProfile(
                name: profile.name, birthYear: profile.birthYear, halfLifeFactors: profile.halfLifeFactors,
                bedtime: profile.bedtime, halfLife: profile.halfLife, hasCompletedOnboarding: true))
        Self.logger.notice("Onboarding completed")
    }

    /// Starts listening to the data source before the first profile goes out, so no change after it is missed.
    private func addProfileSubscriber(_ id: UUID, _ continuation: AsyncStream<UserProfile>.Continuation) async {
        await listenForChanges()
        profileSubscribers[id] = continuation
        continuation.yield(await loadedProfile())
    }

    private func removeProfileSubscriber(_ id: UUID) {
        profileSubscribers[id] = nil
    }

    private func addSleepSubscriber(_ id: UUID, _ subscriber: SleepSubscriber) async {
        await listenForChanges()
        sleepSubscribers[id] = subscriber
        subscriber.continuation.yield(recommendedSleep(for: await loadedProfile(), in: subscriber.calendar))
    }

    private func removeSleepSubscriber(_ id: UUID) {
        sleepSubscribers[id] = nil
    }

    /// Subscribes to the data source's changes once, for the life of the repository.
    private func listenForChanges() async {
        guard !isListening else { return }
        isListening = true
        let changes = await dataSource.changes()
        changeListener = Task { [weak self] in
            for await _ in changes {
                await self?.publishChange()
            }
        }
    }

    /// Re-reads the profile after the data source signals, and publishes it and its recommended sleep.
    private func publishChange() async {
        let profile = await readProfile()
        current = profile
        for subscriber in profileSubscribers.values {
            subscriber.yield(profile)
        }
        for subscriber in sleepSubscribers.values {
            subscriber.continuation.yield(recommendedSleep(for: profile, in: subscriber.calendar))
        }
    }

    private func recommendedSleep(for profile: UserProfile, in calendar: Calendar) -> RecommendedSleep {
        sleepRule.recommendedSleep(birthYear: profile.birthYear, now: clock.now(), calendar: calendar)
    }

    /// The profile in memory, read from the data source the first time it's needed.
    private func loadedProfile() async -> UserProfile {
        if let current { return current }
        let profile = await readProfile()
        current = profile
        return profile
    }

    /// Reads the stored profile. One that doesn't exist or can't be read is a profile with nothing given, so the
    /// user can fill it in again.
    private func readProfile() async -> UserProfile {
        do {
            return try await dataSource.storedProfile() ?? UserProfile()
        } catch {
            let error = error as NSError
            Self.logger.error(
                "Couldn't read the profile: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            return UserProfile()
        }
    }

    /// Makes `profile` the current one, then stores it. A later save builds on it even before the store finishes. If
    /// the store fails, the next read replaces it with what's actually stored.
    private func save(_ profile: UserProfile) async throws {
        current = profile
        do {
            try await dataSource.store(profile)
        } catch {
            current = nil
            let error = error as NSError
            Self.logger.error(
                "Couldn't save the profile: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            throw error
        }
    }
}
