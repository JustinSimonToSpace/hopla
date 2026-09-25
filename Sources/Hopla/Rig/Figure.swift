import CoreGraphics
import SwiftUI

/// Pure geometry: where every part of the character is for a given pose and avatar.
/// Art styles (see Art/Painter.swift) decide how those parts are painted.
///
/// Design space is 200×200, y down. Body parts are expressed in "local" body coordinates
/// (origin at the hips, bottom of the body at y = 2) and mapped to the canvas by `bodyTransform`.
struct Figure {
    static let ground: CGFloat = 185

    struct Limb {
        var side: CGFloat          // -1 left, +1 right
        var points: [CGPoint]      // joint chain, canvas coordinates
        var end: CGPoint           // hand or foot center
    }

    let pose: Pose
    let avatar: Avatar
    let body: BodyGeometry
    let bodyTransform: CGAffineTransform
    let arms: [Limb]
    let legs: [Limb]

    init(pose: Pose, avatar: Avatar) {
        self.pose = pose
        self.avatar = avatar
        let body = BodyGeometry(avatar.shape)
        self.body = body

        let sx = 1 - pose.stretch * 0.6, sy = 1 + pose.stretch
        let tilt = pose.tilt * .pi / 180
        let pivot = CGPoint(x: 100 + pose.x, y: 150 + pose.y + pose.bodyY)
        let transform = CGAffineTransform(translationX: pivot.x, y: pivot.y).rotated(by: tilt).scaledBy(x: sx, y: sy)
        bodyTransform = transform

        func rotate(_ v: CGPoint) -> CGPoint {
            CGPoint(x: v.x * cos(tilt) - v.y * sin(tilt), y: v.x * sin(tilt) + v.y * cos(tilt))
        }

        arms = [-1.0, 1.0].map { s in
            let arm = s < 0 ? pose.leftArm : pose.rightArm
            let shoulder = CGPoint(x: body.shoulderX * s, y: body.shoulderY - pose.shrug).applying(transform)
            func direction(_ degrees: Double) -> CGPoint {
                let a = degrees * .pi / 180
                return rotate(CGPoint(x: s * sin(a), y: cos(a)))
            }
            let d1 = direction(arm.shoulder), d2 = direction(arm.shoulder + arm.elbow)
            let elbow = CGPoint(x: shoulder.x + d1.x * 20, y: shoulder.y + d1.y * 20)
            let hand = CGPoint(x: elbow.x + d2.x * 18, y: elbow.y + d2.y * 18)
            return Limb(side: s, points: [shoulder, elbow, hand], end: hand)
        }

        legs = [-1.0, 1.0].map { s in
            let foot = s < 0 ? pose.leftFoot : pose.rightFoot
            // Hips don't follow the lean, so side bends happen above the waist instead of twisting the legs.
            let hip = CGPoint(x: pivot.x + 20 * s * sx, y: pivot.y - 4 * sy)
            let target = CGPoint(x: 100 + pose.x + s * (24 + foot.dx), y: Figure.ground + pose.y - foot.lift)
            let (knee, end) = Figure.solveIK(from: hip, to: target, side: s)
            return Limb(side: s, points: [hip, knee, end], end: end)
        }
    }

    /// Two-bone IK with equal segments; knees bend outward.
    private static func solveIK(from a: CGPoint, to b: CGPoint, side s: CGFloat) -> (CGPoint, CGPoint) {
        let l: CGFloat = 20
        let reach = 2 * l - 0.01
        var end = b
        var dx = b.x - a.x, dy = b.y - a.y
        var d = hypot(dx, dy)
        if d > reach {
            end = CGPoint(x: a.x + dx / d * reach, y: a.y + dy / d * reach)
            dx = end.x - a.x; dy = end.y - a.y; d = reach
        }
        guard d > 0.001 else { return (a, a) }
        let h = sqrt(max(0, l * l - d * d / 4))
        var px = -dy / d, py = dx / d
        if px * s < 0 { px = -px; py = -py }
        return (CGPoint(x: (a.x + end.x) / 2 + px * h, y: (a.y + end.y) / 2 + py * h), end)
    }

    func has(_ extra: Extra) -> Bool { avatar.extras.contains(extra) }

    var handKind: Extremity { avatar.hand ?? avatar.style.defaultHand }
    var footKind: Extremity { avatar.foot ?? avatar.style.defaultFoot }

