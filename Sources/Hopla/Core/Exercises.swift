import Foundation

enum Posture { case seated, standing }
enum BodyZone { case neck, shoulders, arms, back, eyes, breath, legs, cardio }

struct Exercise: Identifiable {
    let id: String
    let titles: (fr: String, en: String)
    let instructions: (fr: String, en: String)
    let posture: Posture
    let zone: BodyZone
    let clip: Clip

    var title: String { tr(titles.fr, titles.en) }
    var instruction: String { tr(instructions.fr, instructions.en) }

    static let all: [Exercise] = [
        // Seated
        Exercise(id: "reach", titles: ("Grand étirement", "Big stretch"),
                 instructions: ("Tends les bras vers le ciel et grandis-toi au maximum.", "Reach for the sky and make yourself as tall as you can."),
                 posture: .seated, zone: .back, clip: Moves.reachUp),
        Exercise(id: "side", titles: ("Penché de côté", "Side bend"),
                 instructions: ("Bras en l'air, penche-toi doucement à gauche… puis à droite.", "Arms up, gently lean to the left… then to the right."),
                 posture: .seated, zone: .back, clip: Moves.sideBend),
        Exercise(id: "shrug", titles: ("Épaules", "Shoulder shrugs"),
                 instructions: ("Monte les épaules vers les oreilles, tiens… et relâche.", "Lift your shoulders to your ears, hold… and let go."),
                 posture: .seated, zone: .shoulders, clip: Moves.shrug),
        Exercise(id: "neck", titles: ("Nuque", "Neck"),
                 instructions: ("Penche doucement la tête d'un côté, puis de l'autre. Respire.", "Slowly tilt your head to one side, then the other. Breathe."),
                 posture: .seated, zone: .neck, clip: Moves.neck),
        Exercise(id: "circles", titles: ("Moulinets", "Arm circles"),
                 instructions: ("Fais de grands cercles avec les bras.", "Draw big circles with your arms."),
                 posture: .seated, zone: .shoulders, clip: Moves.armCircles),
        Exercise(id: "breathe", titles: ("Grande respiration", "Deep breath"),
                 instructions: ("Inspire en levant les bras, expire en les redescendant.", "Breathe in as your arms rise, breathe out as they come down."),
                 posture: .seated, zone: .breath, clip: Moves.breathe),
        Exercise(id: "crossArm", titles: ("Bras croisé", "Cross-arm stretch"),
                 instructions: ("Ramène un bras contre la poitrine avec l'autre main, puis change.", "Pull one arm across your chest with the other hand, then switch."),
                 posture: .seated, zone: .shoulders, clip: Moves.crossArm),
        Exercise(id: "triceps", titles: ("Triceps", "Triceps"),
                 instructions: ("Main dans le dos, tire doucement le coude avec l'autre main.", "Hand behind your head, gently pull the elbow with the other hand."),
                 posture: .seated, zone: .arms, clip: Moves.triceps),
        Exercise(id: "wrists", titles: ("Secoue les mains", "Shake your hands"),
                 instructions: ("Secoue les mains et les poignets pour les détendre.", "Shake out your hands and wrists to relax them."),
                 posture: .seated, zone: .arms, clip: Moves.wristShake),
        Exercise(id: "twist", titles: ("Torsion du buste", "Seated twist"),
                 instructions: ("Tourne le buste d'un côté, puis de l'autre, sans forcer.", "Turn your upper body to one side, then the other, gently."),
                 posture: .seated, zone: .back, clip: Moves.twist),
        Exercise(id: "eyes", titles: ("Repos des yeux", "Rest your eyes"),
                 instructions: ("Regarde au loin, par la fenêtre ou au fond de la pièce.", "Look far away, out of the window or across the room."),
                 posture: .seated, zone: .eyes, clip: Moves.farSight),
        // Standing
        Exercise(id: "march", titles: ("Marche sur place", "March in place"),
                 instructions: ("Debout ! Lève les genoux et balance les bras.", "Stand up! Lift your knees and swing your arms."),
                 posture: .standing, zone: .cardio, clip: Moves.march),
        Exercise(id: "squat", titles: ("Petits squats", "Mini squats"),
                 instructions: ("Debout, plie les genoux comme pour t'asseoir… et remonte.", "Standing, bend your knees as if to sit down… and come back up."),
                 posture: .standing, zone: .legs, clip: Moves.squat),
        Exercise(id: "calf", titles: ("Sur la pointe des pieds", "Calf raises"),
                 instructions: ("Monte sur la pointe des pieds, puis redescends doucement.", "Rise onto your toes, then lower down slowly."),
                 posture: .standing, zone: .legs, clip: Moves.calfRaise),
        Exercise(id: "knee", titles: ("Genou-poitrine", "Knee hugs"),
                 instructions: ("Ramène un genou vers la poitrine, puis l'autre.", "Bring one knee up to your chest, then the other."),
                 posture: .standing, zone: .legs, clip: Moves.kneeHug),
        Exercise(id: "hips", titles: ("Cercles de hanches", "Hip circles"),
                 instructions: ("Mains sur les hanches, dessine de grands cercles.", "Hands on your hips, draw big circles."),
                 posture: .standing, zone: .back, clip: Moves.hipCircles),
        Exercise(id: "jacks", titles: ("Sauts écartés doux", "Gentle jumping jacks"),
                 instructions: ("Écarte bras et jambes en rythme, sans forcer.", "Open arms and legs in rhythm, nice and easy."),
                 posture: .standing, zone: .cardio, clip: Moves.jumpingJacks),
        Exercise(id: "box", titles: ("Boxe dans le vide", "Shadow boxing"),
                 instructions: ("Garde haute, envoie des petits coups de poing.", "Guard up, throw light punches."),
                 posture: .standing, zone: .cardio, clip: Moves.shadowBoxing),
    ]

