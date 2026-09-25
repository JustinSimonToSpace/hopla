import CoreGraphics

/// Small geometry helpers for hand-made looks: sampling, roughening and deterministic noise.
enum PathTools {
    /// Deterministic noise in -1...1.
    static func noise(_ a: Int, _ b: Int, _ c: Int) -> CGFloat {
        var h = (UInt64(truncatingIfNeeded: a) &* 0x9E37_79B9_7F4A_7C15)
            ^ (UInt64(truncatingIfNeeded: b) &* 0xC2B2_AE3D_27D4_EB4F)
            ^ (UInt64(truncatingIfNeeded: c) &* 0x1656_67B1_9E37_79F9)
        h ^= h >> 29
        h = h &* 0xBF58_476D_1CE4_E5B9
        h ^= h >> 32
        return CGFloat(h & 0xFFFF) / 32767.5 - 1
    }

    private static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    private static func quad(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        lerp(lerp(a, c, t), lerp(c, b, t), t)
    }

    private static func cubic(_ a: CGPoint, _ c1: CGPoint, _ c2: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        lerp(quad(a, c1, c2, t), quad(c1, c2, b, t), t)
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(b.x - a.x, b.y - a.y) }

    /// Flattens a path into polylines, one point every `step` units.
    static func polylines(_ path: CGPath, step: CGFloat) -> [(points: [CGPoint], closed: Bool)] {
        var result: [(points: [CGPoint], closed: Bool)] = []
        var current: [CGPoint] = []
        var start = CGPoint.zero, last = CGPoint.zero

        func flush(_ closed: Bool) {
            if current.count > 1 { result.append((current, closed)) }
            current = []
        }
        func sample(_ length: CGFloat, _ point: (CGFloat) -> CGPoint) {
            let n = max(1, Int(length / step))
            for i in 1...n { current.append(point(CGFloat(i) / CGFloat(n))) }
        }

        path.applyWithBlock { (element: UnsafePointer<CGPathElement>) -> Void in
            let e = element.pointee
            switch e.type {
            case .moveToPoint:
                flush(false)
                start = e.points[0]
                last = start
                current = [start]
            case .addLineToPoint:
                let a = last, b = e.points[0]
                sample(distance(a, b)) { lerp(a, b, $0) }
                last = b
            case .addQuadCurveToPoint:
                let a = last, c = e.points[0], b = e.points[1]
                sample(distance(a, c) + distance(c, b)) { quad(a, c, b, $0) }
                last = b
            case .addCurveToPoint:
                let a = last, c1 = e.points[0], c2 = e.points[1], b = e.points[2]
                sample(distance(a, c1) + distance(c1, c2) + distance(c2, b)) { cubic(a, c1, c2, b, $0) }
                last = b
            case .closeSubpath:
                let a = last, b = start
                if distance(a, b) > 0.5 { sample(distance(a, b)) { lerp(a, b, $0) } }
                flush(true)
                last = start
            @unknown default:
                break
            }
        }
        flush(false)
        return result
    }

    /// Wobbles a path, like a hand-drawn line. The same seed always gives the same wobble.
    static func roughen(_ path: CGPath, amplitude: CGFloat, seed: Int, step: CGFloat = 5) -> CGPath {
        guard amplitude > 0 else { return path }
        let out = CGMutablePath()
        for (k, line) in polylines(path, step: step).enumerated() {
            let pts = line.points.enumerated().map { i, p in
                CGPoint(x: p.x + noise(seed, k * 1000 + i, 1) * amplitude, y: p.y + noise(seed, k * 1000 + i, 2) * amplitude)
            }
            out.addLines(between: pts)
            if line.closed { out.closeSubpath() }
        }
        return out
    }
}
