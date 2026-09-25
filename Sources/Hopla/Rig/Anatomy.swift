import CoreGraphics

/// Creature anatomy that turns the shared body into a giraffe, a turtle, a phoenix…
/// Everything is in body-local coordinates (see Figure), relative to the body's landmarks,
/// so each part fits any shape.
extension Figure {
    private var t: CGFloat { body.top }
    private var c: CGFloat { body.crown }
    private var h: CGFloat { body.half }
    private var bottom: CGFloat { body.bottom }

    // MARK: Behind the body (tails, shells, wings…)

    var anatomyBehind: [(CGPath, Paint)] {
        var parts: [(CGPath, Paint)] = []
        if has(.nineTails) {
            for (i, angle) in [-68.0, -34, 0, 34, 68].enumerated() {
                let place = CGAffineTransform(translationX: 0, y: -18).rotated(by: angle * .pi / 180)
                let tail = CGMutablePath()
                tail.move(to: CGPoint(x: -7, y: 0))
                tail.addCurve(to: CGPoint(x: 0, y: -78), control1: CGPoint(x: -24, y: -26), control2: CGPoint(x: -18, y: -66))
                tail.addCurve(to: CGPoint(x: 7, y: 0), control1: CGPoint(x: 18, y: -66), control2: CGPoint(x: 24, y: -26))
                tail.closeSubpath()
                parts.append((tail.copy(using: [place])!, .body))
                parts.append((CGPath(ellipseIn: CGRect(x: -9, y: -80, width: 18, height: 24), transform: [place]), i % 2 == 0 ? .accent : .accent))
            }
        }
        if has(.shell) {
            parts.append((CGPath(ellipseIn: CGRect(x: -h - 13, y: t - 6, width: 2 * h + 26, height: bottom - t + 4), transform: nil), .accent))
            for (x, y) in [(-h - 6, t + 34.0), (h + 6, t + 34.0), (-h - 2, t + 62.0), (h + 2, t + 62.0), (0, t - 1.0)] {
                parts.append((hexagon(CGPoint(x: x, y: y), 7), .pattern))
            }
        }
        if has(.bugWings) {
            for s in [-1.0, 1.0] {
                let r = CGAffineTransform(translationX: s * (h + 4), y: t + 16).rotated(by: s * 28 * .pi / 180)
                parts.append((CGPath(ellipseIn: CGRect(x: -13, y: -19, width: 26, height: 38), transform: [r]), .glass))
                let r2 = CGAffineTransform(translationX: s * (h + 2), y: t + 40).rotated(by: s * 60 * .pi / 180)
                parts.append((CGPath(ellipseIn: CGRect(x: -9, y: -13, width: 18, height: 26), transform: [r2]), .glass))
            }
        }
        if has(.plates) {
            for (i, a) in stride(from: -150.0, through: -30, by: 30).enumerated() {
                let rad = a * .pi / 180
                let base = CGPoint(x: (h - 4) * cos(rad), y: t + 42 + (bottom - t) * 0.55 * sin(rad))
                let len: CGFloat = i == 2 ? 20 : 15
                let dir = CGPoint(x: cos(rad), y: sin(rad)), n = CGPoint(x: -sin(rad), y: cos(rad))
                let plate = CGMutablePath()
                plate.move(to: CGPoint(x: base.x + n.x * 8, y: base.y + n.y * 8))
                plate.addQuadCurve(to: CGPoint(x: base.x + dir.x * len, y: base.y + dir.y * len), control: CGPoint(x: base.x + n.x * 8 + dir.x * len * 0.7, y: base.y + n.y * 8 + dir.y * len * 0.7))
                plate.addQuadCurve(to: CGPoint(x: base.x - n.x * 8, y: base.y - n.y * 8), control: CGPoint(x: base.x - n.x * 8 + dir.x * len * 0.7, y: base.y - n.y * 8 + dir.y * len * 0.7))
                plate.closeSubpath()
                parts.append((plate, .accent))
            }
        }
        if has(.fur) {
            // Shaggy tufts sticking out all around the body.
            let center = CGPoint(x: 0, y: (t + bottom) / 2)
            for line in PathTools.polylines(body.path, step: 11) {
                for (i, p) in line.points.enumerated() where i % 1 == 0 && p.y < bottom - 6 {
                    let d = CGPoint(x: p.x - center.x, y: p.y - center.y)
                    let len = max(hypot(d.x, d.y), 1)
                    let u = CGPoint(x: d.x / len, y: d.y / len), n = CGPoint(x: -u.y, y: u.x)
                    parts.append((triangle((p.x + n.x * 5, p.y + n.y * 5), (p.x + u.x * 8, p.y + u.y * 8), (p.x - n.x * 5, p.y - n.y * 5)), .body))
                }
            }
        }
        if has(.tentacles) {
            for (x, curl) in [(-h + 2, -1.0), (-h + 14, -1.0), (h - 14, 1.0), (h - 2, 1.0)] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: x, y: bottom - 8))
                p.addCurve(to: CGPoint(x: x + curl * 14, y: bottom + 20), control1: CGPoint(x: x - curl * 6, y: bottom + 6), control2: CGPoint(x: x + curl * 2, y: bottom + 22))
                parts.append((p.copy(strokingWithWidth: 7, lineCap: .round, lineJoin: .round, miterLimit: 10), .body))
            }
        }
        return parts
    }

    // MARK: On the head (behind the body, so their base tucks in)

    var anatomyOnHead: [(CGPath, Paint)] {
        var parts: [(CGPath, Paint)] = []
        if has(.ossicones) {
            for s in [-1.0, 1.0] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: s * 10, y: c + 6))
                p.addLine(to: CGPoint(x: s * 14, y: c - 14))
                parts.append((p.copy(strokingWithWidth: 6, lineCap: .round, lineJoin: .round, miterLimit: 10), .horns))
                parts.append((circle(CGPoint(x: s * 14, y: c - 16), 5.5), .horns))
            }
        }
        if has(.eyeStalks) {
            for s in [-1.0, 1.0] {
                parts.append((circle(CGPoint(x: s * 20, y: c - 26), 8), .white))
                parts.append((circle(CGPoint(x: s * 20 + pose.look * 2.5, y: c - 25), 3.6), .eyes))
            }
        }
        if has(.crest) {
            parts.append((triangle((-6, c + 8), (10, c + 6), (-30, c - 24)), .accent))
        }
        if has(.propellers) {
            for s in [-1.0, 1.0] {
                parts.append((CGPath(ellipseIn: CGRect(x: s * 20 - 16, y: c - 18, width: 32, height: 6), transform: nil), .accent))
                parts.append((circle(CGPoint(x: s * 20, y: c - 15), 3), .outline))
            }
        }
        if has(.flame) {
            for (dx, height, width, paint) in [(-9.0, 26.0, 13.0, Paint.pattern), (9.0, 24.0, 12.0, .pattern), (0.0, 36.0, 17.0, .accent)] {
                let f = CGMutablePath()
                f.move(to: CGPoint(x: dx - width / 2, y: c + 6))
                f.addQuadCurve(to: CGPoint(x: dx + 2, y: c + 6 - height), control: CGPoint(x: dx - width, y: c - height * 0.4))
                f.addQuadCurve(to: CGPoint(x: dx + width / 2, y: c + 6), control: CGPoint(x: dx + width * 0.9, y: c - height * 0.3))
                f.closeSubpath()
                parts.append((f, paint))
            }
        }
        if has(.spout) {
            for (x, y, r) in [(0.0, c - 30, 5.5), (-9.0, c - 22, 4.5), (9.0, c - 22, 4.5), (-15.0, c - 12, 3.5), (15.0, c - 12, 3.5)] {
                parts.append((circle(CGPoint(x: x, y: y), r), .accent))
            }
        }
        return parts
    }

    var anatomyStrokes: [CGPath] {
        var strokes: [CGPath] = []
        if has(.eyeStalks) {
            for s in [-1.0, 1.0] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: s * 10, y: c + 4))
                p.addQuadCurve(to: CGPoint(x: s * 20, y: c - 19), control: CGPoint(x: s * 10, y: c - 10))
                strokes.append(p)
            }
        }
        if has(.propellers) {
            for s in [-1.0, 1.0] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: s * 10, y: c + 4))
                p.addLine(to: CGPoint(x: s * 20, y: c - 14))
                strokes.append(p)
            }
        }
        if has(.spout) {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 0, y: c + 2))
            p.addLine(to: CGPoint(x: 0, y: c - 24))
            strokes.append(p)
        }
        return strokes
    }

    // MARK: In front of the body

    var anatomyInFront: [(CGPath, Paint)] {
        var parts: [(CGPath, Paint)] = []
        if has(.leafCrown) {
            for a in [-165.0, -125, -90, -55, -15] {
                let r = CGAffineTransform(translationX: 0, y: c + 4).rotated(by: a * .pi / 180).translatedBy(x: 10, y: 0)
                parts.append((CGPath(ellipseIn: CGRect(x: -9, y: -4.5, width: 18, height: 9), transform: [r]), .accent))
            }
        }
        if has(.calyx) {
            for a in [-155.0, -120, -90, -60, -25] {
                let rad = a * .pi / 180
                let tip = CGPoint(x: 15 * cos(rad), y: c + 8 + 15 * sin(rad))
                let base = CGPoint(x: 4 * cos(rad), y: c + 8 + 4 * sin(rad)), n = CGPoint(x: -sin(rad) * 4.5, y: cos(rad) * 4.5)
                parts.append((triangle((base.x + n.x, base.y + n.y), (base.x - n.x, base.y - n.y), (tip.x, tip.y)), .pattern))
            }
            parts.append((circle(CGPoint(x: 0, y: c + 8), 5), .pattern))
        }
        if avatar.pattern == .drips {
            for (x, len) in [(-h * 0.6, 10.0), (-h * 0.2, 16.0), (h * 0.25, 8.0), (h * 0.62, 13.0)] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: x, y: bottom - 8))
                p.addLine(to: CGPoint(x: x, y: bottom + len))
                parts.append((p.copy(strokingWithWidth: 7, lineCap: .round, lineJoin: .round, miterLimit: 10), .body))
            }
        }
        if has(.trunk) {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 0, y: eyeY + 8))
            p.addCurve(to: CGPoint(x: 9, y: mouthY + 20), control1: CGPoint(x: -3, y: mouthY + 2), control2: CGPoint(x: 0, y: mouthY + 18))
            parts.append((p.copy(strokingWithWidth: 11, lineCap: .round, lineJoin: .round, miterLimit: 10), .body))
        }
        if has(.nostrils) {
            for s in [-1.0, 1.0] {
                parts.append((CGPath(ellipseIn: CGRect(x: s * 7 - 2, y: mouthY - 9, width: 4, height: 5), transform: nil), .outline))
            }
        }
        if has(.whiskers) {
            for s in [-1.0, 1.0] {
                for j in 0..<3 {
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: s * (cheekDX + 2), y: cheekY + CGFloat(j - 1) * 3))
                    p.addLine(to: CGPoint(x: s * (cheekDX + 17), y: cheekY - 4 + CGFloat(j - 1) * 5))
                    parts.append((p.copy(strokingWithWidth: 1.4, lineCap: .round, lineJoin: .round, miterLimit: 10), .outline))
                }
            }
        }
        if has(.beard) {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -16, y: mouthY + 4))
            p.addQuadCurve(to: CGPoint(x: 0, y: mouthY + 28), control: CGPoint(x: -15, y: mouthY + 24))
            p.addQuadCurve(to: CGPoint(x: 16, y: mouthY + 4), control: CGPoint(x: 15, y: mouthY + 24))
            p.addQuadCurve(to: CGPoint(x: -16, y: mouthY + 4), control: CGPoint(x: 0, y: mouthY + 10))
            p.closeSubpath()
            parts.append((p, .white))
        }
        if avatar.topper == .mushroomCap {
            let cap = CGMutablePath()
            cap.move(to: CGPoint(x: -h - 12, y: t + 16))
            cap.addCurve(to: CGPoint(x: 0, y: t - 30), control1: CGPoint(x: -h - 12, y: t - 10), control2: CGPoint(x: -h * 0.6, y: t - 30))
            cap.addCurve(to: CGPoint(x: h + 12, y: t + 16), control1: CGPoint(x: h * 0.6, y: t - 30), control2: CGPoint(x: h + 12, y: t - 10))
            cap.addQuadCurve(to: CGPoint(x: -h - 12, y: t + 16), control: CGPoint(x: 0, y: t + 24))
            cap.closeSubpath()
            parts.append((cap, .accent))
            for (x, y, r) in [(-h * 0.55, t - 2, 6.0), (h * 0.2, t - 16, 7.0), (h * 0.7, t + 4, 5.0), (-h * 0.1, t + 8, 4.0)] {
                parts.append((circle(CGPoint(x: x, y: y), r), .white))
            }
        }
        return parts
    }

    // MARK: Patterns (clipped to the body)

    /// Points spread over the body (u in -1…1 across, v in 0…1 from top to bottom), avoiding the face.
    private func scattered(_ points: [(CGFloat, CGFloat, CGFloat)]) -> [(CGPoint, CGFloat)] {
        points.compactMap { u, v, r in
            let p = CGPoint(x: u * h, y: t + v * (bottom - t))
            let onFace = abs(p.x) < h * 0.62 && p.y > eyeY - 12 && p.y < mouthY + 9
            return onFace ? nil : (p, r)
        }
    }

    private static let spread: [(CGFloat, CGFloat, CGFloat)] = [
        (-0.55, 0.12, 1), (0.1, 0.08, 0.8), (0.6, 0.18, 1), (-0.8, 0.45, 0.9), (0.82, 0.48, 1), (-0.45, 0.72, 1.1),
        (0.05, 0.8, 0.9), (0.5, 0.74, 1), (-0.15, 0.92, 0.7), (0.78, 0.86, 0.7), (-0.82, 0.84, 0.8), (0.3, 0.3, 0.6),
    ]

    var anatomyPattern: [CGPath] {
        func stroke(_ p: CGPath, _ w: CGFloat) -> CGPath { p.copy(strokingWithWidth: w, lineCap: .round, lineJoin: .round, miterLimit: 10) }
        switch avatar.pattern {
        case .cleft:
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 3, y: t + 3))
            p.addQuadCurve(to: CGPoint(x: 12, y: eyeY + 4), control: CGPoint(x: 16, y: t + 16))
            return [stroke(p, 2.4)]
        case .seeds:
            var seeds: [CGPath] = []
            for row in 0..<6 {
                let y = t + 12 + CGFloat(row) * 13
                for x in stride(from: -h + CGFloat(row % 2) * 7, through: h, by: 14) {
                    let p = CGPoint(x: x, y: y)
                    if abs(p.x) < h * 0.6 && p.y > eyeY - 12 && p.y < mouthY + 9 { continue }
                    seeds.append(CGPath(ellipseIn: CGRect(x: x - 1.6, y: y - 2.4, width: 3.2, height: 4.8), transform: nil))
                }
            }
            return seeds
        case .patches:
            return scattered(Figure.spread).enumerated().map { i, spot in blobPath(spot.0, 8 * spot.1, seed: i) }
        case .zebra:
            // Stripes everywhere except around the eyes and mouth.
            let face = CGPath(ellipseIn: CGRect(x: -h * 0.66, y: eyeY - 15, width: h * 1.32, height: mouthY - eyeY + 30), transform: nil)
            return stride(from: -h - 4, through: h + 4, by: 12).map { x in
                let p = CGMutablePath()
                p.move(to: CGPoint(x: x, y: t - 4))
                p.addQuadCurve(to: CGPoint(x: x + 5, y: bottom + 4), control: CGPoint(x: x + 12, y: (t + bottom) / 2))
                return stroke(p, 4.5).subtracting(face)
            }
        case .bandages:
            return (0..<8).map { i in
                let y = t + 6 + CGFloat(i) * 11
                let r = CGAffineTransform(translationX: 0, y: y).rotated(by: (i % 2 == 0 ? 6 : -5) * .pi / 180)
                return CGPath(rect: CGRect(x: -h - 12, y: -2.2, width: 2 * h + 24, height: 4.4), transform: [r])
            }
        case .stars:
            return scattered(Figure.spread).map { star($0.0, 4.5 * $0.1) }
        case .cracks:
            return [[(-0.6, 0.15), (-0.45, 0.28), (-0.58, 0.4)], [(0.55, 0.62), (0.4, 0.75), (0.56, 0.9)], [(0.2, 0.05), (0.32, 0.16)]].map { pts in
                let p = CGMutablePath()
                p.addLines(between: pts.map { CGPoint(x: $0.0 * h, y: t + $0.1 * (bottom - t)) })
                return stroke(p, 1.8)
            }
        case .chest:
            let band = CGPath(rect: CGRect(x: -h - 10, y: mouthY + 10, width: 2 * h + 20, height: 6), transform: nil)
            let sides = [-1.0, 1.0].map { s in CGPath(rect: CGRect(x: s * h * 0.62 - 3, y: t - 4, width: 6, height: bottom - t + 8), transform: nil) }
            let lock = CGPath(roundedRect: CGRect(x: -5, y: mouthY + 8, width: 10, height: 11), cornerWidth: 2, cornerHeight: 2, transform: nil)
            return [band] + sides + [lock]
        case .eggCrack:
            let p = CGMutablePath()
            let y = mouthY + 16
            p.addLines(between: stride(from: -h, through: h, by: 8).enumerated().map { i, x in CGPoint(x: x, y: y + (i % 2 == 0 ? -4 : 4)) })
            return [stroke(p, 2.4)]
        case .grooves:
            return (0..<4).map { i in
                let p = CGMutablePath()
                let y = mouthY + 14 + CGFloat(i) * 7
                p.move(to: CGPoint(x: -h * 0.45, y: y))
                p.addQuadCurve(to: CGPoint(x: h * 0.45, y: y), control: CGPoint(x: 0, y: y + 3))
                return stroke(p, 1.6)
            }
        case .rivets:
            return [(-1.0, t + 9), (1.0, t + 9), (-1.0, bottom - 9), (1.0, bottom - 9)].map { s, y in circle(CGPoint(x: s * (h - 9), y: y), 2.8) }
        case .glitch:
            return [(-0.9, 0.2, 0.7), (0.1, 0.35, 0.5), (-0.4, 0.78, 0.8), (0.3, 0.9, 0.6), (0.5, 0.12, 0.4)].map { u, v, w in
                CGPath(rect: CGRect(x: u * h, y: t + v * (bottom - t), width: w * h, height: 3.2), transform: nil)
            }
        case .swirl:
            // Little gusts of wind curling on the body.
            return [(-h * 0.55, bottom - 22, 9.0), (h * 0.55, bottom - 18, 8.0), (h * 0.1, bottom - 8, 6.0)].map { x, y, r in
                let p = CGMutablePath()
                p.addArc(center: CGPoint(x: x, y: y), radius: r, startAngle: .pi, endAngle: .pi * 2.6, clockwise: false)
                p.addArc(center: CGPoint(x: x + r * 0.25, y: y), radius: r * 0.5, startAngle: .pi * 0.6, endAngle: .pi * 1.9, clockwise: false)
                return stroke(p, 2.4)
            }
        case .marks:
            var marks: [CGPath] = []
            for s in [-1.0, 1.0] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: s * (eyeDX - 6), y: eyeY - 12))
                p.addQuadCurve(to: CGPoint(x: s * (eyeDX + 8), y: eyeY - 9), control: CGPoint(x: s * (eyeDX + 2), y: eyeY - 17))
                marks.append(stroke(p, 2.6))
                let cheek = CGMutablePath()
                cheek.move(to: CGPoint(x: s * (h - 4), y: cheekY - 2))
                cheek.addLine(to: CGPoint(x: s * (h - 14), y: cheekY + 1))
                marks.append(stroke(cheek, 2.4))
            }
            marks.append(circle(CGPoint(x: 0, y: eyeY - 18), 2.6))
            return marks
        default:
            return []
        }
    }

    // MARK: Helpers

    private func hexagon(_ center: CGPoint, _ r: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.addLines(between: (0..<6).map { i in
            let a = CGFloat(i) * .pi / 3
            return CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
        })
        p.closeSubpath()
        return p
    }

    private func star(_ center: CGPoint, _ r: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.addLines(between: (0..<8).map { i in
            let a = CGFloat(i) * .pi / 4 - .pi / 2
            let rr = i % 2 == 0 ? r : r * 0.38
            return CGPoint(x: center.x + rr * cos(a), y: center.y + rr * sin(a))
        })
        p.closeSubpath()
        return p
    }

    /// A lumpy spot (giraffe patches).
    private func blobPath(_ center: CGPoint, _ r: CGFloat, seed: Int) -> CGPath {
        let p = CGMutablePath()
        p.addLines(between: (0..<9).map { i in
            let a = CGFloat(i) / 9 * 2 * .pi
            let rr = r * (0.8 + 0.3 * PathTools.noise(seed, i, 7))
            return CGPoint(x: center.x + rr * cos(a), y: center.y + rr * sin(a))
        })
        p.closeSubpath()
        return p
    }
}