    // MARK: Face layout (local coordinates)

    var eyeY: CGFloat { body.top + 32 }
    var mouthY: CGFloat { body.top + 46 }
    var cheekY: CGFloat { body.top + 41 }
    var eyeDX: CGFloat { 15 * min(body.half, 46) / 46 }
    var cheekDX: CGFloat { body.half - 19 }

    // MARK: Parts (local coordinates)

    var bellyPath: CGPath? {
        let h = body.half, bottom = body.bottom
        switch avatar.belly {
        case .none: return nil
        case .oval: return CGPath(ellipseIn: CGRect(x: -h * 0.59, y: bottom - 31, width: h * 1.18, height: 28), transform: nil)
        case .large:
            let top = mouthY + 8
            return CGPath(ellipseIn: CGRect(x: -h * 0.72, y: top, width: h * 1.44, height: bottom - 1 - top), transform: nil)
        case .muzzle: return CGPath(ellipseIn: CGRect(x: -h * 0.62, y: mouthY - 12, width: h * 1.24, height: 30), transform: nil)
        }
    }

    /// Ears, toppers and tails that sit behind the body.
    var backParts: [(CGPath, Paint)] {
        var parts: [(CGPath, Paint)] = []
        let t = body.top, c = body.crown, k = body.half / 46, h = body.half
        if avatar.tail == .dino || avatar.tail == .dragon {
            let tail = CGMutablePath()
            tail.move(to: CGPoint(x: h - 12, y: -34))
            tail.addQuadCurve(to: CGPoint(x: h + 36, y: 2), control: CGPoint(x: h + 22, y: -26))
            tail.addQuadCurve(to: CGPoint(x: h - 10, y: -4), control: CGPoint(x: h + 12, y: 6))
            tail.closeSubpath()
            parts.append((tail, .body))
            if avatar.tail == .dragon {
                parts.append((triangle((h + 28, -6), (h + 48, -8), (h + 40, 10)), .accent))
            }
        }
        if has(.mane) {
            let cy = t + 40, r = h + 7
            for i in 0..<13 {
                let a = (-200.0 + Double(i) * 220.0 / 12.0) * .pi / 180
                parts.append((circle(CGPoint(x: r * cos(a), y: cy + r * 0.95 * sin(a)), 14), .accent))
            }
        }
        if has(.frill) {
            parts.append((CGPath(ellipseIn: CGRect(x: -h - 20, y: t - 22, width: 2 * h + 40, height: 84), transform: nil), .accent))
            for x in [-h - 6, -h * 0.5, 0, h * 0.5, h + 6] {
                parts.append((circle(CGPoint(x: x, y: t - 12 + abs(x) * 0.28), 4.5), .pattern))
            }
        }
        if has(.wings) {
            for s in [-1.0, 1.0] {
                let w = CGMutablePath()
                w.move(to: CGPoint(x: s * (h - 8), y: t + 26))
                w.addLine(to: CGPoint(x: s * (h + 30), y: t - 4))
                w.addQuadCurve(to: CGPoint(x: s * (h + 24), y: t + 24), control: CGPoint(x: s * (h + 38), y: t + 12))
                w.addQuadCurve(to: CGPoint(x: s * (h + 8), y: t + 42), control: CGPoint(x: s * (h + 20), y: t + 30))
                w.closeSubpath()
                parts.append((w, .accent))
            }
        }
        if has(.gills) {
            for s in [-1.0, 1.0] {
                for j in 0..<3 {
                    let base = CGPoint(x: s * (h - 10), y: t + 24 + CGFloat(j) * 9)
                    let tip = CGPoint(x: s * (h + 15), y: t + 4 + CGFloat(j) * 15)
                    let frond = CGMutablePath()
                    frond.move(to: base)
                    frond.addQuadCurve(to: tip, control: CGPoint(x: s * (h + 4), y: base.y - 8))
                    parts.append((frond.copy(strokingWithWidth: 6, lineCap: .round, lineJoin: .round, miterLimit: 10), .accent))
                    parts.append((circle(tip, 4.5), .accent))
                }
            }
        }
        parts = anatomyBehind + parts
        if avatar.tail == .fox {
            let h = body.half
            let tail = CGMutablePath()
            tail.move(to: CGPoint(x: h - 10, y: -4))
            tail.addCurve(to: CGPoint(x: h + 30, y: -64), control1: CGPoint(x: h + 30, y: -2), control2: CGPoint(x: h + 42, y: -44))
            tail.addCurve(to: CGPoint(x: h - 8, y: -30), control1: CGPoint(x: h + 18, y: -70), control2: CGPoint(x: h + 2, y: -50))
            tail.closeSubpath()
            parts.append((tail, .body))
            let tip = CGMutablePath()
            tip.move(to: CGPoint(x: h + 30, y: -64))
            tip.addCurve(to: CGPoint(x: h + 26, y: -40), control1: CGPoint(x: h + 38, y: -56), control2: CGPoint(x: h + 36, y: -44))
            tip.addQuadCurve(to: CGPoint(x: h + 14, y: -58), control: CGPoint(x: h + 16, y: -46))
            tip.closeSubpath()
            parts.append((tip, .accent))
        }
        for s in [-1.0, 1.0] {
            switch avatar.ears {
            case .none: break
            case .cat:
                parts.append((triangle((10 * k * s, t + 8), (30 * k * s, t - 17), (40 * k * s, t + 18)), .body))
                parts.append((triangle((19 * k * s, t + 6), (29 * k * s, t - 9), (34 * k * s, t + 10)), .cheeks))
            case .fox:
                parts.append((triangle((12 * k * s, t + 10), (34 * k * s, t - 24), (46 * k * s, t + 22)), .body))
                parts.append((triangle((21 * k * s, t + 6), (32 * k * s, t - 12), (38 * k * s, t + 12)), .accent))
            case .bunny:
                let r = CGAffineTransform(translationX: 17 * s, y: t - 12).rotated(by: 12 * s * .pi / 180)
                parts.append((CGPath(ellipseIn: CGRect(x: -8, y: -24, width: 16, height: 44), transform: [r]), .body))
                parts.append((CGPath(ellipseIn: CGRect(x: -3.5, y: -17, width: 7, height: 28), transform: [r]), .cheeks))
            case .bear:
                let c = CGPoint(x: 30 * k * s, y: t + 8)
                parts.append((circle(c, 12), .body))
                parts.append((circle(c, 6), .cheeks))
            case .mouse:
                parts.append((circle(CGPoint(x: 36 * k * s, y: t + 2), 18), .body))
            case .elephant:
                let r = CGAffineTransform(translationX: s * (h + 8), y: t + 38).rotated(by: -10 * s * .pi / 180)
                parts.append((CGPath(ellipseIn: CGRect(x: -17, y: -24, width: 34, height: 48), transform: [r]), .body))
                parts.append((CGPath(ellipseIn: CGRect(x: -10, y: -16, width: 20, height: 32), transform: [r]), .cheeks))
            case .bat:
                parts.append((triangle((8 * k * s, t + 12), (30 * k * s, t - 28), (46 * k * s, t + 16)), .body))
                parts.append((triangle((18 * k * s, t + 8), (29 * k * s, t - 14), (38 * k * s, t + 12)), .cheeks))
            case .pointy:
                parts.append((triangle((s * (h - 6), eyeY - 8), (s * (h + 20), eyeY - 20), (s * (h - 4), eyeY + 8)), .body))
            }
        }
        if has(.horns) {
            for s in [-1.0, 1.0] {
                let horn = CGMutablePath()
                horn.move(to: CGPoint(x: s * 8 * k, y: t + 6))
                horn.addQuadCurve(to: CGPoint(x: s * 27 * k, y: t - 18), control: CGPoint(x: s * 10 * k, y: t - 10))
                horn.addQuadCurve(to: CGPoint(x: s * 24 * k, y: t + 10), control: CGPoint(x: s * 26 * k, y: t - 2))
                horn.closeSubpath()
                parts.append((horn, .horns))
            }
        }
        if has(.unicornHorn) {
            parts.append((triangle((-6, c + 6), (6, c + 6), (1, c - 30)), .horns))
        }
        if has(.antennae) {
            for s in [-1.0, 1.0] { parts.append((circle(CGPoint(x: s * 22, y: t - 21), 5), .accent)) }
        }
        if has(.stem) {
            let stem = CGMutablePath()
            stem.move(to: CGPoint(x: 0, y: c + 4))
            stem.addQuadCurve(to: CGPoint(x: 5, y: c - 12), control: CGPoint(x: -2, y: c - 6))
            parts.append((stem.copy(strokingWithWidth: 7, lineCap: .round, lineJoin: .round, miterLimit: 10), .accent))
        }
        parts += anatomyOnHead
        switch avatar.topper {
        case .leaf:
            let r = CGAffineTransform(translationX: 12, y: c - 14).rotated(by: -30 * .pi / 180)
            parts.append((CGPath(ellipseIn: CGRect(x: -12, y: -6.5, width: 24, height: 13), transform: [r]), .accent))
        case .bolt:
            let bolt = CGMutablePath()
            bolt.addLines(between: [(3, 6), (-9, -10), (-1, -10), (-7, -32), (11, -6), (3, -6), (9, 6)].map { CGPoint(x: $0.0, y: c + $0.1) })
            bolt.closeSubpath()
            parts.append((bolt, .accent))
        case .tuft:
            let tuft = CGMutablePath()
            tuft.move(to: CGPoint(x: -7, y: c + 5))
            tuft.addQuadCurve(to: CGPoint(x: 3, y: c - 19), control: CGPoint(x: -10, y: c - 10))
            tuft.addQuadCurve(to: CGPoint(x: 7, y: c + 5), control: CGPoint(x: 10, y: c - 6))
            tuft.closeSubpath()
            parts.append((tuft, .accent))
        case .sprout:
            parts.append((leaf(CGPoint(x: 10, y: c - 19), -25), .accent))
            parts.append((leaf(CGPoint(x: -6, y: c - 17), 205), .accent))
        case .antenna:
            parts.append((circle(CGPoint(x: 6, y: c - 23), 6), .accent))
        default: break
        }
        return parts
    }

