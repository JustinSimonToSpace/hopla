import AppKit
import SwiftUI

@MainActor
final class SettingsWindow {
    static let shared = SettingsWindow()
    private var window: NSWindow?

    func show(controller: PetController) {
        if window == nil {
            let host = NSHostingController(rootView: SettingsView(controller: controller))
            let w = NSWindow(contentViewController: host)
            w.styleMask = [.titled, .closable, .miniaturizable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        window?.title = tr("Réglages de Hopla", "Hopla Settings")
        AvatarLibrary.invalidate()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}

struct SettingsView: View {
    let controller: PetController
    @ObservedObject private var settings = Settings.shared
    @State private var tab: Int

    init(controller: PetController, tab: Int = 0) {
        self.controller = controller
        _tab = State(initialValue: tab)
    }

    static let tabCount = 6

    var body: some View {
        TabView(selection: $tab) {
            AvatarTab().tabItem { Label(tr("Avatar", "Avatar"), systemImage: "face.smiling") }.tag(0)
            SessionTab().tabItem { Label(tr("Séance", "Session"), systemImage: "timer") }.tag(1)
            ExercisesTab().tabItem { Label(tr("Exercices", "Exercises"), systemImage: "figure.cooldown") }.tag(2)
            RhythmTab().tabItem { Label(tr("Rythme", "Rhythm"), systemImage: "calendar.badge.clock") }.tag(3)
            ProgressTab().tabItem { Label(tr("Progrès", "Progress"), systemImage: "flame") }.tag(4)
            GeneralTab(controller: controller).tabItem { Label(tr("Général", "General"), systemImage: "gearshape") }.tag(5)
        }
        .padding(12)
        .frame(width: 800, height: 600)
    }
}

// MARK: - Shared pieces

/// An avatar playing a clip, at a modest frame rate so many previews can run at once.
struct AnimatedCharacter: View {
    let avatar: Avatar
    let clip: Clip
    var fps: Double = 30

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1 / fps)) { context in
            let date = avatar.style.spec.quantize(context.date)
            let t = date.timeIntervalSinceReferenceDate
            CharacterView(pose: clip.sample(t), avatar: avatar, blink: Blink.isBlinking(date), time: t)
        }
    }
}

private var currentAvatar: Avatar { AvatarLibrary.current() }

// MARK: - Avatar

private struct AvatarTab: View {
    @ObservedObject private var settings = Settings.shared
    @State private var avatars = AvatarLibrary.all()
    @State private var editing: Avatar?
    @State private var confirmingDelete = false

    private var current: Avatar { avatars.first { $0.id == settings.avatarID } ?? avatars[0] }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 10) {
                AnimatedCharacter(avatar: current, clip: Moves.wave)
                    .frame(width: 190, height: 190)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.primary.opacity(0.05)))
                Text(current.name).font(.hopla(18, .bold))
                Text(current.style.fullName).font(.hopla(12)).foregroundColor(.secondary).multilineTextAlignment(.center)
                Button(tr("Personnaliser…", "Customize…")) { editing = AvatarLibrary.draft(from: current) }
                if AvatarLibrary.isCustom(current) {
                    Button(tr("Supprimer cet avatar…", "Delete this avatar…"), role: .destructive) { confirmingDelete = true }
                        .confirmationDialog(tr("Mettre « \(current.name) » à la corbeille ?", "Move “\(current.name)” to the Trash?"),
                                            isPresented: $confirmingDelete) {
                            Button(tr("Mettre à la corbeille", "Move to Trash"), role: .destructive) {
                                AvatarLibrary.delete(current)
                                avatars = AvatarLibrary.all()
                                settings.avatarID = avatars[0].id
                            }
                        }
                }
                Spacer()
            }
            .frame(width: 220)
            .padding(.top, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(ArtStyle.allCases) { style in
                        let members = avatars.filter { $0.style == style }
                        if !members.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(style.localizedCollection).font(.hopla(15, .bold))
                                    Text(style.localizedStyle).font(.hopla(12)).foregroundColor(.secondary)
                                }
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                                    ForEach(members) { avatar in
                                        AvatarCard(avatar: avatar, selected: avatar.id == settings.avatarID)
                                            .onTapGesture { settings.avatarID = avatar.id }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(14)
            }
        }
        .onAppear { avatars = AvatarLibrary.all() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            AvatarLibrary.invalidate()
            avatars = AvatarLibrary.all()
        }
        .sheet(item: $editing) { draft in
            AvatarEditor(draft: draft, onSave: { saved in
                AvatarLibrary.save(saved)
                avatars = AvatarLibrary.all()
                settings.avatarID = saved.id
                editing = nil
            }, onCancel: { editing = nil })
        }
    }
}

