import AppKit
import Combine
import Foundation
import SwiftUI

/// Hopla's life cycle: arrives → asks (Go / Snooze) → exercises → celebrates → leaves and disappears.
@MainActor
final class PetController: ObservableObject {
    enum Phase: Equatable {
        case hidden, arriving, asking
        case exercising(Int)
        /// A short pause to stand up or sit down before exercise n.
        case changingPosture(Int)
        case celebrating
        case farewell(String)
        case leaving
    }

    /// `ignored`: nobody answered, so the visit comes back later but only within active hours.
    enum Outcome { case completed, stopped, ignored, snoozed(Int) }

    static let snoozeChoices = [5, 15, 30, 60]
    private static let askTimeout: TimeInterval = 120

    @Published private(set) var phase: Phase = .hidden
    @Published var showSnoozeOptions = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var remaining = 0
    @Published var avatar: Avatar = AvatarLibrary.current()
    private(set) var session: [SessionStep] = []

    var onShow: (() -> Void)?
    var onHide: ((Outcome) -> Void)?

    private var clip = Moves.idle
    private var clipStart = Date()
    private var fromPose: Pose?
    private var blendStart = Date()
    private static let blendDuration = 0.35

    private var generation = 0
    private var ticker: Timer?
    private var outcome: Outcome = .stopped
    private var timeScale: Double { Settings.shared.fastMode ? 0.25 : 1 }
    /// macOS setting "Reduce motion": no hops, pops or bounces, just fades.
    private var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    private var subscriptions: Set<AnyCancellable> = []

    init() {
        // Picking another avatar in the settings changes Hopla right away, even mid-visit.
        Settings.shared.$avatarID.dropFirst().sink { [weak self] id in
            guard let avatar = AvatarLibrary.all().first(where: { $0.id == id }) else { return }
            DispatchQueue.main.async { self?.avatar = avatar }
        }.store(in: &subscriptions)
    }

    // MARK: Keyboard shortcuts

    func callOrGo() {
        switch phase {
        case .hidden: present()
        case .asking: go()
        case .farewell, .leaving: comeBackAfterLeaving = true
        default: break
        }
    }

    /// Set when Hopla is called while it is on its way out.
    private var comeBackAfterLeaving = false

    func laterOrStop() {
        switch phase {
        case .asking: snooze(minutes: Settings.shared.snoozeMinutes)
        case .exercising, .changingPosture: stop()
        default: break
        }
    }

    // MARK: Animation

    func pose(at date: Date) -> Pose {
        let target = clip.sample(date.timeIntervalSince(clipStart))
        guard let from = fromPose else { return target }
        let k = date.timeIntervalSince(blendStart) / PetController.blendDuration
        return k >= 1 ? target : Pose.lerp(from, target, Ease.inOut.apply(k))
    }

    private func play(_ next: Clip, blend: Bool = true) {
        let now = Date()
        fromPose = blend ? pose(at: now) : nil
        clip = next
        clipStart = now
        blendStart = now
    }

