import AppKit
import SwiftUI

/// A borderless, transparent, always-on-top panel: only Hopla and its bubble are visible.
final class PetPanel: NSPanel {
    init(content: NSView) {
        super.init(contentRect: NSRect(origin: .zero, size: PetView.size),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        contentView = content
    }

    // Never takes keyboard focus: you keep typing in your app. Buttons still react (see FirstClickHostingView).
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func placeBottomRight() {
        guard let screen = NSScreen.main else { return }
        let area = screen.visibleFrame
        setFrameOrigin(NSPoint(x: area.maxX - frame.width - 8, y: area.minY + 4))
    }
}

/// Buttons react to the very first click, even though the panel never activates the app.
final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
