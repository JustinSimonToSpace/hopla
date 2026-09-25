import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var panel: PetPanel!
    private var host: NSView!
    private let controller = PetController()
    private var scheduler: Scheduler!
    private var subscriptions: Set<AnyCancellable> = []
    private var movingProgrammatically = false
    private let settings = Settings.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        AvatarLibrary.bootstrapUserFolder()

        host = FirstClickHostingView(rootView: PetView(controller: controller))
        panel = PetPanel(content: host)
        resizePanel()

        scheduler = Scheduler(
            onDue: { [weak self] in self?.controller.present() },
            isBusy: { [weak self] in self?.controller.phase != .hidden }
        )
        controller.onShow = { [weak self] in
            self?.placePanel()
            self?.panel.orderFrontRegardless()
        }
        controller.onHide = { [weak self] outcome in
            self?.panel.orderOut(nil)
            switch outcome {
            case .snoozed(let minutes): self?.scheduler.snooze(minutes: minutes)
            case .ignored: self?.scheduler.snooze(minutes: Settings.shared.snoozeMinutes, explicit: false)
            case .completed, .stopped: self?.scheduler.reschedule()
            }
        }
        scheduler.start()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = AppIcon.menuBarImage()
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        observeSettings()

        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--selftest") {
            SelfTest.run(panel: panel, controller: controller, outputDirectory: i + 1 < args.count ? args[i + 1] : "selftest")
        } else if let i = args.firstIndex(of: "--snapshot-settings") {
            SelfTest.snapshotSettings(controller: controller, outputDirectory: i + 1 < args.count ? args[i + 1] : "settings")
        } else if args.contains("--settings") {
            SettingsWindow.shared.show(controller: controller)
        } else if args.contains("--now") {
            controller.present()
        }
    }

    private func observeSettings() {
        settings.$intervalMinutes.dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.scheduler.reschedule() }
        }.store(in: &subscriptions)
        settings.$size.dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.resizePanel(); self?.placePanel() }
        }.store(in: &subscriptions)
        settings.$corner.dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.placePanel() }
        }.store(in: &subscriptions)
        settings.$hotkeysEnabled.sink { [weak self] enabled in
            DispatchQueue.main.async { self?.updateHotKeys(enabled) }
        }.store(in: &subscriptions)
        NotificationCenter.default.publisher(for: NSWindow.didMoveNotification, object: panel).sink { [weak self] _ in
            self?.rememberDraggedPosition()
        }.store(in: &subscriptions)
    }

    // MARK: Panel placement

    private func resizePanel() {
        let scale = settings.size.scale
        let size = NSSize(width: PetView.size.width * scale, height: PetView.size.height * scale)
        movingProgrammatically = true
        panel.setContentSize(size)
        host.frame = NSRect(origin: .zero, size: size)
        movingProgrammatically = false
    }

    private var targetScreen: NSScreen {
        if settings.screen == .mouse,
           let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) {
            return screen
        }
        return NSScreen.main ?? NSScreen.screens[0]
    }

    private func placePanel() {
        let area = targetScreen.visibleFrame
        let size = panel.frame.size
        let origin: NSPoint
        switch settings.corner {
        case .bottomRight: origin = NSPoint(x: area.maxX - size.width - 8, y: area.minY + 4)
        case .bottomLeft: origin = NSPoint(x: area.minX + 8, y: area.minY + 4)
        case .topRight: origin = NSPoint(x: area.maxX - size.width - 8, y: area.maxY - size.height)
        case .topLeft: origin = NSPoint(x: area.minX + 8, y: area.maxY - size.height)
        case .custom:
            let p = settings.customPosition ?? CGPoint(x: 1, y: 0)
            origin = NSPoint(x: area.minX + p.x * (area.width - size.width), y: area.minY + p.y * (area.height - size.height))
        }
        movingProgrammatically = true
        panel.setFrameOrigin(origin)
        movingProgrammatically = false
    }

    /// Dropping Hopla somewhere makes that its new home.
    private func rememberDraggedPosition() {
        guard !movingProgrammatically, panel.isVisible, let screen = panel.screen else { return }
        let area = screen.visibleFrame, frame = panel.frame
        let x = (frame.minX - area.minX) / max(1, area.width - frame.width)
        let y = (frame.minY - area.minY) / max(1, area.height - frame.height)
        settings.customPosition = CGPoint(x: min(max(x, 0), 1), y: min(max(y, 0), 1))
        if settings.corner != .custom { settings.corner = .custom }
    }

    private func updateHotKeys(_ enabled: Bool) {
        guard enabled else { HotKeys.shared.uninstall(); return }
        HotKeys.shared.install(go: { [weak self] in self?.controller.callOrGo() },
                               later: { [weak self] in self?.controller.laterOrStop() })
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let stats = Stats.shared
        menu.addItem(item(tr("Hopla ! Bouger maintenant", "Hopla! Move now"), #selector(presentNow), key: "h"))
        if let paused = settings.pausedUntil, paused > Date() {
            menu.addItem(info(tr("En pause jusqu'à \(paused.formatted(date: .omitted, time: .shortened))",
                                 "Paused until \(paused.formatted(date: .omitted, time: .shortened))")))
        } else {
            let next = scheduler.nextDue.formatted(date: .omitted, time: .shortened)
            if scheduler.nextDue < Date(), Presence.shouldStayQuiet() {
                menu.addItem(info(tr("En attente : appel ou partage d'écran en cours", "Waiting: call or screen sharing in progress")))
            } else {
                menu.addItem(info(tr("Prochain passage vers \(next)", "Next visit around \(next)")))
            }
        }
        menu.addItem(info(tr("Aujourd'hui : \(stats.sessionsToday)/\(settings.dailyGoal) pauses · série : \(stats.streak) j",
                             "Today: \(stats.sessionsToday)/\(settings.dailyGoal) breaks · streak: \(stats.streak) d")))
        menu.addItem(.separator())

        let pause = NSMenu()
        for (label, tag) in [(tr("1 heure", "1 hour"), 60), (tr("2 heures", "2 hours"), 120), (tr("Jusqu'à demain", "Until tomorrow"), -1)] {
            let it = item(label, #selector(pause(_:)))
            it.tag = tag
            pause.addItem(it)
        }
        if settings.pausedUntil.map({ $0 > Date() }) == true {
            pause.addItem(.separator())
            let resume = item(tr("Reprendre", "Resume"), #selector(pause(_:)))
            resume.tag = 0
            pause.addItem(resume)
        }
        menu.addItem(submenu(tr("Pause", "Pause"), pause))
        menu.addItem(item(tr("Réglages…", "Settings…"), #selector(openSettings), key: ","))
        menu.addItem(.separator())
        menu.addItem(item(tr("Quitter Hopla", "Quit Hopla"), #selector(quit), key: "q"))
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let it = NSMenuItem(title: title, action: action, keyEquivalent: key)
        it.target = self
        return it
    }

    private func info(_ title: String) -> NSMenuItem {
        let it = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        it.isEnabled = false
        return it
    }

    private func submenu(_ title: String, _ sub: NSMenu) -> NSMenuItem {
        let it = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        it.submenu = sub
        return it
    }

    @objc private func presentNow() { controller.present() }
    @objc private func openSettings() { SettingsWindow.shared.show(controller: controller) }

    @objc private func pause(_ sender: NSMenuItem) {
        switch sender.tag {
        case 0:
            settings.pausedUntil = nil
        case -1:
            let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
            settings.pausedUntil = Calendar.current.date(byAdding: .hour, value: settings.startHour, to: tomorrow)
        default:
            settings.pausedUntil = Date().addingTimeInterval(Double(sender.tag) * 60)
        }
        scheduler.reschedule()
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