    /// Runs `block` later unless the phase changed in the meantime.
    private func after(_ seconds: Double, _ block: @escaping () -> Void) {
        let g = generation
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self, self.generation == g else { return }
            block()
        }
    }

    private func enter(_ next: Phase) {
        generation += 1
        phase = next
    }

    // MARK: Flow

    func present() {
        guard phase == .hidden else {
            if case .farewell = phase { comeBackAfterLeaving = true }
            if phase == .leaving { comeBackAfterLeaving = true }
            return
        }
        avatar = AvatarLibrary.current()
        showSnoozeOptions = false
        enter(.arriving)
        let entrance = reduceMotion ? Moves.fadeIn : Moves.arrive
        play(entrance, blend: false)
        onShow?()
        Sound.play(.arrive, for: avatar)
        after(entrance.duration) { self.ask() }
    }

    private func ask() {
        enter(.asking)
        play(reduceMotion ? Moves.idle : Moves.wave)
        after(1.6) { self.play(Moves.idle) }
        after(PetController.askTimeout) {
            self.snooze(minutes: Settings.shared.snoozeMinutes, message: tr("Je repasse plus tard 👋", "I'll come back later 👋"))
            self.outcome = .ignored
        }
    }

    func go() {
        guard phase == .asking else { return }
        session = RouteBook.nextSession()
        finishedSteps = 0
        Sound.play(.go, for: avatar)
        // You're at your desk: if the first move is a standing one, give time to stand up.
        begin(0, from: .seated)
    }

    func snooze(minutes: Int, message: String? = nil) {
        stopTicker()
        outcome = .snoozed(minutes)
        enter(.farewell(message ?? tr("À dans \(minutes) min ! 💤", "See you in \(minutes) min! 💤")))
        Sound.play(.snooze, for: avatar)
        play(Moves.wave)
        after(1.4) { self.leave() }
    }

    func skip() {
        switch phase {
        case .exercising(let i): next(after: i)
        case .changingPosture(let i): startExercise(i)
        default: break
        }
    }

    /// Seconds given to stand up or sit down between a seated and a standing exercise.
    static let postureChangeSeconds = 3.0

    private func begin(_ i: Int, from previous: Posture) {
        if session[i].exercise.posture != previous { changePosture(before: i) } else { startExercise(i) }
    }

    private func changePosture(before i: Int) {
        let duration = PetController.postureChangeSeconds * timeScale
        enter(.changingPosture(i))
        play(session[i].exercise.posture == .standing ? Moves.standUp : Moves.sitDown)
        Sound.play(.next, for: avatar)
        startCountdown(duration)
        after(duration) { self.startExercise(i) }
    }

    private func startCountdown(_ duration: Double) {
        progress = 0
        remaining = Int(duration.rounded(.up))
        stopTicker()
        let start = Date()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let elapsed = Date().timeIntervalSince(start)
                self.progress = min(elapsed / duration, 1)
                self.remaining = max(Int((duration - elapsed).rounded(.up)), 0)
            }
        }
    }

    func stop() {
        stopTicker()
        outcome = .stopped
        enter(.farewell(tr("Pas de souci, à plus tard !", "No worries, see you later!")))
        play(Moves.wave)
        after(1.4) { self.leave() }
    }

    private func startExercise(_ i: Int) {
        let step = session[i]
        let duration = step.seconds * timeScale
        let afterPostureChange: Bool
        if case .changingPosture = phase { afterPostureChange = true } else { afterPostureChange = false }
        enter(.exercising(i))
        play(step.exercise.clip)
        if i > 0 && !afterPostureChange { Sound.play(.next, for: avatar) }
        startCountdown(duration)
        after(duration) {
            self.finishedSteps += 1
            self.next(after: i)
        }
    }

    /// Exercises that ran to the end (not skipped): a break only counts if at least one did.
    private var finishedSteps = 0

    private func next(after i: Int) {
        if i + 1 < session.count { begin(i + 1, from: session[i].exercise.posture) } else { celebrate() }
    }

    private func celebrate() {
        stopTicker()
        if finishedSteps > 0 { Stats.shared.recordSession() }
        outcome = .completed
        enter(.celebrating)
        play(reduceMotion ? Moves.calmCheer : Moves.celebrate)
        Sound.play(.celebrate, for: avatar)
        after(3.0) { self.leave() }
    }

    private func leave() {
        enter(.leaving)
        let exit = reduceMotion ? Moves.fadeOut : Moves.leave
        play(exit)
        after(exit.duration + 0.05) {
            self.enter(.hidden)
            self.fromPose = nil
            self.onHide?(self.outcome)
            if self.comeBackAfterLeaving {
                self.comeBackAfterLeaving = false
                self.present()
            }
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    /// Freezes a given phase, used by `--render` to snapshot the bubbles.
    func debugFreeze(_ phase: Phase, session: [SessionStep] = [], progress: Double = 0, remaining: Int = 0) {
        self.phase = phase
        self.session = session
        self.progress = progress
        self.remaining = remaining
        self.clip = phase == .celebrating ? Moves.celebrate : Moves.idle
        self.fromPose = nil
    }
}
