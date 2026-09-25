import SwiftUI

/// Draws an avatar in a given pose, in a 200×200 design space scaled to the view size.
struct CharacterView: View {
    var pose: Pose
    var avatar: Avatar
    var blink = false
    var time: Double = 0

    var body: some View {
        Canvas { ctx, size in
            let figure = Figure(pose: pose, avatar: avatar)
            let painter = Painter(figure: figure, time: time, blink: blink)
            ctx.withCGContext { cg in
                let k = min(size.width, size.height) / 200
                cg.scaleBy(x: k, y: k)
                let anchor = CGPoint(x: 100 + pose.x, y: Figure.ground + pose.y)
                cg.translateBy(x: anchor.x, y: anchor.y)
                cg.scaleBy(x: pose.scale, y: pose.scale)
                cg.translateBy(x: -anchor.x, y: -anchor.y)
                cg.setAlpha(pose.alpha)
                cg.beginTransparencyLayer(auxiliaryInfo: nil)
                painter.paint(in: cg)
                cg.endTransparencyLayer()
            }
        }
    }
}

enum Blink {
    /// A short blink every ~4 seconds.
    static func isBlinking(_ date: Date) -> Bool {
        fmod(date.timeIntervalSinceReferenceDate, 4.2) < 0.13
    }
}
