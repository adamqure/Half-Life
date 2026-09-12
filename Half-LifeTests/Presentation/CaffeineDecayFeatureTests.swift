//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeTests CaffeineDecayFeatureTests
//

import ComposableArchitecture
import Foundation
import Testing

@testable import Half_Life

/// Checks the decay card's feature (DECAY-1 to DECAY-4 in the Today Screen article).
///
/// Each observation test lets only one of the three streams emit, so the order of received actions is
/// deterministic.
@MainActor
struct CaffeineDecayFeatureTests {

    // Immutable Sendable values, so the default arguments below can read them outside the main actor.
    nonisolated static let now = Date(timeIntervalSinceReferenceDate: 16 * 3_600)
    nonisolated static let intake = CaffeineIntake(
        id: UUID(), milligrams: 205, consumedAt: now.addingTimeInterval(-3_600))

    static func status(
        active: [CaffeineIntake] = [intake], halfGone: Date? = now.addingTimeInterval(16_200),
        atBedtime: CaffeineLevel? = CaffeineLevel(date: now.addingTimeInterval(23_400), milligrams: 62.4)
    ) -> CaffeineStatus {
        CaffeineStatus(
            level: CaffeineLevel(date: now, milligrams: 180.2), activeIntakes: active, lastIntakeHalfGoneAt: halfGone,
            levelAtBedtime: atBedtime)
    }

    static func store(
        curves: [[CaffeineLevel]] = [], statuses: [CaffeineStatus] = [], time: (any CurrentTimeRepository)? = nil
    ) -> TestStoreOf<CaffeineDecayFeature> {
        let repository = FakeCaffeineDecayRepository(curves: curves, statuses: { _ in statuses })
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        return TestStore(initialState: CaffeineDecayFeature.State()) {
            CaffeineDecayFeature()
        } withDependencies: {
            $0.calendar = utc
            $0.observeCaffeineCurve = ObserveCaffeineCurveUseCase(repository: repository)
            $0.observeCaffeineStatus = ObserveCaffeineStatusUseCase(repository: repository)
            $0.observeTimeOfDay = ObserveTimeOfDayUseCase(currentTime: time ?? SilentCurrentTimeRepository())
        }
    }

    /// DECAY-1: `task` subscribes to the curve, and each curve is reduced into `State`.
    @Test func taskReducesEachCurveIntoState() async {
        let curve = [CaffeineLevel(date: Self.now, milligrams: 180.2)]
        let store = Self.store(curves: [curve])

        await store.send(.task)
        await store.receive(\.curveUpdated) {
            $0.curve = curve
        }
        await store.finish()
    }

    /// DECAY-2: `task` subscribes to the status, and each status is reduced into `State`.
    @Test func taskReducesEachStatusIntoState() async {
        let store = Self.store(statuses: [Self.status()])

        await store.send(.task)
        await store.receive(\.statusUpdated) {
            $0.status = Self.status()
        }
        await store.finish()
    }

    /// DECAY-3: `task` subscribes to the time of day, and each time of day is reduced into `State`.
    @Test func taskReducesEachTimeOfDayIntoState() async {
        let store = Self.store(time: FakeCurrentTimeRepository(date: Self.now))

        await store.send(.task)
        await store.receive(\.timeOfDayUpdated) {
            $0.timeOfDay = TimeOfDay(date: Self.now, period: .afternoon)
        }
        await store.finish()
    }

    /// DECAY-4: before the first status arrives, there's no summary.
    @Test func noSummaryBeforeTheFirstStatus() {
        #expect(CaffeineDecayFeature.State().summary == nil)
    }

    /// DECAY-4: with nothing counting, the summary says the user's system is clear.
    @Test func summaryIsClearWhenNothingCounts() {
        let state = CaffeineDecayFeature.State(status: Self.status(active: [], halfGone: nil))

        #expect(state.summary == .clear)
    }

    /// DECAY-4: while the last cup is still on its way to half gone, the summary gives both tips.
    @Test func summaryGivesBothTipsBeforeTheLastCupIsHalfGone() throws {
        let status = Self.status()
        let state = CaffeineDecayFeature.State(status: status)

        let atBedtime = try #require(status.levelAtBedtime)
        let halfGone = try #require(status.lastIntakeHalfGoneAt)
        #expect(state.summary == .bedtimeAndHalfGone(atBedtime, halfGone: halfGone))
    }

    /// DECAY-4: once the last cup is past half gone, the summary gives only the level at bedtime.
    @Test func summaryGivesOnlyTheBedtimeLevelOnceTheLastCupIsHalfGone() throws {
        let status = Self.status(halfGone: nil)
        let state = CaffeineDecayFeature.State(status: status)

        #expect(state.summary == .bedtime(try #require(status.levelAtBedtime)))
    }
}
