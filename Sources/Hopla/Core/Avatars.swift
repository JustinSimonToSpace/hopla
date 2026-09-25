import AppKit
import SwiftUI

/// A collection = one art direction. Every avatar of every collection runs on the same skeleton,
/// so all of them can perform every move.
enum ArtStyle: String, Codable, CaseIterable, Identifiable {
    case classic, ligneClaire, sketch, rubberHose, cartoon, pixel, lcd, clay, watercolor, neon, paper

    var id: String { rawValue }

    /// The creature family of the collection.
    var collectionName: String {
        switch self {
        case .classic: return "Le Verger"
        case .ligneClaire: return "Grand Safari"
        case .sketch: return "Monstres de cahier"
        case .rubberHose: return "Fantômes rigolos"
        case .cartoon: return "Aliens"
        case .pixel: return "Bestiaire RPG"
        case .lcd: return "Élémentaires"
        case .clay: return "Dinosaures"
        case .watercolor: return "Monde marin"
        case .neon: return "Cyber-bestiaire"
        case .paper: return "Légendes"
        }
    }

    /// The art direction.
    var displayName: String {
        switch self {
        case .classic: return "Classique"
        case .ligneClaire: return "Ligne claire"
        case .sketch: return "Carnet de croquis"
        case .rubberHose: return "Cartoon 1930"
        case .cartoon: return "Cartoon TV"
        case .pixel: return "Pixel 16 bits"
        case .lcd: return "LCD Tamagotchi"
        case .clay: return "Pâte à modeler"
        case .watercolor: return "Aquarelle"
        case .neon: return "Néon"
        case .paper: return "Papier découpé"
        }
    }
}

enum BodyShape: String, Codable, CaseIterable { case round, apple, tall, square, blob, cloud, pear, berry, lemon, ghost, egg, flame, drop, rock }
enum Ears: String, Codable, CaseIterable { case none, cat, bunny, bear, fox, mouse, elephant, bat, pointy }
enum Topper: String, Codable, CaseIterable { case none, sprout, antenna, beret, leaf, mushroomCap, tuft, bolt }
enum Belly: String, Codable, CaseIterable { case none, oval, large, muzzle }
enum Pattern: String, Codable, CaseIterable {
    case none, stripes, band, facePatch, spots, ribs
    case cleft, seeds, patches, zebra, drips, bandages, stars, cracks, chest, eggCrack, grooves, rivets, glitch, marks, swirl
}
enum Tail: String, Codable, CaseIterable { case none, fox, dino, dragon }

/// Extra anatomy, freely combined: this is what turns the same skeleton into a lion, a dragon or an alien.
enum Extra: String, Codable {
    case cyclops, fangs, horns, unicornHorn, noseHorn, antennae, stem, forelock, mane, frill, gills, wings
    case leafCrown, calyx, ossicones, trunk, nostrils, fur, threeEyes, eyeStalks, bugWings, teeth, beard
    case plates, crest, tentacles, spout, shell, whiskers, propellers, flame, nineTails
}

struct Palette: Codable, Equatable {
    var body: String
    var belly: String
    var limbs: String
    var outline: String
    var cheeks: String
    var eyes: String
    var accent: String
    var pattern: String? = nil
    var hands: String? = nil
    var feet: String? = nil
    var horns: String? = nil
}

extension Palette {
    /// Colors from shared files: invalid ones become grey, and the main parts can't be made (almost) invisible.
    func sanitized() -> Palette {
        func clean(_ hex: String, visible: Bool) -> String {
            guard let c = CGColor.parse(hex) else { return "#888888" }
            return visible && c.alpha < 0.6 ? String(hex.prefix(hex.hasPrefix("#") ? 7 : 6)) : hex
        }
        func optional(_ hex: String?) -> String? { hex.map { clean($0, visible: true) } }
        var p = self
        p.body = clean(body, visible: true); p.belly = clean(belly, visible: false); p.limbs = clean(limbs, visible: true)
        p.outline = clean(outline, visible: true); p.cheeks = clean(cheeks, visible: false); p.eyes = clean(eyes, visible: true)
        p.accent = clean(accent, visible: false); p.pattern = pattern.map { clean($0, visible: false) }
        p.hands = optional(hands); p.feet = optional(feet); p.horns = optional(horns)
        return p
    }
}

