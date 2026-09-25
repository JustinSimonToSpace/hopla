import Foundation

/// Every animation Hopla knows. Exercises reuse these clips; skins never need to redraw them.
enum Moves {
    static let rest = Pose.neutral

    // MARK: Life

    static let idle = Clip(keys: [
        Key(t: 0, pose: rest),
        Key(t: 1.2, pose: rest.arms(16, 12).with { $0.stretch = 0.035; $0.bodyY = -1 }),
        Key(t: 2.4, pose: rest),
    ], loops: true)

    static let wave = Clip(keys: [
        Key(t: 0, pose: rest.with { $0.rightArm = Arm(150, 30); $0.look = 0.3; $0.mouth = .open }),
        Key(t: 0.4, pose: rest.with { $0.rightArm = Arm(155, -25); $0.look = 0.3; $0.mouth = .open; $0.tilt = -3 }),
        Key(t: 0.8, pose: rest.with { $0.rightArm = Arm(150, 30); $0.look = 0.3; $0.mouth = .open }),
    ], loops: true)

    /// Pops in with a little bounce.
    static let arrive = Clip(keys: [
        Key(t: 0, pose: rest.with { $0.scale = 0.1; $0.alpha = 0; $0.stretch = 0.2 }),
        Key(t: 0.28, pose: rest.arms(60, 20).with { $0.scale = 1.06; $0.y = -26; $0.stretch = 0.12; $0.eyes = .wide; $0.mouth = .open }, ease: .out),
        Key(t: 0.55, pose: rest.arms(30, 10).with { $0.stretch = -0.14; $0.bodyY = 4; $0.eyes = .happy; $0.mouth = .grin }),
        Key(t: 0.9, pose: rest.with { $0.mouth = .grin }),
    ], loops: false)

    /// "Reduce motion": appear and disappear with a simple fade, and cheer without jumping.
    static let fadeIn = Clip(keys: [Key(t: 0, pose: rest.with { $0.alpha = 0 }), Key(t: 0.5, pose: rest)], loops: false)
    static let fadeOut = Clip(keys: [Key(t: 0, pose: rest), Key(t: 0.6, pose: rest.with { $0.alpha = 0 })], loops: false)
    static let calmCheer = Clip(keys: [Key(t: 0, pose: rest.arms(150, 20).with { $0.eyes = .happy; $0.mouth = .grin })], loops: false)

    /// Crouches, jumps and vanishes.
    static let leave = Clip(keys: [
        Key(t: 0, pose: rest),
        Key(t: 0.25, pose: rest.arms(25, 10).with { $0.stretch = -0.14; $0.bodyY = 6; $0.eyes = .happy }),
        Key(t: 0.5, pose: rest.arms(160, 10).with { $0.y = -34; $0.stretch = 0.14; $0.scale = 0.95; $0.eyes = .happy; $0.mouth = .grin }, ease: .out),
        Key(t: 0.9, pose: rest.arms(170, 0).with { $0.y = -70; $0.scale = 0.05; $0.alpha = 0; $0.eyes = .happy }),
    ], loops: false)

    static let celebrate: Clip = {
        let base = rest.arms(150, 20).with { $0.eyes = .happy; $0.mouth = .grin }
        return Clip(keys: [
            Key(t: 0, pose: base),
            Key(t: 0.3, pose: base.arms(170, 5).with { $0.y = -24; $0.stretch = 0.1 }, ease: .out),
            Key(t: 0.55, pose: base.arms(140, 25).with { $0.stretch = -0.1; $0.bodyY = 3 }),
            Key(t: 0.9, pose: base),
        ], loops: true)
    }()

    // MARK: Exercises

    static let reachUp: Clip = {
        let down = rest.arms(20, 10)
        let up = rest.arms(168, 8).with { $0.stretch = 0.09; $0.bodyY = -4; $0.eyes = .closed }
        return Clip(keys: [
            Key(t: 0, pose: down),
            Key(t: 1.4, pose: up),
            Key(t: 3.0, pose: up.arms(172, 4).with { $0.stretch = 0.1 }),
            Key(t: 4.4, pose: down),
        ], loops: true)
    }()

