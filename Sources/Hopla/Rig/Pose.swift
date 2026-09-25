import Foundation

/// One arm, forward kinematics. Angles in degrees.
/// `shoulder`: 0 = hanging straight down, 90 = pointing sideways, 180 = straight up (always "outward").
/// `elbow`: extra rotation of the forearm relative to the upper arm, same direction convention.
struct Arm {
    var shoulder: Double
    var elbow: Double
    init(_ shoulder: Double, _ elbow: Double) {
        self.shoulder = shoulder
        self.elbow = elbow
    }
}

/// One foot, solved with inverse kinematics from the hip.
/// `dx`: sideways offset from the resting stance (+ = outward), `lift`: height above the ground.
struct Foot {
    var dx: Double
    var lift: Double
    init(_ dx: Double = 0, _ lift: Double = 0) {
        self.dx = dx
        self.lift = lift
    }
}

enum Eyes { case open, closed, happy, wide }
enum Mouth { case smile, grin, open, o, flat }

/// A full-body pose of the character. Every animation is a sequence of poses.
struct Pose {
    var x = 0.0            // whole character offset (hops, entrances)
    var y = 0.0
    var scale = 1.0        // whole character scale, anchored at the feet
    var alpha = 1.0
    var bodyY = 0.0        // body offset relative to the feet (+ = lower, e.g. squats)
    var tilt = 0.0         // body lean in degrees, pivoting at the hips (+ = leans right)
    var stretch = 0.0      // squash & stretch (+ = taller and thinner)
    var shrug = 0.0        // lifts the shoulders
    var leftArm = Arm(12, 8)
    var rightArm = Arm(12, 8)
    var leftFoot = Foot()
    var rightFoot = Foot()
    var look = 0.0         // pupils, -1 (left) ... 1 (right)
    var eyes: Eyes = .open
    var mouth: Mouth = .smile

    static let neutral = Pose()

    func with(_ edit: (inout Pose) -> Void) -> Pose {
        var copy = self
        edit(&copy)
        return copy
    }

    /// Sets both arms at once (mirrored, since angles are expressed "outward").
    func arms(_ shoulder: Double, _ elbow: Double) -> Pose {
        with { $0.leftArm = Arm(shoulder, elbow); $0.rightArm = Arm(shoulder, elbow) }
    }

    static func lerp(_ a: Pose, _ b: Pose, _ t: Double) -> Pose {
        func m(_ x: Double, _ y: Double) -> Double { x + (y - x) * t }
        func arm(_ x: Arm, _ y: Arm) -> Arm { Arm(m(x.shoulder, y.shoulder), m(x.elbow, y.elbow)) }
        func foot(_ x: Foot, _ y: Foot) -> Foot { Foot(m(x.dx, y.dx), m(x.lift, y.lift)) }
        var p = Pose()
        p.x = m(a.x, b.x)
        p.y = m(a.y, b.y)
        p.scale = m(a.scale, b.scale)
        p.alpha = m(a.alpha, b.alpha)
        p.bodyY = m(a.bodyY, b.bodyY)
        p.tilt = m(a.tilt, b.tilt)
        p.stretch = m(a.stretch, b.stretch)
        p.shrug = m(a.shrug, b.shrug)
        p.leftArm = arm(a.leftArm, b.leftArm)
        p.rightArm = arm(a.rightArm, b.rightArm)
        p.leftFoot = foot(a.leftFoot, b.leftFoot)
        p.rightFoot = foot(a.rightFoot, b.rightFoot)
        p.look = m(a.look, b.look)
        p.eyes = t < 0.5 ? a.eyes : b.eyes
        p.mouth = t < 0.5 ? a.mouth : b.mouth
        return p
    }
}

enum Ease {
    case linear, inOut, out

    func apply(_ t: Double) -> Double {
        switch self {
        case .linear: return t
        case .inOut: return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
        case .out: return 1 - pow(1 - t, 3)
        }
    }
}

struct Key {
    var t: Double
    var pose: Pose
    var ease: Ease = .inOut
}

/// A keyframed animation. Looping clips should end on the same pose they start with.
struct Clip {
    var keys: [Key]
    var loops: Bool

    var duration: Double { keys.last?.t ?? 0 }

    func sample(_ time: Double) -> Pose {
        guard let first = keys.first else { return .neutral }
        guard keys.count > 1, duration > 0 else { return first.pose }
        let t = loops ? fmod(max(time, 0), duration) : min(max(time, 0), duration)
        for i in 1..<keys.count where t <= keys[i].t {
            let a = keys[i - 1], b = keys[i]
            let span = b.t - a.t
            let local = span > 0 ? (t - a.t) / span : 1
            return Pose.lerp(a.pose, b.pose, b.ease.apply(local))
        }
        return keys[keys.count - 1].pose
    }
}