struct Avatar: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var style: ArtStyle = .classic
    var shape: BodyShape = .round
    var ears: Ears = .none
    var topper: Topper = .none
    var belly: Belly = .oval
    var pattern: Pattern = .none
    var tail: Tail = .none
    var beak = false
    var extras: [Extra] = []
    var hand: Extremity? = nil     // nil = the collection's default hands
    var foot: Extremity? = nil
    var palette: Palette

    init(id: String, name: String, style: ArtStyle, shape: BodyShape = .round, ears: Ears = .none,
         topper: Topper = .none, belly: Belly = .oval, pattern: Pattern = .none, tail: Tail = .none,
         beak: Bool = false, extras: [Extra] = [], hand: Extremity? = nil, foot: Extremity? = nil, palette: Palette) {
        self.id = id; self.name = name; self.style = style; self.shape = shape; self.ears = ears
        self.topper = topper; self.belly = belly; self.pattern = pattern; self.tail = tail
        self.beak = beak; self.extras = extras; self.hand = hand; self.foot = foot; self.palette = palette
    }

    // Missing keys fall back to defaults, so community JSON files can stay short.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        palette = try c.decode(Palette.self, forKey: .palette)
        style = try c.decodeIfPresent(ArtStyle.self, forKey: .style) ?? .classic
        shape = try c.decodeIfPresent(BodyShape.self, forKey: .shape) ?? .round
        ears = try c.decodeIfPresent(Ears.self, forKey: .ears) ?? .none
        topper = try c.decodeIfPresent(Topper.self, forKey: .topper) ?? .none
        belly = try c.decodeIfPresent(Belly.self, forKey: .belly) ?? .oval
        pattern = try c.decodeIfPresent(Pattern.self, forKey: .pattern) ?? .none
        tail = try c.decodeIfPresent(Tail.self, forKey: .tail) ?? .none
        beak = try c.decodeIfPresent(Bool.self, forKey: .beak) ?? false
        extras = try c.decodeIfPresent([Extra].self, forKey: .extras) ?? []
        hand = try c.decodeIfPresent(Extremity.self, forKey: .hand)
        foot = try c.decodeIfPresent(Extremity.self, forKey: .foot)
    }

    /// Color for the main button in the bubble: the outline color, darkened if too light for white text.
    var buttonColor: Color {
        let c = CGColor.hex(palette.outline)
        return Color(cgColor: c.luminance > 0.55 ? c.mixed(with: .black, 0.45) : c)
    }

    var progressColor: Color { Color(hex: palette.limbs) }
}

enum AvatarLibrary {
    static var userFolder: URL {
        if isTestRun {
            return FileManager.default.temporaryDirectory.appendingPathComponent("HoplaSelfTest/Avatars", isDirectory: true)
        }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Hopla/Avatars", isDirectory: true)
    }

    /// Avatar files come from other people: they are size-limited, and their id can never become a path.
    private static let maxFileSize = 64 * 1024
    private static let maxExtras = 16

    /// Which file each custom avatar was loaded from, so deleting only ever touches that file.
    private static var sourceFiles: [String: URL] = [:]
    private static var cache: (stamp: Date?, count: Int, avatars: [Avatar])?

    /// Lowercase letters, digits, "-" and "_" only.
    static func safeID(_ raw: String) -> String {
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789-_")
        let cleaned = String(raw.lowercased().filter { allowed.contains($0) }.prefix(64))
        return cleaned.isEmpty ? "avatar" : cleaned
    }