    static func find(_ id: String) -> Exercise? { all.first { $0.id == id } }
}

struct SessionStep {
    let exercise: Exercise
    let seconds: Double
}

/// Pre-recorded routes: 10 per duration. Each one warms up the upper body first and ends standing.
/// Excluded exercises (or standing ones in seated-only mode) are swapped for a close alternative.
enum RouteBook {
    static let durations = [30, 45, 60, 120]
    static let routesPerDuration = 10

    static let routes: [Int: [[String]]] = [
        30: [["neck", "march"], ["reach", "squat"], ["shrug", "calf"], ["side", "jacks"], ["crossArm", "knee"],
             ["twist", "hips"], ["breathe", "box"], ["circles", "march"], ["triceps", "squat"], ["wrists", "calf"]],
        45: [["reach", "neck", "march"], ["shrug", "twist", "squat"], ["breathe", "crossArm", "calf"], ["circles", "side", "jacks"],
             ["eyes", "wrists", "knee"], ["triceps", "shrug", "hips"], ["neck", "circles", "box"], ["side", "breathe", "march"],
             ["twist", "reach", "squat"], ["crossArm", "eyes", "jacks"]],
        60: [["breathe", "neck", "reach", "march"], ["shrug", "side", "wrists", "squat"], ["circles", "crossArm", "twist", "calf"],
             ["eyes", "triceps", "side", "jacks"], ["neck", "shrug", "reach", "knee"], ["wrists", "twist", "circles", "hips"],
             ["breathe", "crossArm", "triceps", "box"], ["reach", "eyes", "shrug", "march"], ["side", "neck", "circles", "squat"],
             ["twist", "wrists", "breathe", "jacks"]],
        120: [["breathe", "neck", "shrug", "march", "reach", "squat"], ["reach", "side", "crossArm", "calf", "twist", "jacks"],
              ["circles", "wrists", "triceps", "knee", "neck", "box"], ["eyes", "shrug", "side", "hips", "breathe", "march"],
              ["neck", "twist", "circles", "squat", "crossArm", "calf"], ["breathe", "reach", "wrists", "jacks", "triceps", "knee"],
              ["shrug", "crossArm", "eyes", "box", "side", "hips"], ["side", "neck", "twist", "march", "circles", "squat"],
              ["reach", "triceps", "shrug", "calf", "wrists", "jacks"], ["circles", "breathe", "neck", "knee", "eyes", "box"]],
    ]

