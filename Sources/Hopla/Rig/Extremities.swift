import CoreGraphics

/// Hands and feet. Each kind is a small set of shapes in its own local space:
/// - hands: origin at the wrist, +y pointing along the forearm (away from the elbow);
/// - feet: origin at the ankle, +x pointing outward, y down.
/// Shapes are built once and cached; the painter places them on each frame.
enum Extremity: String, Codable {
    case ball, mitten, paw, claw, glove, threeFinger, talon, stubby, splayed, pincer, hoof, shoe, sneaker, boot
}

struct ExtremityPart {
    let path: CGPath
    let paint: Paint
    var outlined = true
}

extension ArtStyle {
    var defaultHand: Extremity {
        switch self {
        case .classic: return .ball
        case .ligneClaire: return .paw
        case .sketch: return .claw
        case .rubberHose: return .glove
        case .cartoon: return .threeFinger
        case .pixel: return .talon
        case .lcd: return .mitten
        case .clay: return .stubby
        case .watercolor: return .splayed
        case .neon: return .pincer
        case .paper: return .hoof
        }
    }

    var defaultFoot: Extremity {
        switch self {
        case .classic, .lcd: return .ball
        case .ligneClaire: return .paw
        case .sketch: return .claw
        case .rubberHose: return .shoe
        case .cartoon: return .sneaker
        case .pixel: return .talon
        case .clay: return .stubby
        case .watercolor: return .splayed
        case .neon: return .boot
        case .paper: return .hoof
        }
    }
}

enum Extremities {
    private static var handCache: [Extremity: [ExtremityPart]] = [:]
    private static var footCache: [Extremity: [ExtremityPart]] = [:]

    static func hand(_ kind: Extremity) -> [ExtremityPart] {
        if let cached = handCache[kind] { return cached }
        let parts = makeHand(kind)
        handCache[kind] = parts
        return parts
    }

    static func foot(_ kind: Extremity) -> [ExtremityPart] {
        if let cached = footCache[kind] { return cached }
        let parts = makeFoot(kind)
        footCache[kind] = parts
        return parts
    }

    // MARK: Hands (+y along the forearm)

    private static func makeHand(_ kind: Extremity) -> [ExtremityPart] {
        switch kind {
        case .ball, .shoe, .sneaker, .boot:
            return [ExtremityPart(path: circle(0, 0, 6.5), paint: .hand)]
        case .mitten:
            return [ExtremityPart(path: union([ellipse(0, 6, 12, 14), ellipse(5.5, 3, 5.5, 8, rotation: -25)]), paint: .hand)]
        case .paw:
            return [
                ExtremityPart(path: union([ellipse(0, 6, 14, 12), circle(-4.6, 11.2, 3.3), circle(0, 12.6, 3.3), circle(4.6, 11.2, 3.3)]), paint: .hand),
                ExtremityPart(path: ellipse(0, 5.5, 6, 4.5), paint: .cheeks, outlined: false),
                ExtremityPart(path: union([circle(-4.4, 11.6, 1.4), circle(0, 13.1, 1.4), circle(4.4, 11.6, 1.4)]), paint: .cheeks, outlined: false),
            ]
        case .claw:
            let claws = [-32.0, 0, 32].map { spike(from: 5, to: 14.5, angle: $0, center: CGPoint(x: 0, y: 4), width: 2.8) }
            return [ExtremityPart(path: union(claws), paint: .horns), ExtremityPart(path: ellipse(0, 4, 13, 12), paint: .hand)]
        case .glove:
            return [
                ExtremityPart(path: union([circle(0, 8, 7.2), circle(-4.6, 14, 3.2), circle(0, 15.5, 3.2), circle(4.6, 14, 3.2),
                                           ellipse(7, 6, 5, 8.5, rotation: -30)]), paint: .hand),
                ExtremityPart(path: CGPath(roundedRect: CGRect(x: -7, y: -2.5, width: 14, height: 6), cornerWidth: 2.5, cornerHeight: 2.5, transform: nil), paint: .hand),
            ]
        case .threeFinger:
            let fingers = [-38.0, 0, 38].flatMap { a -> [CGPath] in
                let tip = polar(CGPoint(x: 0, y: 4), 12, a)
                return [capsule(CGPoint(x: 0, y: 4), tip, 4.4), circle(tip.x, tip.y, 2.7)]
            }
            return [ExtremityPart(path: union([circle(0, 4, 5.5)] + fingers), paint: .hand)]
        case .talon:
            let talons = [-35.0, 0, 35].map { hook(center: CGPoint(x: 0, y: 3), angle: $0, from: 3.5, to: 13) }
            return [ExtremityPart(path: union(talons), paint: .horns), ExtremityPart(path: ellipse(0, 3, 10, 9), paint: .hand)]
        case .stubby:
            return [
                ExtremityPart(path: ellipse(0, 6, 15, 13), paint: .hand),
                ExtremityPart(path: union([ellipse(-4.6, 11, 4.2, 3.4), ellipse(0, 12.2, 4.2, 3.4), ellipse(4.6, 11, 4.2, 3.4)]), paint: .horns, outlined: false),
            ]
        case .splayed:
            let fingers = [-50.0, -17, 17, 50].flatMap { a -> [CGPath] in
                let tip = polar(CGPoint(x: 0, y: 3), 9, a)
                return [capsule(CGPoint(x: 0, y: 3), tip, 2.8), circle(tip.x, tip.y, 1.9)]
            }
            return [ExtremityPart(path: union([circle(0, 3, 4.3)] + fingers), paint: .hand)]
        case .pincer:
            // Two open jaws around a small hub, like a robot gripper.
            let jaws = [-1.0, 1.0].map { s -> CGPath in
                let p = CGMutablePath()
                p.move(to: CGPoint(x: 1.5 * s, y: 2.5))
                p.addQuadCurve(to: CGPoint(x: 8.5 * s, y: 9), control: CGPoint(x: 9.5 * s, y: 2.5))
                p.addQuadCurve(to: CGPoint(x: 5 * s, y: 17), control: CGPoint(x: 9 * s, y: 15.5))
                return p.copy(strokingWithWidth: 2.8, lineCap: .round, lineJoin: .round, miterLimit: 10)
            }
            return [ExtremityPart(path: union([circle(0, 1.5, 3.2)] + jaws), paint: .hand)]
        case .hoof:
            let hoof = CGMutablePath()
            hoof.move(to: CGPoint(x: -5.5, y: 0))
            hoof.addLine(to: CGPoint(x: 5.5, y: 0))
            hoof.addLine(to: CGPoint(x: 7, y: 11))
            hoof.addQuadCurve(to: CGPoint(x: -7, y: 11), control: CGPoint(x: 0, y: 13))
            hoof.closeSubpath()
            return [ExtremityPart(path: hoof, paint: .hand), ExtremityPart(path: capsule(CGPoint(x: 0, y: 6.5), CGPoint(x: 0, y: 12), 1.1), paint: .outline, outlined: false)]
        }
    }