    /// Built-in avatars plus any valid JSON avatar from the user folder (same id overrides a built-in).
    static func all() -> [Avatar] {
        let keys: [URLResourceKey] = [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey]
        let files = (try? FileManager.default.contentsOfDirectory(at: userFolder, includingPropertiesForKeys: keys)) ?? []
        // The cache is keyed on every file's date, so files edited in place are picked up too.
        let stamp = files.compactMap { (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate }.max()
        if let cache, cache.stamp == stamp, cache.count == files.count { return cache.avatars }

        var avatars = Avatar.catalog
        var sources: [String: URL] = [:]
        for file in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) where file.pathExtension == "json" {
            let values = try? file.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard values?.isRegularFile == true, (values?.fileSize ?? .max) <= maxFileSize,
                  let data = try? Data(contentsOf: file),
                  var avatar = try? JSONDecoder().decode(Avatar.self, from: data) else {
                NSLog("Hopla: avatar ignoré (fichier invalide) : \(file.lastPathComponent)")
                continue
            }
            // Ids are unique: a file can never take over a built-in avatar or another file.
            var id = safeID(avatar.id), n = 2
            while avatars.contains(where: { $0.id == id }) { id = "\(safeID(avatar.id))-\(n)"; n += 1 }
            avatar.id = id
            avatar.palette = avatar.palette.sanitized()
            avatar.name = String(avatar.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
            if avatar.name.isEmpty { avatar.name = "Hopla" }
            var seen = Set<Extra>()
            avatar.extras = Array(avatar.extras.filter { seen.insert($0).inserted }.prefix(maxExtras))
            sources[avatar.id] = file
            avatars.append(avatar)
        }
        sourceFiles = sources
        cache = (stamp, files.count, avatars)
        return avatars
    }

    static func current() -> Avatar {
        let avatars = all()
        return avatars.first { $0.id == Settings.shared.avatarID } ?? avatars[0]
    }

    static func invalidate() { cache = nil }

    /// Creates the user folder with an example file to copy from.
    static func bootstrapUserFolder() {
        let fm = FileManager.default
        try? fm.createDirectory(at: userFolder, withIntermediateDirectories: true)
        let example = userFolder.appendingPathComponent("exemple.json.sample")
        guard !fm.fileExists(atPath: example.path) else { return }
        var sample = Avatar.catalog[0]
        sample.id = "mon-avatar"
        sample.name = "Mon avatar"
        sample.palette.body = "#9AD0FF"
        sample.palette.limbs = "#6BB3F0"
        sample.palette.outline = "#1F4E79"
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? encoder.encode(sample).write(to: example)
    }

    static func isCustom(_ avatar: Avatar) -> Bool { !Avatar.catalog.contains { $0.id == avatar.id } }

    /// A copy to edit: custom avatars are edited in place, built-in ones get duplicated.
    static func draft(from avatar: Avatar) -> Avatar {
        guard !isCustom(avatar) else { return avatar }
        var copy = avatar
        copy.id = "perso-\(UUID().uuidString.prefix(8).lowercased())"
        copy.name = tr("\(avatar.name) perso", "My \(avatar.name)")
        return copy
    }

    static func save(_ avatar: Avatar) {
        var clean = avatar
        clean.id = safeID(avatar.id)
        try? FileManager.default.createDirectory(at: userFolder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let target = sourceFiles[clean.id] ?? userFolder.appendingPathComponent("\(clean.id).json")
        guard isInsideUserFolder(target) else { return }
        try? encoder.encode(clean).write(to: target, options: .atomic)
        invalidate()
    }

    /// Only removes the file the avatar was loaded from, and only if it sits in the avatars folder.
    static func delete(_ avatar: Avatar) {
        guard let file = sourceFiles[avatar.id], isInsideUserFolder(file) else { return }
        if isTestRun { try? FileManager.default.removeItem(at: file) } else { try? FileManager.default.trashItem(at: file, resultingItemURL: nil) }
        invalidate()
    }

    private static func isInsideUserFolder(_ url: URL) -> Bool {
        let folder = userFolder.standardizedFileURL.resolvingSymlinksInPath().path
        let parent = url.deletingLastPathComponent().standardizedFileURL.resolvingSymlinksInPath().path
        return parent == folder
    }
}

// MARK: - Colors

extension Color {
    init(hex: String) { self.init(cgColor: CGColor.hex(hex)) }
}

extension CGColor {
    private static let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

    private static var hexCache: [String: CGColor] = [:]

    /// "#RGB", "#RGBA", "#RRGGBB" or "#RRGGBBAA". Anything else is grey. Parsed colors are cached (drawn every frame).
    static func hex(_ hex: String) -> CGColor {
        if let cached = hexCache[hex] { return cached }
        let color = parse(hex) ?? CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        if hexCache.count < 2_000 { hexCache[hex] = color }
        return color
    }

    static func parse(_ hex: String) -> CGColor? {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard [3, 4, 6, 8].contains(s.count), s.allSatisfy(\.isHexDigit) else { return nil }
        if s.count <= 4 { s = String(s.flatMap { [$0, $0] }) }   // #F80 → #FF8800
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let hasAlpha = s.count == 8
        let rgb = hasAlpha ? v >> 8 : v
        return CGColor(srgbRed: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255,
                       blue: CGFloat(rgb & 0xFF) / 255, alpha: hasAlpha ? CGFloat(v & 0xFF) / 255 : 1)
    }

    var rgba: [CGFloat] {
        let c = converted(to: CGColor.srgb, intent: .defaultIntent, options: nil)?.components ?? [0, 0, 0, 1]
        return c.count >= 4 ? c : [c[0], c[0], c[0], c.last ?? 1]
    }

    var luminance: CGFloat {
        let c = rgba
        return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
    }

    func mixed(with other: CGColor, _ t: CGFloat) -> CGColor {
        let a = rgba, b = other.rgba
        return CGColor(srgbRed: a[0] + (b[0] - a[0]) * t, green: a[1] + (b[1] - a[1]) * t,
                       blue: a[2] + (b[2] - a[2]) * t, alpha: a[3])
    }

    func lighter(_ t: CGFloat) -> CGColor { mixed(with: .white, t) }
    func darker(_ t: CGFloat) -> CGColor { mixed(with: .black, t) }
    func withAlpha(_ a: CGFloat) -> CGColor { copy(alpha: a * alpha) ?? self }
}
