import AppKit

let arguments = CommandLine.arguments

MainActor.assumeIsolated {
    if let i = arguments.firstIndex(of: "--icon") {
        AppIcon.writeIconset(to: i + 1 < arguments.count ? arguments[i + 1] : "AppIcon.iconset")
        exit(0)
    }
    if let i = arguments.firstIndex(of: "--render") {
        Renderer.run(outputDirectory: i + 1 < arguments.count ? arguments[i + 1] : "renders")
        exit(0)
    }

    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory) // menu bar app: no Dock icon
    app.run()
}