    // MARK: Feet (+x outward, y down)

    private static func makeFoot(_ kind: Extremity) -> [ExtremityPart] {
        switch kind {
        case .ball, .mitten, .glove, .threeFinger, .pincer:
            return [ExtremityPart(path: ellipse(3, 1, 20, 11), paint: .foot)]
        case .paw:
            return [
                ExtremityPart(path: union([ellipse(3, 0, 20, 11), circle(11, -3.5, 3.4), circle(13.5, 0.5, 3.4), circle(11.5, 4.5, 3)]), paint: .foot),
                ExtremityPart(path: union([circle(11.6, -3.3, 1.3), circle(14, 0.7, 1.3), circle(12, 4.4, 1.2)]), paint: .cheeks, outlined: false),
            ]
        case .claw:
            let claws = [(-4.0, -30.0), (1.0, 0.0), (5.5, 30.0)].map { y, a in
                spike(from: 0, to: 7.5, angle: 90 - a, center: CGPoint(x: 11, y: y), width: 2.6)
            }
            return [ExtremityPart(path: union(claws), paint: .horns), ExtremityPart(path: ellipse(3, 1, 19, 11), paint: .foot)]
        case .shoe:
            return [
                ExtremityPart(path: union([ellipse(8, -0.5, 24, 15), CGPath(roundedRect: CGRect(x: -9, y: -5, width: 14, height: 11), cornerWidth: 4, cornerHeight: 4, transform: nil)]), paint: .foot),
                ExtremityPart(path: ellipse(12, -3.5, 6, 3), paint: .white, outlined: false),
            ]
        case .sneaker:
            return [
                ExtremityPart(path: ellipse(4, -0.5, 24, 13), paint: .foot),
                ExtremityPart(path: CGPath(roundedRect: CGRect(x: -7.5, y: 3, width: 24, height: 3.6), cornerWidth: 1.8, cornerHeight: 1.8, transform: nil), paint: .white, outlined: false),
            ]
        case .talon:
            let tips = [CGPoint(x: 12, y: 1), CGPoint(x: 8.5, y: 6), CGPoint(x: -4, y: 5.5)]
            let toes = tips.map { capsule(CGPoint(x: 0, y: 0), $0, 4.2) }
            let claws = tips.map { tip -> CGPath in
                let a = atan2(tip.x, tip.y) * 180 / .pi
                return spike(from: 0, to: 4.5, angle: a, center: tip, width: 1.8)
            }
            return [ExtremityPart(path: union(claws), paint: .horns), ExtremityPart(path: union([circle(0, 0, 4)] + toes), paint: .foot)]
        case .stubby:
            return [
                ExtremityPart(path: ellipse(3, -0.5, 22, 14), paint: .foot),
                ExtremityPart(path: union([ellipse(-2.5, 4.4, 5, 3), ellipse(3, 5.4, 5, 3), ellipse(8.5, 4.4, 5, 3)]), paint: .horns, outlined: false),
            ]
        case .splayed:
            let tips = [CGPoint(x: 11, y: -3), CGPoint(x: 12.5, y: 1), CGPoint(x: 10.5, y: 5), CGPoint(x: 6, y: 7)]
            let toes = tips.flatMap { [capsule(CGPoint(x: 2, y: 0), $0, 2.7), circle($0.x, $0.y, 1.8)] }
            return [ExtremityPart(path: union([circle(2, 0, 4)] + toes), paint: .foot)]
        case .boot:
            return [
                ExtremityPart(path: CGPath(roundedRect: CGRect(x: -8, y: -5, width: 22, height: 11), cornerWidth: 3, cornerHeight: 3, transform: nil), paint: .foot),
                ExtremityPart(path: CGPath(rect: CGRect(x: -7, y: 3.5, width: 20, height: 2), transform: nil), paint: .outline, outlined: false),
            ]
        case .hoof:
            let hoof = CGMutablePath()
            hoof.move(to: CGPoint(x: -7, y: -5))
            hoof.addLine(to: CGPoint(x: 8, y: -5))
            hoof.addLine(to: CGPoint(x: 9.5, y: 6))
            hoof.addQuadCurve(to: CGPoint(x: -8.5, y: 6), control: CGPoint(x: 0.5, y: 8))
            hoof.closeSubpath()
            return [ExtremityPart(path: hoof, paint: .foot), ExtremityPart(path: capsule(CGPoint(x: 0.5, y: 1), CGPoint(x: 0.5, y: 7), 1.1), paint: .outline, outlined: false)]
        }
    }