    static let sideBend: Clip = {
        let up = rest.arms(165, 12)
        let left = up.with { $0.tilt = -20; $0.eyes = .closed; $0.look = -1 }
        let right = up.with { $0.tilt = 20; $0.eyes = .closed; $0.look = 1 }
        return Clip(keys: [
            Key(t: 0, pose: up),
            Key(t: 1.6, pose: left),
            Key(t: 3.2, pose: left),
            Key(t: 4.0, pose: up),
            Key(t: 5.6, pose: right),
            Key(t: 7.2, pose: right),
            Key(t: 8.0, pose: up),
        ], loops: true)
    }()

    static let shrug: Clip = {
        let down = rest.arms(10, 5)
        let up = rest.arms(6, 5).with { $0.shrug = 9; $0.bodyY = -2; $0.eyes = .closed; $0.mouth = .flat }
        return Clip(keys: [
            Key(t: 0, pose: down),
            Key(t: 0.6, pose: up),
            Key(t: 1.1, pose: up),
            Key(t: 1.8, pose: down),
        ], loops: true)
    }()

    static let neck: Clip = {
        let base = rest.arms(10, 6).with { $0.eyes = .closed }
        return Clip(keys: [
            Key(t: 0, pose: base),
            Key(t: 1.5, pose: base.with { $0.tilt = -14; $0.look = -1 }),
            Key(t: 2.5, pose: base.with { $0.tilt = -14; $0.look = -1 }),
            Key(t: 3.0, pose: base),
            Key(t: 4.5, pose: base.with { $0.tilt = 14; $0.look = 1 }),
            Key(t: 5.5, pose: base.with { $0.tilt = 14; $0.look = 1 }),
            Key(t: 6.0, pose: base),
        ], loops: true)
    }()

    /// Arms straight out to the sides, drawing small circles.
    static let armCircles: Clip = {
        let base = rest.with { $0.mouth = .o }
        let steps = 8
        return Clip(keys: (0...steps).map { i in
            let a = Double(i) / Double(steps) * 2 * .pi
            return Key(t: Double(i) * 0.15, pose: base.arms(90 + 16 * sin(a), 12 * cos(a)), ease: .linear)
        }, loops: true)
    }()

    static let march: Clip = {
        let left = rest.with {
            $0.leftFoot = Foot(0, 16); $0.leftArm = Arm(8, 5); $0.rightArm = Arm(40, 20)
            $0.bodyY = -2; $0.mouth = .open
        }
        let right = rest.with {
            $0.rightFoot = Foot(0, 16); $0.rightArm = Arm(8, 5); $0.leftArm = Arm(40, 20)
            $0.bodyY = -2; $0.mouth = .open
        }
        return Clip(keys: [
            Key(t: 0, pose: left),
            Key(t: 0.5, pose: right),
            Key(t: 1.0, pose: left),
        ], loops: true)
    }()

    static let squat: Clip = {
        let up = rest.arms(15, 8)
        let down = rest.arms(85, 0).with {
            $0.bodyY = 18; $0.stretch = -0.04; $0.mouth = .o
            $0.leftFoot = Foot(4, 0); $0.rightFoot = Foot(4, 0)
        }
        return Clip(keys: [
            Key(t: 0, pose: up),
            Key(t: 1.1, pose: down),
            Key(t: 1.6, pose: down),
            Key(t: 2.6, pose: up),
        ], loops: true)
    }()

    static let breathe: Clip = {
        let low = rest.arms(25, 10).with { $0.eyes = .closed }
        let high = rest.arms(150, 25).with { $0.stretch = 0.07; $0.bodyY = -3; $0.eyes = .closed; $0.mouth = .o }
        return Clip(keys: [Key(t: 0, pose: low), Key(t: 3, pose: high), Key(t: 3.6, pose: high), Key(t: 6.6, pose: low), Key(t: 7, pose: low)], loops: true)
    }()