    /// Thin strokes behind the body (sprout stem, antenna stalk).
    var backStrokes: [CGPath] {
        let t = body.top
        var strokes: [CGPath] = []
        if has(.antennae) {
            for s in [-1.0, 1.0] {
                let a = CGMutablePath()
                a.move(to: CGPoint(x: s * 10, y: t + 4))
                a.addQuadCurve(to: CGPoint(x: s * 22, y: t - 17), control: CGPoint(x: s * 12, y: t - 8))
                strokes.append(a)
            }
        }
        let c = body.crown
        let p = CGMutablePath()
        strokes += anatomyStrokes
        switch avatar.topper {
        case .leaf:
            p.move(to: CGPoint(x: 0, y: c + 4))
            p.addQuadCurve(to: CGPoint(x: 3, y: c - 10), control: CGPoint(x: -2, y: c - 4))
        case .sprout:
            p.move(to: CGPoint(x: 0, y: c + 4))
            p.addQuadCurve(to: CGPoint(x: 2, y: c - 15), control: CGPoint(x: -4, y: c - 6))
        case .antenna:
            p.move(to: CGPoint(x: 0, y: c + 4))
            p.addQuadCurve(to: CGPoint(x: 6, y: c - 18), control: CGPoint(x: 6, y: c - 6))
        default:
            return strokes
        }
        return strokes + [p]
    }