    static func stepSeconds(for total: Int) -> Double { total >= 120 ? 20 : 15 }

    /// The session for the next visit; advances the rotation.
    static func nextSession(now: Date = Date()) -> [SessionStep] {
        let index = currentIndex(now: now)
        if Settings.shared.variation == .perVisit { advanceCursor(now: now) }
        return session(route: index)
    }

    static func session(route index: Int, seconds: Int = Settings.shared.sessionSeconds) -> [SessionStep] {
        let total = durations.contains(seconds) ? seconds : 60
        let ids = routes[total]![index % routesPerDuration]
        let step = stepSeconds(for: total)
        return resolve(ids, seed: index).map { SessionStep(exercise: $0, seconds: step) }
    }

    /// Which route the next visit uses, according to the variation setting.
    static func currentIndex(now: Date = Date()) -> Int {
        let cal = Calendar.current
        let day = Int(cal.startOfDay(for: now).timeIntervalSince1970 / 86_400)
        switch Settings.shared.variation {
        case .perVisit:
            // Every morning the 10 routes are shuffled; visits go through them in that order,
            // so the same route never comes back twice in a day before all others were done.
            var rng = SeededGenerator(seed: UInt64(day))
            let order = Array(0..<routesPerDuration).shuffled(using: &rng)
            return order[cursor(now: now) % routesPerDuration]
        case .daily:
            return day % routesPerDuration
        case .weekly:
            let week = cal.component(.weekOfYear, from: now) + cal.component(.yearForWeekOfYear, from: now) * 53
            return week % routesPerDuration
        case .monthly:
            return (cal.component(.month, from: now) + cal.component(.year, from: now) * 12) % routesPerDuration
        case .never:
            return Settings.shared.pinnedRoute % routesPerDuration
        }
    }

    // MARK: Exclusions

    static func isAllowed(_ exercise: Exercise) -> Bool {
        let s = Settings.shared
        return !s.excludedExercises.contains(exercise.id) && !(s.seatedOnly && exercise.posture == .standing)
    }

    /// Replaces unwanted exercises with allowed ones: same posture (seated if seated-only), same body zone if possible.
    static func resolve(_ ids: [String], seed: Int) -> [Exercise] {
        let allowed = Exercise.all.filter(isAllowed)
        guard !allowed.isEmpty else { return ids.compactMap(Exercise.find) }
        var used = Set<String>()
        return ids.enumerated().compactMap { i, id in
            guard let wanted = Exercise.find(id) else { return nil }
            if isAllowed(wanted), !used.contains(id) {
                used.insert(id)
                return wanted
            }
            let posture: Posture = Settings.shared.seatedOnly ? .seated : wanted.posture
            var pool = allowed.filter { $0.posture == posture && !used.contains($0.id) }
            if pool.isEmpty { pool = allowed.filter { !used.contains($0.id) } }
            if pool.isEmpty { pool = allowed }
            let sameZone = pool.filter { $0.zone == wanted.zone }
            let candidates = sameZone.isEmpty ? pool : sameZone
            let pick = candidates[(seed * 7 + i * 3) % candidates.count]
            used.insert(pick.id)
            return pick
        }
    }

    // MARK: Rotation cursor

    private static let d = hoplaDefaults

    private static func cursor(now: Date) -> Int {
        d.string(forKey: "route.day") == Stats.dayKey(now) ? d.integer(forKey: "route.cursor") : 0
    }

    private static func advanceCursor(now: Date) {
        let next = cursor(now: now) + 1
        d.set(Stats.dayKey(now), forKey: "route.day")
        d.set(next, forKey: "route.cursor")
    }
}

/// Deterministic RNG (SplitMix64), so a given day always shuffles the same way.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
