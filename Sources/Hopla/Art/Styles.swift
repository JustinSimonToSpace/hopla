import CoreGraphics
import Foundation

/// How an art direction paints: a small set of knobs shared by one generic painter.
struct StyleSpec {
    enum Fill { case flat, pencil, clay, wash, glow, paper }
    enum LimbKind { case tube, hose, line }
    enum EyeKind { case bead, dot, pie, big }

    var fill: Fill = .flat
    var outline: CGFloat = 3              // 0 = no contour
    var ink: String? = nil                // fixed contour color (nil = avatar outline color)
    var limbs: LimbKind = .tube
    var limbWidth: CGFloat = 10
    var eyes: EyeKind = .bead
    var gloves = false                    // big white cartoon hands
    var shine = false                     // glossy highlight on the body
    var grain = false                     // old film specks
    var hatching = false                  // pencil hatching on the shadow side
    var pixel: CGFloat? = nil             // pixel size (pixel art, LCD)
    var lcd = false                       // monochrome dot-matrix screen
    var fps: Double? = nil                // stop-motion / line boil frame rate
    var jitter: CGFloat = 0               // line boil amplitude

    /// Snaps time to the style's frame rate, for stop-motion styles.
    func quantize(_ date: Date) -> Date {
        guard let fps else { return date }
        let t = date.timeIntervalSinceReferenceDate
        return Date(timeIntervalSinceReferenceDate: (t * fps).rounded(.down) / fps)
    }
}

extension ArtStyle {
    var spec: StyleSpec {
        switch self {
        case .classic:
            return StyleSpec()
        case .ligneClaire:
            return StyleSpec(outline: 2, ink: "#161616", limbWidth: 9, eyes: .dot)
        case .sketch:
            return StyleSpec(fill: .pencil, outline: 1.4, ink: "#3B3A36", limbWidth: 9, hatching: true, fps: 8, jitter: 0.9)
        case .rubberHose:
            return StyleSpec(outline: 2.6, ink: "#141212", limbs: .hose, limbWidth: 4.5, eyes: .pie, gloves: true, grain: true)
        case .cartoon:
            return StyleSpec(outline: 4, limbs: .line, limbWidth: 4.5, eyes: .big, gloves: true, shine: true)
        case .pixel:
            return StyleSpec(outline: 4, limbWidth: 10, pixel: 4)
        case .lcd:
            return StyleSpec(outline: 4, limbWidth: 11, pixel: 4, lcd: true)
        case .clay:
            return StyleSpec(fill: .clay, outline: 0, limbWidth: 11, fps: 12, jitter: 0.45)
        case .watercolor:
            return StyleSpec(fill: .wash, outline: 0, limbWidth: 9)
        case .neon:
            return StyleSpec(fill: .glow, outline: 2.4, limbs: .line, limbWidth: 3)
        case .paper:
            return StyleSpec(fill: .paper, outline: 0, limbWidth: 10)
        }
    }
}