    // MARK: Primitives

    private static func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r), transform: nil)
    }

    private static func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, rotation: CGFloat = 0) -> CGPath {
        var t = CGAffineTransform(translationX: x, y: y).rotated(by: rotation * .pi / 180)
        return CGPath(ellipseIn: CGRect(x: -w / 2, y: -h / 2, width: w, height: h), transform: &t)
    }

    private static func capsule(_ a: CGPoint, _ b: CGPoint, _ width: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: a)
        p.addLine(to: b)
        return p.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 10)
    }

    /// Point at `radius` from `center`, `degrees` away from +y.
    private static func polar(_ center: CGPoint, _ radius: CGFloat, _ degrees: CGFloat) -> CGPoint {
        let a = degrees * .pi / 180
        return CGPoint(x: center.x + sin(a) * radius, y: center.y + cos(a) * radius)
    }

    /// A pointed claw from `from` to `to` along a direction.
    private static func spike(from r0: CGFloat, to r1: CGFloat, angle: CGFloat, center: CGPoint, width: CGFloat) -> CGPath {
        let a = angle * .pi / 180
        let dir = CGPoint(x: sin(a), y: cos(a)), n = CGPoint(x: cos(a), y: -sin(a))
        let base = CGPoint(x: center.x + dir.x * r0, y: center.y + dir.y * r0)
        let tip = CGPoint(x: center.x + dir.x * r1, y: center.y + dir.y * r1)
        let p = CGMutablePath()
        p.addLines(between: [CGPoint(x: base.x + n.x * width, y: base.y + n.y * width), tip,
                             CGPoint(x: base.x - n.x * width, y: base.y - n.y * width)])
        p.closeSubpath()
        return p
    }

    /// A curved talon, hooking inward.
    private static func hook(center: CGPoint, angle: CGFloat, from r0: CGFloat, to r1: CGFloat) -> CGPath {
        let a = angle * .pi / 180
        let dir = CGPoint(x: sin(a), y: cos(a)), n = CGPoint(x: cos(a), y: -sin(a))
        func at(_ r: CGFloat, _ side: CGFloat) -> CGPoint {
            CGPoint(x: center.x + dir.x * r + n.x * side, y: center.y + dir.y * r + n.y * side)
        }
        let p = CGMutablePath()
        p.move(to: at(r0, 3))
        p.addQuadCurve(to: at(r1, -2.5), control: at(r1 - 2, 3.5))
        p.addQuadCurve(to: at(r0, -3), control: at((r0 + r1) / 2, -1))
        p.closeSubpath()
        return p
    }

    private static func union(_ paths: [CGPath]) -> CGPath {
        paths.dropFirst().reduce(paths[0]) { $0.union($1) }
    }
}