private struct AvatarCard: View {
    let avatar: Avatar
    let selected: Bool
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 2) {
            Group {
                if hovering || selected {
                    AnimatedCharacter(avatar: avatar, clip: Moves.idle, fps: 24)
                } else {
                    CharacterView(pose: Moves.idle.sample(0), avatar: avatar)
                }
            }
            .frame(width: 84, height: 84)
            Text(avatar.name).font(.hopla(11, .semibold)).lineLimit(1)
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(selected ? Color.accentColor.opacity(0.14) : Color.primary.opacity(hovering ? 0.06 : 0.03)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color.accentColor : .clear, lineWidth: 2))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}

// MARK: - Session

private struct SessionTab: View {
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        let steps = RouteBook.session(route: RouteBook.currentIndex())
        Form {
            Section(tr("Durée d'une séance", "Session length")) {
                Picker("", selection: $settings.sessionSeconds) {
                    Text("30 s").tag(30); Text("45 s").tag(45); Text("1 min").tag(60); Text("2 min").tag(120)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Text(tr("\(steps.count) mouvements de \(Int(steps.first?.seconds ?? 15)) secondes",
                        "\(steps.count) moves of \(Int(steps.first?.seconds ?? 15)) seconds"))
                    .foregroundColor(.secondary)
            }
            Section(tr("Parcours", "Routes")) {
                Picker(tr("Changer de parcours", "Change route"), selection: $settings.variation) {
                    ForEach(RouteVariation.allCases) { Text($0.label).tag($0) }
                }
                if settings.variation == .never {
                    Picker(tr("Parcours", "Route"), selection: $settings.pinnedRoute) {
                        ForEach(0..<RouteBook.routesPerDuration, id: \.self) { Text(tr("Parcours n° \($0 + 1)", "Route #\($0 + 1)")).tag($0) }
                    }
                }
                Text(tr("10 parcours pré-enregistrés par durée. « À chaque passage » : jamais deux fois le même dans la journée tant que tu n'as pas fait tous les autres.",
                        "10 pre-recorded routes per length. “Every visit”: never the same one twice in a day until you've done all the others."))
                    .font(.hopla(12)).foregroundColor(.secondary)
            }
            Section(tr("Postures", "Postures")) {
                Toggle(tr("Assis uniquement (aucun exercice debout)", "Seated only (no standing exercises)"), isOn: $settings.seatedOnly)
            }
            Section(tr("Prochain parcours", "Next route")) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                    let previous: Posture = i == 0 ? .seated : steps[i - 1].exercise.posture
                    if step.exercise.posture != previous {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down").foregroundColor(.secondary)
                            Text(step.exercise.posture == .standing ? tr("On se lève", "Stand up") : tr("On se rassoit", "Sit back down"))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(PetController.postureChangeSeconds)) s").monospacedDigit().foregroundColor(.secondary)
                        }
                        .font(.hopla(12))
                    }
                    HStack {
                        Text("\(i + 1).").monospacedDigit().foregroundColor(.secondary)
                        Text(step.exercise.title)
                        Spacer()
                        Image(systemName: step.exercise.posture == .standing ? "figure.stand" : "chair")
                            .foregroundColor(.secondary)
                        Text("\(Int(step.seconds)) s").monospacedDigit().foregroundColor(.secondary)
                    }
                }
            }
            Section(tr("Plus tard", "Later")) {
                Picker(tr("« Plus tard » par défaut", "Default “Later”"), selection: $settings.snoozeMinutes) {
                    ForEach([5, 10, 15, 30, 60], id: \.self) { Text($0 < 60 ? "\($0) min" : "1 h").tag($0) }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Exercises

private struct ExercisesTab: View {
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        let avatar = currentAvatar
        VStack(alignment: .leading, spacing: 8) {
            Text(tr("Décoche les exercices que tu ne veux pas faire : ils seront remplacés automatiquement par un exercice proche.",
                    "Uncheck the exercises you don't want to do: they'll be replaced by a similar one."))
                .font(.hopla(13)).foregroundColor(.secondary)
            Label(tr("Des mouvements doux, pas un avis médical : va à ton rythme et arrête si tu as mal.",
                     "Gentle moves, not medical advice: go at your own pace and stop if anything hurts."),
                  systemImage: "heart")
                .font(.hopla(12)).foregroundColor(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    group(tr("Assis", "Seated"), Exercise.all.filter { $0.posture == .seated }, avatar: avatar)
                    group(tr("Debout", "Standing"), Exercise.all.filter { $0.posture == .standing }, avatar: avatar)
                        .opacity(settings.seatedOnly ? 0.4 : 1)
                        .overlay(alignment: .topTrailing) {
                            if settings.seatedOnly {
                                Text(tr("Désactivés : mode assis uniquement", "Off: seated-only mode")).font(.hopla(12, .semibold)).foregroundColor(.orange)
                            }
                        }
                }
                .padding(.vertical, 4)
            }
            HStack {
                Button(tr("Tout cocher", "Select all")) { settings.excludedExercises = [] }
                Spacer()
                let active = Exercise.all.filter(RouteBook.isAllowed).count
                Text(tr("\(active) exercices actifs", "\(active) active exercises")).foregroundColor(.secondary)
            }
        }
        .padding(8)
    }

    private func group(_ title: String, _ exercises: [Exercise], avatar: Avatar) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.hopla(15, .bold))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 10)], spacing: 10) {
                ForEach(exercises) { exercise in
                    ExerciseCard(exercise: exercise, avatar: avatar)
                }
            }
        }
    }
}

