import CoreGraphics
import Foundation

/// True under `--selftest` and unit tests: storage is then isolated from your real settings, stats and avatars.
let isTestRun: Bool = {
    let args = CommandLine.arguments
    return args.contains("--selftest") || args.contains("--testing-library")
        || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        || ProcessInfo.processInfo.environment["HOPLA_TEST"] != nil
}()

let hoplaDefaults: UserDefaults = {
    if isTestRun {
        let suite = "hopla.tests"
        UserDefaults().removePersistentDomain(forName: suite)
        return UserDefaults(suiteName: suite)!
    }
    migrateFromOldBundleID()
    return .standard
}()

/// Version 0.1 used the identifier "dev.hopla.app": carry its settings and stats over once.
private func migrateFromOldBundleID() {
    let standard = UserDefaults.standard
    guard !standard.bool(forKey: "migrated.fromDevHopla"),
          let old = standard.persistentDomain(forName: "dev.hopla.app") else { return }
    for (key, value) in old where standard.object(forKey: key) == nil { standard.set(value, forKey: key) }
    standard.set(true, forKey: "migrated.fromDevHopla")
}

enum RouteVariation: String, CaseIterable, Identifiable {
    case perVisit, daily, weekly, monthly, never
    var id: String { rawValue }
}

enum PetSize: String, CaseIterable, Identifiable {
    case small, medium, large
    var id: String { rawValue }
    var scale: CGFloat { self == .small ? 0.8 : self == .large ? 1.25 : 1 }
}

enum Corner: String, CaseIterable, Identifiable {
    case bottomRight, bottomLeft, topRight, topLeft, custom
    var id: String { rawValue }
}

enum ScreenChoice: String, CaseIterable, Identifiable {
    case main, mouse
    var id: String { rawValue }
}

/// All preferences, persisted as soon as they change. Defaults are the recommended values.
final class Settings: ObservableObject {
    static let shared = Settings()
    private let d = hoplaDefaults

    // Rhythm
    @Published var intervalMinutes: Int { didSet { d.set(intervalMinutes, forKey: "intervalMinutes") } }
    @Published var startHour: Int { didSet { d.set(startHour, forKey: "startHour") } }
    @Published var endHour: Int { didSet { d.set(endHour, forKey: "endHour") } }
    /// Calendar weekdays (1 = Sunday … 7 = Saturday).
    @Published var activeDays: Set<Int> { didSet { d.set(Array(activeDays), forKey: "activeDays") } }
    @Published var pausedUntil: Date? { didSet { d.set(pausedUntil, forKey: "pausedUntil") } }
    @Published var snoozeMinutes: Int { didSet { d.set(snoozeMinutes, forKey: "snoozeMinutes") } }
    @Published var quietDuringCalls: Bool { didSet { d.set(quietDuringCalls, forKey: "quietDuringCalls") } }

    // Session
    @Published var sessionSeconds: Int { didSet { d.set(sessionSeconds, forKey: "sessionSeconds") } }
    @Published var variation: RouteVariation { didSet { d.set(variation.rawValue, forKey: "variation") } }
    @Published var pinnedRoute: Int { didSet { d.set(pinnedRoute, forKey: "pinnedRoute") } }
    @Published var seatedOnly: Bool { didSet { d.set(seatedOnly, forKey: "seatedOnly") } }
    @Published var excludedExercises: Set<String> { didSet { d.set(Array(excludedExercises), forKey: "excludedExercises") } }
    @Published var dailyGoal: Int { didSet { d.set(dailyGoal, forKey: "dailyGoal") } }

    // Look & feel
    @Published var avatarID: String { didSet { d.set(avatarID, forKey: "avatarID") } }
    @Published var size: PetSize { didSet { d.set(size.rawValue, forKey: "size") } }
    @Published var corner: Corner { didSet { d.set(corner.rawValue, forKey: "corner") } }
    /// Position chosen by dragging Hopla, as a fraction of the screen's visible frame.
    @Published var customPosition: CGPoint? {
        didSet { d.set(customPosition.map { [$0.x, $0.y] }, forKey: "customPosition") }
    }
    @Published var screen: ScreenChoice { didSet { d.set(screen.rawValue, forKey: "screen") } }
    @Published var soundsEnabled: Bool { didSet { d.set(soundsEnabled, forKey: "soundsEnabled") } }
    @Published var volume: Double { didSet { d.set(volume, forKey: "volume") } }
    @Published var language: AppLanguage { didSet { d.set(language.rawValue, forKey: "language") } }
    @Published var hotkeysEnabled: Bool { didSet { d.set(hotkeysEnabled, forKey: "hotkeysEnabled") } }