    /// One arm across the chest, the other hand pressing it. Then the other side.
    static let crossArm: Clip = {
        let right = rest.with { $0.rightArm = Arm(-80, 5); $0.leftArm = Arm(-30, -75); $0.eyes = .closed; $0.look = 0.6 }
        let left = rest.with { $0.leftArm = Arm(-80, 5); $0.rightArm = Arm(-30, -75); $0.eyes = .closed; $0.look = -0.6 }
        return alternating(right, left)
    }()

    /// Hand behind the head, the other hand pulling the elbow.
    static let triceps: Clip = {
        let right = rest.with { $0.rightArm = Arm(165, 140); $0.leftArm = Arm(150, 55); $0.eyes = .closed; $0.tilt = -4 }
        let left = rest.with { $0.leftArm = Arm(165, 140); $0.rightArm = Arm(150, 55); $0.eyes = .closed; $0.tilt = 4 }
        return alternating(right, left)
    }()

    static let wristShake = Clip(keys: [
        Key(t: 0, pose: rest.arms(70, 25).with { $0.mouth = .open }, ease: .linear),
        Key(t: 0.18, pose: rest.arms(70, 55).with { $0.mouth = .open; $0.bodyY = -1 }, ease: .linear),
        Key(t: 0.36, pose: rest.arms(70, 25).with { $0.mouth = .open }, ease: .linear),
    ], loops: true)

    static let twist: Clip = {
        let center = rest.arms(40, 20)
        let right = rest.with { $0.rightArm = Arm(95, 0); $0.leftArm = Arm(-55, -35); $0.tilt = 4; $0.look = 1 }
        let left = rest.with { $0.leftArm = Arm(95, 0); $0.rightArm = Arm(-55, -35); $0.tilt = -4; $0.look = -1 }
        return Clip(keys: [Key(t: 0, pose: center), Key(t: 1.2, pose: right), Key(t: 2.4, pose: right), Key(t: 3, pose: center),
                           Key(t: 4.2, pose: left), Key(t: 5.4, pose: left), Key(t: 6, pose: center)], loops: true)
    }()

    /// Hand over the brow, looking far away on one side then the other.
    static let farSight: Clip = {
        let base = rest.with { $0.rightArm = Arm(150, 115); $0.eyes = .wide; $0.mouth = .o }
        return Clip(keys: [Key(t: 0, pose: base.with { $0.look = -1 }), Key(t: 2.5, pose: base.with { $0.look = -1 }),
                           Key(t: 4, pose: base.with { $0.look = 1 }), Key(t: 6.5, pose: base.with { $0.look = 1 }),
                           Key(t: 8, pose: base.with { $0.look = -1 })], loops: true)
    }()

    static let calfRaise: Clip = {
        let down = rest.arms(20, 10)
        let up = rest.arms(28, 12).with { $0.y = -7; $0.stretch = 0.05 }
        return Clip(keys: [Key(t: 0, pose: down), Key(t: 0.6, pose: up), Key(t: 0.9, pose: up), Key(t: 1.6, pose: down)], loops: true)
    }()

    static let kneeHug: Clip = {
        let right = rest.arms(-15, -40).with { $0.rightFoot = Foot(-6, 28); $0.bodyY = -2; $0.eyes = .happy }
        let left = rest.arms(-15, -40).with { $0.leftFoot = Foot(-6, 28); $0.bodyY = -2; $0.eyes = .happy }
        return Clip(keys: [Key(t: 0, pose: rest), Key(t: 0.8, pose: right), Key(t: 1.8, pose: right), Key(t: 2.2, pose: rest),
                           Key(t: 3.0, pose: left), Key(t: 4.0, pose: left), Key(t: 4.4, pose: rest)], loops: true)
    }()

