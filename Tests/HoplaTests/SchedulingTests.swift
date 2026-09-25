import Foundation
import Testing
@testable import Hopla

@Suite(.serialized) @MainActor struct SchedulingTests {
    init() {
        let s = Settings.shared
        s.quietDuringCalls = false      // a real call on the test machine must not change the results
        s.pausedUntil = nil
        s.activeDays = [1, 2, 3, 4, 5, 6, 7]
        s.startHour = 0
        s.endHour = 24
    }

    @Test func dueVisitHappensDuringActiveHours() {
        var visits = 0
        let scheduler = Scheduler(onDue: { visits += 1 }, isBusy: { false })
        scheduler.idleSeconds = { 0 }
        scheduler.schedule(at: Date().addingTimeInterval(-1))
        scheduler.tick()
        #expect(visits == 1)
    }

    @Test func noVisitOutsideActiveHoursUnlessTheUserAskedLater() {
        Settings.shared.activeDays = []
        var visits = 0
        let scheduler = Scheduler(onDue: { visits += 1 }, isBusy: { false })
        scheduler.idleSeconds = { 0 }
        scheduler.schedule(at: Date().addingTimeInterval(-1))
        scheduler.tick()
        #expect(visits == 0)
        scheduler.snooze(until: Date().addingTimeInterval(-1))
        scheduler.tick()
        #expect(visits == 1, "an explicit “Later” is always honored")
    }

    @Test func ignoredVisitsDoNotComeBackOutsideActiveHours() {
        Settings.shared.activeDays = []
        var visits = 0
        let scheduler = Scheduler(onDue: { visits += 1 }, isBusy: { false })
        scheduler.idleSeconds = { 0 }
        scheduler.snooze(minutes: 15, explicit: false)
        scheduler.schedule(at: Date().addingTimeInterval(-1))
        scheduler.tick()
        #expect(visits == 0)
    }

    @Test func pauseWins() {
        Settings.shared.pausedUntil = Date().addingTimeInterval(3600)
        var visits = 0
        let scheduler = Scheduler(onDue: { visits += 1 }, isBusy: { false })
        scheduler.idleSeconds = { 0 }
        scheduler.snooze(until: Date().addingTimeInterval(-1))
        scheduler.tick()
        #expect(visits == 0)
        Settings.shared.pausedUntil = nil
    }

    @Test func beingAwayCountsAsABreak() {
        var visits = 0
        let scheduler = Scheduler(onDue: { visits += 1 }, isBusy: { false })
        scheduler.idleSeconds = { 600 }
        scheduler.schedule(at: Date().addingTimeInterval(-1))
        scheduler.tick()
        #expect(visits == 0, "no visit while you're away")
        scheduler.idleSeconds = { 1 }
        scheduler.tick()
        #expect(visits == 0, "coming back restarts the timer instead of greeting you at once")
    }

    @Test func busyHoplaIsNotInterrupted() {
        var visits = 0
        let scheduler = Scheduler(onDue: { visits += 1 }, isBusy: { true })
        scheduler.idleSeconds = { 0 }
        scheduler.schedule(at: Date().addingTimeInterval(-1))
        scheduler.tick()
        #expect(visits == 0)
    }

    @Test func hoursCanWrapPastMidnight() throws {
        let s = Settings.shared
        s.startHour = 22
        s.endHour = 6
        let cal = Calendar.current
        let day = cal.startOfDay(for: Date())
        let at23 = try #require(cal.date(byAdding: .hour, value: 23, to: day))
        let at3 = try #require(cal.date(byAdding: .hour, value: 3, to: day))
        let at12 = try #require(cal.date(byAdding: .hour, value: 12, to: day))
        #expect(s.isActiveTime(at23))
        #expect(s.isActiveTime(at3))
        #expect(!s.isActiveTime(at12))
    }
}

@Suite(.serialized) struct StatsTests {
    @Test func streakCountsConsecutiveDays() throws {
        let d = hoplaDefaults
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var history: [String: Int] = [:]
        for back in [1, 2, 3, 5] {
            history[Stats.dayKey(try #require(cal.date(byAdding: .day, value: -back, to: today)))] = 2
        }
        d.set(history, forKey: "stats.history")
        #expect(Stats.shared.streak == 3, "yesterday, the day before and the one before (today not done yet)")
        Stats.shared.recordSession()
        #expect(Stats.shared.sessionsToday == 1)
        #expect(Stats.shared.streak == 4)
        d.removeObject(forKey: "stats.history")
    }
}