    /// Accessories worn in front of the body.
    var frontParts: [(CGPath, Paint)] {
        let t = body.top
        var parts = anatomyInFront
        if has(.forelock) {
            parts += [(-11.0, 3.0, 24.0, 14.0, -20.0), (3.0, -1.0, 22.0, 14.0, 10.0), (13.0, 5.0, 16.0, 11.0, 30.0)].map { x, y, w, hh, a in
                let tr = CGAffineTransform(translationX: x, y: t + y).rotated(by: a * .pi / 180)
                return (CGPath(ellipseIn: CGRect(x: -w / 2, y: -hh / 2, width: w, height: hh), transform: [tr]), .pattern)
            }
        }
        return parts + toppersInFront
    }

    private var toppersInFront: [(CGPath, Paint)] {
        let t = body.top
        switch avatar.topper {
        case .beret:
            return [
                (CGPath(roundedRect: CGRect(x: -26, y: t - 2, width: 52, height: 9), cornerWidth: 4, cornerHeight: 4, transform: nil), .pattern),
                (CGPath(ellipseIn: CGRect(x: -32, y: t - 14, width: 64, height: 16), transform: nil), .white),
                (circle(CGPoint(x: 0, y: t - 17), 6), .accent),
            ]
        default:
            return []
        }
    }