    /// Exercises last a few seconds instead of 15–20 s (`--fast`), handy while developing.
    let fastMode = CommandLine.arguments.contains("--fast")

    private init() {
        let d = hoplaDefaults
        func int(_ key: String, _ fallback: Int) -> Int { d.object(forKey: key) as? Int ?? fallback }
        func bool(_ key: String, _ fallback: Bool) -> Bool { d.object(forKey: key) as? Bool ?? fallback }
        intervalMinutes = min(max(int("intervalMinutes", 60), 5), 24 * 60)
        startHour = min(max(int("startHour", 9), 0), 23)
        endHour = min(max(int("endHour", 18), 1), 24)
        activeDays = Set(d.array(forKey: "activeDays") as? [Int] ?? [2, 3, 4, 5, 6])
        pausedUntil = d.object(forKey: "pausedUntil") as? Date
        snoozeMinutes = min(max(int("snoozeMinutes", 15), 1), 240)
        quietDuringCalls = bool("quietDuringCalls", true)
        sessionSeconds = int("sessionSeconds", 60)
        variation = RouteVariation(rawValue: d.string(forKey: "variation") ?? "") ?? .perVisit
        pinnedRoute = min(max(int("pinnedRoute", 0), 0), 9)
        seatedOnly = bool("seatedOnly", false)
        excludedExercises = Set(d.array(forKey: "excludedExercises") as? [String] ?? [])
        dailyGoal = min(max(int("dailyGoal", 6), 1), 50)
        avatarID = d.string(forKey: "avatarID") ?? "hopla"
        size = PetSize(rawValue: d.string(forKey: "size") ?? "") ?? .medium
        corner = Corner(rawValue: d.string(forKey: "corner") ?? "") ?? .bottomRight
        customPosition = (d.array(forKey: "customPosition") as? [Double]).flatMap { $0.count == 2 ? CGPoint(x: $0[0], y: $0[1]) : nil }
        screen = ScreenChoice(rawValue: d.string(forKey: "screen") ?? "") ?? .main
        soundsEnabled = bool("soundsEnabled", true)
        volume = min(max(d.object(forKey: "volume") as? Double ?? 0.6, 0), 1)
        language = AppLanguage(rawValue: d.string(forKey: "language") ?? "") ?? .system
        hotkeysEnabled = bool("hotkeysEnabled", true)
    }

    var resolvedLanguage: AppLanguage {
        guard language == .system else { return language }
        return (Locale.preferredLanguages.first ?? "fr").hasPrefix("fr") ? .fr : .en
    }

    func isActiveTime(_ date: Date) -> Bool {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        // End before start means the range wraps past midnight (e.g. 22 h → 6 h).
        let inHours = startHour < endHour ? (hour >= startHour && hour < endHour) : (hour >= startHour || hour < endHour)
        return activeDays.contains(cal.component(.weekday, from: date)) && inHours
    }
}

final class Stats {
    static let shared = Stats()
    private let d = hoplaDefaults

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(_ date: Date) -> String { dayFormatter.string(from: date) }

    /// Completed sessions per day ("yyyy-MM-dd" → count).
    var history: [String: Int] { d.dictionary(forKey: "stats.history") as? [String: Int] ?? [:] }

    func sessions(on date: Date) -> Int { history[Stats.dayKey(date)] ?? 0 }
    var sessionsToday: Int { sessions(on: Date()) }

    /// Consecutive days with at least one session, ending today (or yesterday if today is still empty).
    var streak: Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        if sessions(on: day) == 0 { day = cal.date(byAdding: .day, value: -1, to: day)! }
        var count = 0
        while sessions(on: day) > 0 {
            count += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    var total: Int { history.values.reduce(0, +) }

    func recordSession() {
        var h = history
        h[Stats.dayKey(Date()), default: 0] += 1
        d.set(h, forKey: "stats.history")
    }
}