private struct ExerciseCard: View {
    let exercise: Exercise
    let avatar: Avatar
    @ObservedObject private var settings = Settings.shared

    private var enabled: Binding<Bool> {
        Binding(get: { !settings.excludedExercises.contains(exercise.id) }, set: { on in
            if on {
                settings.excludedExercises.remove(exercise.id)
            } else if Exercise.all.filter(RouteBook.isAllowed).count > 1 {
                settings.excludedExercises.insert(exercise.id)
            }
        })
    }

    var body: some View {
        HStack(spacing: 6) {
            AnimatedCharacter(avatar: avatar, clip: exercise.clip, fps: 15)
                .frame(width: 70, height: 70)
                .opacity(enabled.wrappedValue ? 1 : 0.35)
            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: enabled) { Text(exercise.title).font(.hopla(12.5, .semibold)) }
                    .toggleStyle(.checkbox)
                Text(exercise.instruction).font(.hopla(10.5)).foregroundColor(.secondary).lineLimit(3)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.04)))
        .contentShape(Rectangle())
        .onTapGesture { enabled.wrappedValue.toggle() }
    }
}

// MARK: - Rhythm

private struct RhythmTab: View {
    @ObservedObject private var settings = Settings.shared

    private var weekdays: [(Int, String)] {
        let letters = settings.resolvedLanguage == .en ? ["M", "T", "W", "T", "F", "S", "S"] : ["L", "M", "M", "J", "V", "S", "D"]
        return zip([2, 3, 4, 5, 6, 7, 1], letters).map { ($0, $1) }
    }

