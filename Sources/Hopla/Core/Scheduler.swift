import CoreGraphics
import Foundation

/// Decides when Hopla visits. Being away from the Mac counts as a break,
/// so the timer restarts when you come back instead of greeting you immediately.
@MainActor
final class Scheduler {
    private(set) var nextDue: Date
    private let onDue: () -> Void
    private let isBusy: () -> Bool
    private var timer: Timer?
    private var wasAway = false
    /// True while the next visit is one the user asked for ("Later"): it comes back even outside active hours.
    private var snoozed = false

    private static let awayAfter: TimeInterval = 5 * 60

    init(onDue: @escaping () -> Void, isBusy: @escaping () -> Bool) {
        self.onDue = onDue
        self.isBusy = isBusy
        self.nextDue = Date().addingTimeInterval(Double(Settings.shared.intervalMinutes) * 60)
    }

    private var interval: TimeInterval { Double(max(Settings.shared.intervalMinutes, 5)) * 60 }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func reschedule() {
        snoozed = false
        nextDue = Date().addingTimeInterval(interval)
    }

    /// `explicit`: the user asked for it, so it comes back even outside active hours.
    func snooze(minutes: Int, explicit: Bool = true) {
        snoozed = explicit
        nextDue = Date().addingTimeInterval(Double(min(max(minutes, 1), 24 * 60)) * 60)
    }

    /// Test hooks.
    func schedule(at date: Date) { snoozed = false; nextDue = date }
    func snooze(until date: Date) { snoozed = true; nextDue = date }

    private var lastTick = Date()

    /// Seconds since the last keyboard or mouse event (replaceable in tests).
    var idleSeconds: () -> TimeInterval = {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }

    func tick() {
        let now = Date()
        // No tick runs while the Mac sleeps, and the idle counter resets on wake: a long gap is an absence too.
        if now.timeIntervalSince(lastTick) > Scheduler.awayAfter { wasAway = true }
        lastTick = now
        let idle = idleSeconds()
        if idle > Scheduler.awayAfter {
            wasAway = true
            return
        }
        if wasAway {
            wasAway = false
            reschedule()
            return
        }
        if let paused = Settings.shared.pausedUntil, paused > now {
            reschedule()
            return
        }
        guard snoozed || Settings.shared.isActiveTime(now) else {
            reschedule()
            return
        }
        guard now >= nextDue, !isBusy() else { return }
        // In a call or a full-screen app: try again at the next tick instead of interrupting.
        guard !Presence.shouldStayQuiet() else { return }
        onDue()
    }
}