    /// Pattern painted inside the body (clipped to it).
    var patternParts: [CGPath] {
        let h = body.half, bottom = body.bottom
        switch avatar.pattern {
        case .none: return []
        case .stripes:
            return stride(from: mouthY + 12, to: bottom, by: 9).map {
                CGPath(rect: CGRect(x: -h - 10, y: $0, width: 2 * h + 20, height: 4.5), transform: nil)
            }
        case .band:
            return [CGPath(rect: CGRect(x: -h - 10, y: bottom - 32, width: 2 * h + 20, height: 17), transform: nil)]
        case .facePatch:
            return [CGPath(ellipseIn: CGRect(x: -h * 0.74, y: eyeY - 17, width: h * 1.48, height: 48), transform: nil)]
        case .spots:
            return [circle(CGPoint(x: -20, y: -60), 5), circle(CGPoint(x: 22, y: -30), 6),
                    circle(CGPoint(x: -8, y: -18), 4), circle(CGPoint(x: 28, y: -64), 4)]
        case .cleft, .seeds, .patches, .zebra, .drips, .bandages, .stars, .cracks, .chest, .eggCrack, .grooves, .rivets, .glitch, .marks, .swirl:
            return anatomyPattern
        case .ribs:
            return [-0.62, -0.25, 0.25, 0.62].map { f in
                let x = h * f
                let rib = CGMutablePath()
                rib.move(to: CGPoint(x: x * 0.7, y: body.top + 5))
                rib.addQuadCurve(to: CGPoint(x: x * 0.7, y: bottom - 3), control: CGPoint(x: x * 1.35, y: (body.top + bottom) / 2))
                return rib.copy(strokingWithWidth: 2.4, lineCap: .round, lineJoin: .round, miterLimit: 10)
            }
        }
    }

    var beakPath: CGPath? {
        guard avatar.beak else { return nil }
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -8, y: mouthY - 4))
        p.addQuadCurve(to: CGPoint(x: 8, y: mouthY - 4), control: CGPoint(x: 0, y: mouthY - 8))
        p.addQuadCurve(to: CGPoint(x: 0, y: mouthY + 6), control: CGPoint(x: 5, y: mouthY + 2))
        p.addQuadCurve(to: CGPoint(x: -8, y: mouthY - 4), control: CGPoint(x: -5, y: mouthY + 2))
        p.closeSubpath()
        return p
    }

    // MARK: Helpers

    func triangle(_ a: (CGFloat, CGFloat), _ b: (CGFloat, CGFloat), _ c: (CGFloat, CGFloat)) -> CGPath {
        let p = CGMutablePath()
        p.addLines(between: [CGPoint(x: a.0, y: a.1), CGPoint(x: b.0, y: b.1), CGPoint(x: c.0, y: c.1)])
        p.closeSubpath()
        return p
    }

    func circle(_ c: CGPoint, _ r: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r), transform: nil)
    }

    func leaf(_ c: CGPoint, _ degrees: CGFloat) -> CGPath {
        let t = CGAffineTransform(translationX: c.x, y: c.y).rotated(by: degrees * .pi / 180)
        return CGPath(ellipseIn: CGRect(x: -9, y: -5, width: 18, height: 10), transform: [t])
    }
}

/// Which palette color a part uses.
enum Paint { case body, belly, limbs, outline, cheeks, accent, pattern, horns, hand, foot, eyes, glass, white }

/// Body outline and landmarks for each shape (local coordinates, bottom at y = 2).
struct BodyGeometry {
    let path: CGPath
    let top: CGFloat
    let half: CGFloat
    let shoulderX: CGFloat
    let bottom: CGFloat = 2
    /// Where things growing from the head (stems, antennae, horns) are rooted, at x = 0.
    var crown: CGFloat
    var shoulderY: CGFloat { top + 44 }

