import AppKit
import Carbon
import CoreAudio
import CoreMediaIO
import Darwin
import ServiceManagement

/// Detects moments when Hopla should not pop up: calls (camera or microphone in use) and screen sharing.
enum Presence {
    static func shouldStayQuiet() -> Bool {
        guard Settings.shared.quietDuringCalls else { return false }
        return isCameraInUse() || isMicrophoneInUse() || isScreenShared()
    }

    /// True while another app records from a microphone (calls, dictation…).
    static func isMicrophoneInUse() -> Bool {
        if #available(macOS 14.2, *), let recording = otherProcessIsRecording() { return recording }
        return defaultInputDeviceIsRunning()
    }

    /// Per-process check (macOS 14.2+): ignores Hopla itself, and playing audio never counts as recording.
    @available(macOS 14.2, *)
    private static func otherProcessIsRecording() -> Bool? {
        let system = AudioObjectID(kAudioObjectSystemObject)
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyProcessObjectList,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return nil }
        var processes = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard !processes.isEmpty, AudioObjectGetPropertyData(system, &address, 0, nil, &size, &processes) == noErr else { return nil }
        let me = getpid()
        for process in processes {
            var pid: pid_t = 0
            var pidSize = UInt32(MemoryLayout<pid_t>.size)
            var pidAddress = AudioObjectPropertyAddress(mSelector: kAudioProcessPropertyPID, mScope: kAudioObjectPropertyScopeGlobal,
                                                        mElement: kAudioObjectPropertyElementMain)
            guard AudioObjectGetPropertyData(process, &pidAddress, 0, nil, &pidSize, &pid) == noErr, pid != me,
                  isApp(pid) else { continue }
            var running: UInt32 = 0
            var runningSize = UInt32(MemoryLayout<UInt32>.size)
            var inputAddress = AudioObjectPropertyAddress(mSelector: kAudioProcessPropertyIsRunningInput, mScope: kAudioObjectPropertyScopeGlobal,
                                                          mElement: kAudioObjectPropertyElementMain)
            if AudioObjectGetPropertyData(process, &inputAddress, 0, nil, &runningSize, &running) == noErr, running != 0 { return true }
        }
        return false
    }

    /// Only apps count (FaceTime, Zoom, Teams, browsers and their helpers all live in a .app bundle).
    /// System services such as "Hey Siri" (corespeechd) listen to the microphone all the time and must be ignored.
    private static func isApp(_ pid: pid_t) -> Bool {
        var buffer = [CChar](repeating: 0, count: 4096)
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return false }
        return String(cString: buffer).contains(".app/")
    }

    private static func defaultInputDeviceIsRunning() -> Bool {
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device) == noErr,
              device != 0 else { return false }
        var running: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        address.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &running) == noErr else { return false }
        return running != 0
    }

    static func isCameraInUse() -> Bool {
        var address = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
                                                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                                                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        var dataSize: UInt32 = 0
        let system = CMIOObjectID(kCMIOObjectSystemObject)
        guard CMIOObjectGetPropertyDataSize(system, &address, 0, nil, &dataSize) == noErr, dataSize > 0 else { return false }
        var devices = [CMIOObjectID](repeating: 0, count: Int(dataSize) / MemoryLayout<CMIOObjectID>.size)
        var used: UInt32 = 0
        guard CMIOObjectGetPropertyData(system, &address, 0, nil, dataSize, &used, &devices) == noErr else { return false }
        for device in devices {
            var running: UInt32 = 0
            var got: UInt32 = 0
            var a = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
                                              mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
                                              mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard))
            if CMIOObjectGetPropertyData(device, &a, 0, nil, UInt32(MemoryLayout<UInt32>.size), &got, &running) == noErr, running != 0 {
                return true
            }
        }
        return false
    }

    /// True while the screen is being shared or recorded. macOS has no public API for this, so we look up the
    /// window server's own check at runtime; if it ever disappears, Hopla simply assumes the screen isn't shared.
    static func isScreenShared() -> Bool { screenWatcherCheck?() ?? false }

    private typealias WatcherCheck = @convention(c) () -> Bool
    private static let screenWatcherCheck: WatcherCheck? = {
        let handle = UnsafeMutableRawPointer(bitPattern: -2) // RTLD_DEFAULT
        for name in ["SLSIsScreenWatcherPresent", "CGSIsScreenWatcherPresent"] {
            if let symbol = dlsym(handle, name) { return unsafeBitCast(symbol, to: WatcherCheck.self) }
        }
        return nil
    }()
}

/// System-wide shortcuts that work from any app, without accessibility permissions.
final class HotKeys {
    static let shared = HotKeys()
    private var refs: [EventHotKeyRef] = []
    private var actions: [UInt32: () -> Void] = [:]
    private var handlerInstalled = false

    /// Shortcuts macOS refused, usually because another app already uses them.
    private(set) var unavailable: [String] = []

    static let goKeyLabel = "⌃⌥H"
    static let laterKeyLabel = "⌃⌥S"

    func install(go: @escaping () -> Void, later: @escaping () -> Void) {
        uninstall()
        installHandlerIfNeeded()
        let modifiers = UInt32(controlKey | optionKey)
        register(id: 1, keyCode: UInt32(kVK_ANSI_H), modifiers: modifiers, action: go)
        register(id: 2, keyCode: UInt32(kVK_ANSI_S), modifiers: modifiers, action: later)
    }

    func uninstall() {
        refs.forEach { UnregisterEventHotKey($0) }
        refs = []
        actions = [:]
        unavailable = []
    }

    private func register(id: UInt32, keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x48504C41), id: id) // "HPLA"
        if RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref) == noErr, let ref {
            refs.append(ref)
            actions[id] = action
        } else {
            unavailable.append(id == 1 ? HotKeys.goKeyLabel : HotKeys.laterKeyLabel)
            NSLog("Hopla: raccourci indisponible (déjà utilisé ?) : \(id)")
        }
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            let id = hotKeyID.id
            DispatchQueue.main.async { HotKeys.shared.actions[id]?() }
            return noErr
        }, 1, &spec, nil, nil)
    }
}

enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
    static var needsApproval: Bool { SMAppService.mainApp.status == .requiresApproval }

    static func set(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Hopla: lancement au démarrage impossible (\(error.localizedDescription))")
        }
    }
}
