import CoreGraphics
import Foundation
import Testing
@testable import Hopla

/// Every creature must be drawable in every move: no crash, and something actually visible.
struct DrawingTests {
    private static let clips: [(String, Clip)] = Exercise.all.map { ($0.id, $0.clip) } + [
        ("arrive", Moves.arrive), ("leave", Moves.leave), ("wave", Moves.wave), ("celebrate", Moves.celebrate),
        ("standUp", Moves.standUp), ("sitDown", Moves.sitDown), ("idle", Moves.idle),
    ]

    /// Paints one frame and returns how many pixels were covered.
    private func coverage(_ avatar: Avatar, _ pose: Pose, time: Double = 0.4) -> Int {
        let size = 100
        guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return 0 }
        ctx.translateBy(x: 0, y: CGFloat(size))
        ctx.scaleBy(x: 0.5, y: -0.5)
        Painter(figure: Figure(pose: pose, avatar: avatar), time: time, blink: false).paint(in: ctx)
        guard let data = ctx.data else { return 0 }
        let pixels = data.bindMemory(to: UInt8.self, capacity: size * size * 4)
        return (0..<(size * size)).filter { pixels[$0 * 4 + 3] > 20 }.count
    }

    @Test(arguments: Avatar.catalog)
    func everyCreatureDrawsEveryMove(_ avatar: Avatar) {
        for (name, clip) in Self.clips {
            for t in [0.0, clip.duration * 0.5] {
                let pose = clip.sample(t)
                guard pose.alpha > 0.5, pose.scale > 0.5 else { continue }   // entrance/exit fades
                #expect(coverage(avatar, pose) > 400, "\(avatar.id) is (almost) invisible in \(name)")
            }
        }
    }

    @Test func fiftyFiveCreaturesInElevenCollections() {
        #expect(Avatar.catalog.count == 55)
        #expect(Set(Avatar.catalog.map(\.id)).count == 55)
        for style in ArtStyle.allCases {
            #expect(Avatar.catalog.filter { $0.style == style }.count == 5, "\(style) needs 5 creatures")
        }
    }

    @Test func clipsSampleSafelyOutsideTheirRange() {
        for (_, clip) in Self.clips {
            for t in [-10.0, 0, clip.duration, clip.duration * 3.7, 1e9] {
                let p = clip.sample(t)
                #expect(p.x.isFinite && p.y.isFinite && p.tilt.isFinite && p.leftArm.shoulder.isFinite)
            }
        }
    }
}
