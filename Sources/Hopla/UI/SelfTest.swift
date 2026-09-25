import AppKit
import SwiftUI

/// `Hopla --selftest <dir>`: drives the real panel through a full visit (arrive → Go → exercises →
/// celebrate → disappear), snapshots each step and checks the panel really is window-less.
@MainActor
enum SelfTest {
    /// `Hopla --snapshot-settings <dir>`: renders each settings tab in an off-screen window.
    static func snapshotSettings(controller: PetController, outputDirectory: String) {
        let dir = URL(fileURLWithPath: outputDirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        Task { @MainActor in
            for tab in 0..<SettingsView.tabCount {
                let host = NSHostingView(rootView: SettingsView(controller: controller, tab: tab).background(Color(nsColor: .windowBackgroundColor)))
                host.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
                let window = OffscreenWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
                window.contentView = host
                window.setFrameOrigin(NSPoint(x: -20_000, y: -20_000))
                window.orderFrontRegardless()
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                if let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
                    host.cacheDisplay(in: host.bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?.write(to: dir.appendingPathComponent("reglages-\(tab).png"))
                }
                window.orderOut(nil)
            }
            print("→ \(dir.path)")
            exit(0)
        }
    }

    static func run(panel: PetPanel, controller: PetController, outputDirectory: String) {
        let dir = URL(fileURLWithPath: outputDirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var failures: [String] = []
        func check(_ ok: Bool, _ what: String) {
            print(ok ? "✓ \(what)" : "✗ \(what)")
            if !ok { failures.append(what) }
        }
        func snapshot(_ name: String) {
            guard let view = panel.contentView, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
            view.cacheDisplay(in: view.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: dir.appendingPathComponent("\(name).png"))
        }
        func wait(_ seconds: Double) async { try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000)) }

        Task { @MainActor in
            check(!panel.isOpaque && panel.backgroundColor == .clear && !panel.hasShadow, "panneau transparent, sans ombre")
            check(panel.styleMask.contains(.borderless), "aucune bordure ni barre de titre")
            controller.present()
            check(panel.isVisible, "Hopla apparaît")
            await wait(1.5)
            check(controller.phase == .asking, "il propose Go / Snooze")
            snapshot("1-arrivee")
            // Click the Go button like a user would, in a panel that never becomes key.
            let point = NSPoint(x: 60, y: 200)
            for y in stride(from: 180.0, through: 235, by: 5) where controller.phase == .asking {
                for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                    if let event = NSEvent.mouseEvent(with: type, location: NSPoint(x: point.x, y: y), modifierFlags: [],
                                                      timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: panel.windowNumber,
                                                      context: nil, eventNumber: 0, clickCount: 1, pressure: 1) {
                        panel.sendEvent(event)
                    }
                }
                await wait(0.15)
            }
            check(controller.phase == .exercising(0), "un clic sur Go lance la séance")
            check(!panel.isKeyWindow, "la bulle ne vole pas le clavier")
            if controller.phase == .asking { controller.go() }
            await wait(0.6)
            snapshot("2-exercice")
            let hasPostureChange = zip(controller.session, controller.session.dropFirst()).contains { $0.exercise.posture != $1.exercise.posture }
            var sawPostureChange = false
            for _ in 0..<(controller.session.count * 2 + 2) {
                if case .changingPosture = controller.phase { sawPostureChange = true }
                guard controller.phase != .celebrating else { break }
                controller.skip()
                await wait(0.3)
            }
            check(sawPostureChange == hasPostureChange, "pause pour se lever ou se rassoir entre assis et debout")
            check(controller.phase == .celebrating, "fin de séance : bravo")
            snapshot("3-bravo")
            await wait(4.2)
            check(controller.phase == .hidden && !panel.isVisible, "Hopla disparaît après les étirements")

            controller.present()
            await wait(1.5)
            controller.showSnoozeOptions = true
            await wait(0.4)
            snapshot("4-snooze")
            controller.snooze(minutes: 15)
            await wait(2.6)
            check(controller.phase == .hidden && !panel.isVisible, "Snooze le fait partir")

            // Calling Hopla while it is leaving brings it straight back.
            controller.present()
            await wait(1.5)
            controller.snooze(minutes: 15)
            await wait(0.3)
            controller.callOrGo()
            await wait(3.2)
            check(controller.phase != .hidden && panel.isVisible, "raccourci pendant le départ : Hopla revient")
            controller.snooze(minutes: 15)
            await wait(2.6)

            // An explicit "Later" comes back even outside active hours; a regular visit does not.
            let settings = Settings.shared
            let savedDays = settings.activeDays
            settings.activeDays = []
            var visits = 0
            let scheduler = Scheduler(onDue: { visits += 1 }, isBusy: { false })
            scheduler.idleSeconds = { 0 }
            if Presence.shouldStayQuiet() {
                print("· planning non testé : appel ou partage d'écran en cours")
            } else {
                scheduler.snooze(until: Date().addingTimeInterval(-1))
                scheduler.tick()
                check(visits == 1, "« plus tard » respecté hors des horaires")
                scheduler.schedule(at: Date().addingTimeInterval(-1))
                scheduler.tick()
                check(visits == 1, "pas de visite normale hors des horaires")
            }
            settings.activeDays = savedDays

            // A shared avatar file can't escape the avatars folder.
            check(AvatarLibrary.safeID("../../Library/LaunchAgents/evil") == "librarylaunchagentsevil", "identifiant d'avatar nettoyé")
            let folder = AvatarLibrary.userFolder
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let trap = folder.appendingPathComponent("piege.json")
            let json = ##"{"id": "../../piege", "name": "Piège", "palette": {"body": "#000", "belly": "#000", "limbs": "#000", "outline": "#000", "cheeks": "#000", "eyes": "#000", "accent": "#000"}, "extras": ["horns", "horns", "horns"]}"##
            try? json.data(using: .utf8)?.write(to: trap)
            AvatarLibrary.invalidate()
            let loaded = AvatarLibrary.all().first { $0.name == "Piège" }
            check(loaded?.id == "piege" && loaded?.extras == [.horns], "avatar partagé chargé proprement")
            if let loaded { AvatarLibrary.delete(loaded) }
            check(!FileManager.default.fileExists(atPath: trap.path), "suppression limitée au dossier des avatars")

            check(CGColor.parse("#FFF")?.rgba == [1, 1, 1, 1] && CGColor.parse("#12345") == nil, "couleurs courtes et invalides")

            print(failures.isEmpty ? "Tout est OK" : "\(failures.count) échec(s)")
            exit(failures.isEmpty ? 0 : 1)
        }
    }
}

/// A window that may live outside every screen (for snapshots).
private final class OffscreenWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}