    var body: some View {
        Form {
            Section(tr("Fréquence", "Frequency")) {
                Picker(tr("Hopla passe", "Hopla visits"), selection: $settings.intervalMinutes) {
                    ForEach([30, 45, 60, 90, 120], id: \.self) { m in
                        Text(m < 60 ? tr("toutes les \(m) min", "every \(m) min")
                                    : m == 90 ? tr("toutes les 1 h 30", "every 1 h 30") : tr("toutes les \(m / 60) h", "every \(m / 60) h")).tag(m)
                    }
                }
            }
            Section(tr("Horaires", "Hours")) {
                Picker(tr("À partir de", "From"), selection: $settings.startHour) {
                    ForEach(0..<24, id: \.self) { Text("\($0) h").tag($0) }
                }
                Picker(tr("Jusqu'à", "Until"), selection: $settings.endHour) {
                    ForEach(1...24, id: \.self) { Text("\($0) h").tag($0) }
                }
                HStack(spacing: 6) {
                    Text(tr("Jours", "Days"))
                    Spacer()
                    ForEach(weekdays, id: \.0) { day, letter in
                        let on = settings.activeDays.contains(day)
                        Button(letter) {
                            if on { settings.activeDays.remove(day) } else { settings.activeDays.insert(day) }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(on ? Color.accentColor : Color.primary.opacity(0.08)))
                        .foregroundColor(on ? .white : .primary)
                    }
                }
            }
            Section(tr("Ne pas déranger", "Do not disturb")) {
                Toggle(tr("Pendant les appels et les partages d'écran", "During calls and screen sharing"), isOn: $settings.quietDuringCalls)
                Text(tr("Caméra ou micro utilisés par une autre app, ou écran partagé : Hopla attend la fin pour passer.",
                        "Camera or microphone used by another app, or screen shared: Hopla waits until it's over."))
                    .font(.hopla(12)).foregroundColor(.secondary)
                Text(tr("Si tu t'éloignes du Mac plus de 5 minutes, ça compte comme une pause : Hopla repart de zéro.",
                        "If you're away from your Mac for more than 5 minutes, it counts as a break: Hopla starts over."))
                    .font(.hopla(12)).foregroundColor(.secondary)
            }
            Section(tr("Pause", "Pause")) {
                if let until = settings.pausedUntil, until > Date() {
                    Text(tr("En pause jusqu'à \(until.formatted(date: .omitted, time: .shortened))",
                            "Paused until \(until.formatted(date: .omitted, time: .shortened))"))
                }
                HStack {
                    Button(tr("1 heure", "1 hour")) { settings.pausedUntil = Date().addingTimeInterval(3600) }
                    Button(tr("2 heures", "2 hours")) { settings.pausedUntil = Date().addingTimeInterval(7200) }
                    Button(tr("Jusqu'à demain", "Until tomorrow")) {
                        let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
                        settings.pausedUntil = Calendar.current.date(byAdding: .hour, value: settings.startHour, to: tomorrow)
                    }
                    if settings.pausedUntil.map({ $0 > Date() }) == true {
                        Button(tr("Reprendre", "Resume")) { settings.pausedUntil = nil }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Progress

private struct ProgressTab: View {
    @ObservedObject private var settings = Settings.shared
    /// Bumped each time the tab appears, so fresh stats are read.
    @State private var appearances = 0

    var body: some View {
        let _ = appearances
        let stats = Stats.shared
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                tile(tr("Aujourd'hui", "Today"), "\(stats.sessionsToday) / \(settings.dailyGoal)")
                tile(tr("Série", "Streak"), tr("\(stats.streak) j", "\(stats.streak) d"))
                tile(tr("Au total", "Total"), "\(stats.total)")
            }
            Stepper(tr("Objectif : \(settings.dailyGoal) pauses par jour", "Goal: \(settings.dailyGoal) breaks a day"),
                    value: $settings.dailyGoal, in: 1...15)
            Text(tr("Tes 18 dernières semaines", "Your last 18 weeks")).font(.hopla(15, .bold))
            CalendarHeatmap(goal: settings.dailyGoal, history: stats.history, language: settings.resolvedLanguage)
            Spacer()
        }
        .padding(20)
        .onAppear { appearances += 1 }
    }

    private func tile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.hopla(12)).foregroundColor(.secondary)
            Text(value).font(.hopla(26, .bold))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.05)))
    }
}

private struct CalendarHeatmap: View {
    let goal: Int
    let history: [String: Int]
    let language: AppLanguage
    private let weeks = 18

    var body: some View {
        let cal = Calendar(identifier: .iso8601)
        let today = cal.startOfDay(for: Date())
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let first = cal.date(byAdding: .weekOfYear, value: -(weeks - 1), to: weekStart)!
        let rowLabels = language == .en ? ["Mon", "", "Wed", "", "Fri", "", ""] : ["Lun", "", "Mer", "", "Ven", "", ""]
        HStack(alignment: .top, spacing: 4) {
            VStack(alignment: .trailing, spacing: 4) {
                ForEach(0..<7, id: \.self) { Text(rowLabels[$0]).font(.hopla(10)).foregroundColor(.secondary).frame(height: 16) }
            }
            ForEach(0..<weeks, id: \.self) { w in
                VStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { d in
                        cell(cal.date(byAdding: .day, value: w * 7 + d, to: first)!, today: today)
                    }
                }
            }
        }
    }
}

extension CalendarHeatmap {
    private func fill(count: Int, future: Bool) -> Color {
        if future { return .clear }
        if count == 0 { return Color.primary.opacity(0.08) }
        let strength = min(1, 0.3 + 0.7 * Double(count) / Double(max(goal, 1)))
        return Color(hex: "#34A86A").opacity(strength)
    }