    init(_ shape: BodyShape) {
        func squircle(_ r: CGRect, _ radius: CGFloat) -> CGPath {
            RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: r).cgPath
        }
        crown = 0
        switch shape {
        case .apple:
            // Two lobes around a dip where the stem grows, widest in the upper third, narrower at the bottom.
            let p = CGMutablePath()
            for side in [1.0, -1.0] {
                p.move(to: CGPoint(x: 0, y: -72))
                p.addCurve(to: CGPoint(x: 23 * side, y: -86), control1: CGPoint(x: 5 * side, y: -82), control2: CGPoint(x: 12 * side, y: -87))
                p.addCurve(to: CGPoint(x: 49 * side, y: -54), control1: CGPoint(x: 40 * side, y: -86), control2: CGPoint(x: 50 * side, y: -72))
                p.addCurve(to: CGPoint(x: 22 * side, y: 0), control1: CGPoint(x: 48 * side, y: -26), control2: CGPoint(x: 37 * side, y: 0))
                p.addCurve(to: CGPoint(x: 0, y: -3), control1: CGPoint(x: 14 * side, y: 0), control2: CGPoint(x: 6 * side, y: -3))
            }
            path = p.union(p); top = -86; half = 47; shoulderX = 45; crown = -72
        case .flame:
            // Three flickering tongues on top; the face sits in the round lower part.
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 0, y: 2))
            p.addCurve(to: CGPoint(x: 44, y: -34), control1: CGPoint(x: 28, y: 2), control2: CGPoint(x: 44, y: -14))
            p.addCurve(to: CGPoint(x: 25, y: -88), control1: CGPoint(x: 44, y: -58), control2: CGPoint(x: 30, y: -72))
            p.addQuadCurve(to: CGPoint(x: 11, y: -70), control: CGPoint(x: 19, y: -74))
            p.addQuadCurve(to: CGPoint(x: 2, y: -106), control: CGPoint(x: 15, y: -90))
            p.addQuadCurve(to: CGPoint(x: -9, y: -70), control: CGPoint(x: -9, y: -88))
            p.addQuadCurve(to: CGPoint(x: -23, y: -86), control: CGPoint(x: -15, y: -76))
            p.addCurve(to: CGPoint(x: -44, y: -34), control1: CGPoint(x: -30, y: -70), control2: CGPoint(x: -44, y: -58))
            p.addCurve(to: CGPoint(x: 0, y: 2), control1: CGPoint(x: -44, y: -14), control2: CGPoint(x: -28, y: 2))
            p.closeSubpath()
            path = p; top = -82; half = 44; shoulderX = 42; crown = -100
        case .drop:
            let p = CGMutablePath()
            for side in [1.0, -1.0] {
                p.move(to: CGPoint(x: 0, y: -104))
                p.addCurve(to: CGPoint(x: 45 * side, y: -30), control1: CGPoint(x: 10 * side, y: -86), control2: CGPoint(x: 45 * side, y: -62))
                p.addCurve(to: CGPoint(x: 0, y: 2), control1: CGPoint(x: 45 * side, y: -6), control2: CGPoint(x: 25 * side, y: 2))
            }
            path = p.union(p); top = -82; half = 45; shoulderX = 42; crown = -100
        case .rock:
            let corners = [CGPoint(x: -44, y: -12), CGPoint(x: -40, y: -60), CGPoint(x: -16, y: -84), CGPoint(x: 16, y: -86),
                           CGPoint(x: 42, y: -62), CGPoint(x: 47, y: -20), CGPoint(x: 34, y: 2), CGPoint(x: -32, y: 2)]
            let p = CGMutablePath()
            let mid = { (a: CGPoint, b: CGPoint) in CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }
            p.move(to: mid(corners[corners.count - 1], corners[0]))
            for i in corners.indices {
                p.addArc(tangent1End: corners[i], tangent2End: mid(corners[i], corners[(i + 1) % corners.count]), radius: 9)
            }
            p.closeSubpath()
            path = p; top = -86; half = 46; shoulderX = 42; crown = -86
        case .berry:
            let p = CGMutablePath()
            for side in [1.0, -1.0] {
                p.move(to: CGPoint(x: 0, y: -84))
                p.addCurve(to: CGPoint(x: 47 * side, y: -62), control1: CGPoint(x: 30 * side, y: -86), control2: CGPoint(x: 47 * side, y: -80))
                p.addCurve(to: CGPoint(x: 0, y: 2), control1: CGPoint(x: 47 * side, y: -32), control2: CGPoint(x: 24 * side, y: 2))
            }
            path = p.union(p); top = -84; half = 47; shoulderX = 42; crown = -84
        case .lemon:
            var p = CGPath(ellipseIn: CGRect(x: -48, y: -72, width: 96, height: 74), transform: nil)
            for side in [1.0, -1.0] {
                p = p.union(CGPath(ellipseIn: CGRect(x: 48 * side - 7, y: -42, width: 14, height: 12), transform: nil))
            }
            path = p; top = -72; half = 48; shoulderX = 46; crown = -72
        case .ghost:
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -44, y: -40))
            p.addCurve(to: CGPoint(x: 0, y: -86), control1: CGPoint(x: -44, y: -70), control2: CGPoint(x: -26, y: -86))
            p.addCurve(to: CGPoint(x: 44, y: -40), control1: CGPoint(x: 26, y: -86), control2: CGPoint(x: 44, y: -70))
            p.addLine(to: CGPoint(x: 44, y: 0))
            p.addQuadCurve(to: CGPoint(x: 22, y: 0), control: CGPoint(x: 33, y: 8))
            p.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: 11, y: -6))
            p.addQuadCurve(to: CGPoint(x: -22, y: 0), control: CGPoint(x: -11, y: 8))
            p.addQuadCurve(to: CGPoint(x: -44, y: 0), control: CGPoint(x: -33, y: -6))
            p.closeSubpath()
            path = p; top = -86; half = 44; shoulderX = 42; crown = -86
        case .egg:
            let p = CGMutablePath()
            for side in [1.0, -1.0] {
                p.move(to: CGPoint(x: 0, y: -92))
                p.addCurve(to: CGPoint(x: 43 * side, y: -30), control1: CGPoint(x: 27 * side, y: -92), control2: CGPoint(x: 43 * side, y: -62))
                p.addCurve(to: CGPoint(x: 0, y: 2), control1: CGPoint(x: 43 * side, y: -6), control2: CGPoint(x: 24 * side, y: 2))
            }
            path = p.union(p); top = -92; half = 43; shoulderX = 40; crown = -92
        case .round:
            path = squircle(CGRect(x: -46, y: -84, width: 92, height: 86), 40); top = -84; half = 46; shoulderX = 43; crown = top
        case .tall:
            path = squircle(CGRect(x: -39, y: -102, width: 78, height: 104), 37); top = -102; half = 39; shoulderX = 36; crown = top
        case .square:
            path = squircle(CGRect(x: -45, y: -80, width: 90, height: 82), 17); top = -80; half = 45; shoulderX = 42; crown = top
        case .blob:
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -50, y: -10))
            p.addCurve(to: CGPoint(x: 0, y: -76), control1: CGPoint(x: -50, y: -50), control2: CGPoint(x: -30, y: -76))
            p.addCurve(to: CGPoint(x: 50, y: -10), control1: CGPoint(x: 30, y: -76), control2: CGPoint(x: 50, y: -50))
            p.addCurve(to: CGPoint(x: 38, y: 2), control1: CGPoint(x: 50, y: -2), control2: CGPoint(x: 46, y: 2))
            p.addLine(to: CGPoint(x: -38, y: 2))
            p.addCurve(to: CGPoint(x: -50, y: -10), control1: CGPoint(x: -46, y: 2), control2: CGPoint(x: -50, y: -2))
            p.closeSubpath()
            path = p; top = -76; half = 50; shoulderX = 45; crown = top
        case .cloud:
            var p = CGPath(roundedRect: CGRect(x: -50, y: -46, width: 100, height: 48), cornerWidth: 22, cornerHeight: 22, transform: nil)
            for (x, y, r) in [(-26.0, -50.0, 25.0), (4.0, -60.0, 28.0), (30.0, -48.0, 22.0)] {
                p = p.union(CGPath(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r), transform: nil))
            }
            path = p; top = -86; half = 50; shoulderX = 47; crown = -80
        case .pear:
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 0, y: -84))
            p.addCurve(to: CGPoint(x: 50, y: -12), control1: CGPoint(x: 30, y: -84), control2: CGPoint(x: 50, y: -44))
            p.addCurve(to: CGPoint(x: 30, y: 2), control1: CGPoint(x: 50, y: -2), control2: CGPoint(x: 42, y: 2))
            p.addLine(to: CGPoint(x: -30, y: 2))
            p.addCurve(to: CGPoint(x: -50, y: -12), control1: CGPoint(x: -42, y: 2), control2: CGPoint(x: -50, y: -2))
            p.addCurve(to: CGPoint(x: 0, y: -84), control1: CGPoint(x: -50, y: -44), control2: CGPoint(x: -30, y: -84))
            p.closeSubpath()
            path = p; top = -84; half = 50; shoulderX = 42; crown = top
        }
    }
}
