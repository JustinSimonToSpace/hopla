import AppKit
import SwiftUI

/// The app icon is drawn with the same engine as Hopla: a green apple caught mid-jump.
/// `Hopla --icon <dir>` writes an .iconset that `scripts/make-app.sh` turns into AppIcon.icns.
@MainActor
enum AppIcon {
    static let jumpPose = Moves.celebrate.sample(0.3).with { $0.y = -18; $0.stretch = 0.03; $0.leftArm = Arm(160, 12); $0.rightArm = Arm(160, 12) }

    static func writeIconset(to path: String) {
        let dir = URL(fileURLWithPath: path, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let renderer = ImageRenderer(content: IconArtwork().frame(width: 1024, height: 1024))
        renderer.scale = 1
        guard let master = renderer.cgImage else { print("Rendu de l'icône impossible"); return }
        for size in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let px = size * scale
                let name = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
                write(resize(master, to: px), to: dir.appendingPathComponent(name))
            }
        }
        write(master, to: dir.deletingLastPathComponent().appendingPathComponent("AppIcon-1024.png"))
        print("→ \(dir.path)")
    }

    private static func resize(_ image: CGImage, to px: Int) -> CGImage {
        guard let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: px * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return image }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: px, height: px))
        return ctx.makeImage() ?? image
    }

    private static func write(_ image: CGImage, to url: URL) {
        try? NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?.write(to: url)
    }

    /// Menu bar icon: Hopla's silhouette, arms up, as a template image.
    static func menuBarImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: true) { rect in
            guard let cg = NSGraphicsContext.current?.cgContext else { return false }
            let figure = Figure(pose: jumpPose.with { $0.y = 0; $0.stretch = 0.05 }, avatar: Avatar.catalog[0])
            cg.scaleBy(x: rect.width / 150, y: rect.height / 135)
            cg.translateBy(x: -25, y: -52)
            cg.setFillColor(.black)
            cg.setStrokeColor(.black)
            cg.setLineCap(.round)
            cg.setLineJoin(.round)
            for limb in figure.arms + figure.legs {
                cg.setLineWidth(11)
                cg.addLines(between: limb.points)
                cg.strokePath()
                cg.fillEllipse(in: CGRect(x: limb.end.x - 8, y: limb.end.y - 8, width: 16, height: 16))
            }
            cg.saveGState()
            cg.concatenate(figure.bodyTransform)
            cg.addPath(figure.body.path)
            cg.fillPath()
            for (leaf, _) in figure.backParts {
                cg.addPath(leaf)
                cg.fillPath()
            }
            for stem in figure.backStrokes {
                cg.setLineWidth(6)
                cg.addPath(stem)
                cg.strokePath()
            }
            // Eyes cut out of the silhouette.
            cg.setBlendMode(.clear)
            for s in [-1.0, 1.0] {
                cg.fillEllipse(in: CGRect(x: figure.eyeDX * s - 7, y: figure.eyeY - 9, width: 14, height: 18))
            }
            cg.restoreGState()
            return true
        }
        image.isTemplate = true
        return image
    }
}

struct IconArtwork: View {
    var body: some View {
        ZStack {
            // macOS icon grid: 824 pt rounded square centred in 1024.
            RoundedRectangle(cornerRadius: 186, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "#3DBE7A"), Color(hex: "#15804B")], startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 186, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 6)
                )
                .overlay(
                    Ellipse().fill(Color.white.opacity(0.10)).frame(width: 700, height: 360).offset(y: -230).blur(radius: 30)
                )
                .frame(width: 824, height: 824)
                .shadow(color: .black.opacity(0.28), radius: 22, y: 12)

            // Ground shadow, stretched because Hopla is in the air.
            Ellipse().fill(Color.black.opacity(0.18)).frame(width: 300, height: 46).offset(y: 300)

            // Motion lines: one smooth arc on each side.
            ForEach([-1.0, 1.0], id: \.self) { side in
                Path { p in
                    let center = side > 0 ? 0.0 : 180.0
                    p.addArc(center: CGPoint(x: 512, y: 470), radius: 318,
                             startAngle: .degrees(center - 24), endAngle: .degrees(center + 24), clockwise: false)
                }
                .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 20, lineCap: .round))
            }
            .frame(width: 1024, height: 1024)

            CharacterView(pose: AppIcon.jumpPose, avatar: Avatar.catalog[0].with { $0.palette.outline = "#0F4D2E" })
                .frame(width: 760, height: 760)
                .offset(y: -10)
        }
        .frame(width: 1024, height: 1024)
    }
}

extension Avatar {
    func with(_ edit: (inout Avatar) -> Void) -> Avatar {
        var copy = self
        edit(&copy)
        return copy
    }
}