    fileprivate func cell(_ day: Date, today: Date) -> some View {
        let count = history[Stats.dayKey(day)] ?? 0
        let border: Color = day == today ? Color.primary.opacity(0.6) : .clear
        return RoundedRectangle(cornerRadius: 4)
            .fill(fill(count: count, future: day > today))
            .frame(width: 16, height: 16)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(border, lineWidth: 1.5))
            .help("\(day.formatted(date: .abbreviated, time: .omitted)) : \(count)")
    }
}

// MARK: - General

private struct GeneralTab: View {
    let controller: PetController
    @ObservedObject private var settings = Settings.shared
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            Section(tr("Langue", "Language")) {
                Picker(tr("Langue de Hopla", "Hopla's language"), selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { Text($0.label).tag($0) }
                }
            }
            Section(tr("Sons", "Sounds")) {
                Toggle(tr("Sons de l'avatar", "Avatar sounds"), isOn: $settings.soundsEnabled)
                HStack {
                    Image(systemName: "speaker.fill").foregroundColor(.secondary)
                    Slider(value: $settings.volume, in: 0...1)
                    Image(systemName: "speaker.wave.3.fill").foregroundColor(.secondary)
                    Button(tr("Écouter", "Listen")) { Sound.play(.celebrate, for: currentAvatar, force: true) }
                }
                .disabled(!settings.soundsEnabled)
                Text(tr("Chaque collection a sa propre voix, et chaque avatar sa propre hauteur.",
                        "Each collection has its own voice, and each avatar its own pitch."))
                    .font(.hopla(12)).foregroundColor(.secondary)
            }
            Section(tr("Apparence", "Appearance")) {
                Picker(tr("Taille", "Size"), selection: $settings.size) {
                    ForEach(PetSize.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker(tr("Position", "Position"), selection: $settings.corner) {
                    ForEach(Corner.allCases.filter { $0 != .custom || settings.customPosition != nil }) { Text($0.label).tag($0) }
                }
                Picker(tr("Écran", "Screen"), selection: $settings.screen) {
                    ForEach(ScreenChoice.allCases) { Text($0.label).tag($0) }
                }
                Text(tr("Tu peux aussi déplacer Hopla à la souris : il reviendra au même endroit.",
                        "You can also drag Hopla around: it will come back to the same spot."))
                    .font(.hopla(12)).foregroundColor(.secondary)
            }
            Section(tr("Démarrage", "Startup")) {
                Toggle(tr("Ouvrir Hopla au démarrage du Mac", "Open Hopla when the Mac starts"), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { wanted in
                        LoginItem.set(wanted)
                        if LoginItem.isEnabled != wanted { launchAtLogin = LoginItem.isEnabled }
                    }
                if launchAtLogin == false, LoginItem.needsApproval {
                    Text(tr("À autoriser dans Réglages Système › Général › Ouverture.", "Allow it in System Settings › General › Login Items."))
                        .font(.hopla(12)).foregroundColor(.orange)
                }
            }
            Section(tr("Raccourcis clavier", "Keyboard shortcuts")) {
                Toggle(tr("Activer les raccourcis", "Enable shortcuts"), isOn: $settings.hotkeysEnabled)
                LabeledContent(HotKeys.goKeyLabel, value: tr("Faire venir Hopla, puis Go", "Call Hopla, then Go"))
                LabeledContent(HotKeys.laterKeyLabel, value: tr("Plus tard, ou Stop pendant une séance", "Later, or Stop during a session"))
                if settings.hotkeysEnabled, !HotKeys.shared.unavailable.isEmpty {
                    Text(tr("Déjà utilisé par une autre app : \(HotKeys.shared.unavailable.joined(separator: ", "))",
                            "Already used by another app: \(HotKeys.shared.unavailable.joined(separator: ", "))"))
                        .font(.hopla(12)).foregroundColor(.orange)
                }
            }
            Section(tr("Avatars perso", "Custom avatars")) {
                Button(tr("Ouvrir le dossier des avatars…", "Open the avatars folder…")) { NSWorkspace.shared.open(AvatarLibrary.userFolder) }
                Button(tr("Faire venir Hopla maintenant", "Call Hopla now")) { controller.present() }
            }
        }
        .formStyle(.grouped)
    }
}