    /// Hands on the hips, drawing circles with the pelvis.
    static let hipCircles: Clip = {
        let base = rest.arms(40, -110)
        return Clip(keys: [Key(t: 0, pose: base.with { $0.tilt = -7 }), Key(t: 0.6, pose: base.with { $0.bodyY = 3 }),
                           Key(t: 1.2, pose: base.with { $0.tilt = 7 }), Key(t: 1.8, pose: base.with { $0.bodyY = -3 }),
                           Key(t: 2.4, pose: base.with { $0.tilt = -7 })], loops: true)
    }()

    static let jumpingJacks: Clip = {
        let closed = rest.arms(15, 8)
        return Clip(keys: [
            Key(t: 0, pose: closed),
            Key(t: 0.25, pose: rest.arms(120, 10).with { $0.y = -12; $0.leftFoot = Foot(10, 0); $0.rightFoot = Foot(10, 0); $0.mouth = .open }, ease: .out),
            Key(t: 0.5, pose: rest.arms(170, 10).with { $0.leftFoot = Foot(16, 0); $0.rightFoot = Foot(16, 0); $0.stretch = -0.05; $0.mouth = .grin }),
            Key(t: 0.75, pose: rest.arms(90, 10).with { $0.y = -10; $0.leftFoot = Foot(8, 0); $0.rightFoot = Foot(8, 0) }, ease: .out),
            Key(t: 1.0, pose: closed),
        ], loops: true)
    }()

    static let shadowBoxing: Clip = {
        let guardPose = rest.arms(35, 135).with { $0.mouth = .flat; $0.bodyY = 1 }
        return Clip(keys: [
            Key(t: 0, pose: guardPose),
            Key(t: 0.2, pose: guardPose.with { $0.rightArm = Arm(88, 0); $0.tilt = 3; $0.mouth = .open; $0.bodyY = -1 }, ease: .out),
            Key(t: 0.4, pose: guardPose),
            Key(t: 0.6, pose: guardPose.with { $0.leftArm = Arm(88, 0); $0.tilt = -3; $0.mouth = .open; $0.bodyY = -1 }, ease: .out),
            Key(t: 0.8, pose: guardPose),
        ], loops: true)
    }()

    /// Getting up from the chair: from a crouch to standing tall, arms rising.
    static let standUp: Clip = {
        let low = rest.arms(40, 30).with { $0.bodyY = 14; $0.stretch = -0.06; $0.mouth = .open }
        let up = rest.arms(150, 20).with { $0.stretch = 0.06; $0.bodyY = -3; $0.eyes = .happy; $0.mouth = .grin }
        return Clip(keys: [Key(t: 0, pose: low), Key(t: 0.8, pose: up, ease: .out), Key(t: 1.5, pose: rest), Key(t: 2.2, pose: low)], loops: true)
    }()

    /// Sitting back down: a slow, comfy crouch.
    static let sitDown: Clip = {
        let seat = rest.arms(55, 20).with { $0.bodyY = 12; $0.stretch = -0.05; $0.eyes = .happy }
        return Clip(keys: [Key(t: 0, pose: rest), Key(t: 1.0, pose: seat), Key(t: 1.8, pose: seat), Key(t: 2.4, pose: rest)], loops: true)
    }()

    /// Right side, then left side, with a short rest in between (12 s loop).
    private static func alternating(_ right: Pose, _ left: Pose) -> Clip {
        Clip(keys: [Key(t: 0, pose: rest), Key(t: 1.2, pose: right), Key(t: 5, pose: right), Key(t: 6, pose: rest),
                    Key(t: 7.2, pose: left), Key(t: 11, pose: left), Key(t: 12, pose: rest)], loops: true)
    }

    /// Key poses used by `--render` to check the art.
    static let showcase: [(String, Pose)] = [
        ("Repos", idle.sample(0)),
        ("Coucou", wave.sample(0.2)),
        ("Bras au ciel", reachUp.sample(2)),
        ("Penché", sideBend.sample(2.4)),
        ("Moulinet", armCircles.sample(0.5)),
        ("Marche", march.sample(0)),
        ("Squat", squat.sample(1.3)),
        ("Bravo", celebrate.sample(0.3)),
    ]
}
