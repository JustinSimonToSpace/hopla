import CoreGraphics

/// Paints a `Figure` in the style of its avatar's art direction.
/// Every part goes through `shape(...)`, which is where each style gets its look.
struct Painter {
    let figure: Figure
    let spec: StyleSpec
    let frame: Int      // animation frame, drives line boil and film grain
    let blink: Bool

    init(figure: Figure, time: Double, blink: Bool) {
        self.figure = figure
        self.spec = figure.avatar.style.spec
        self.frame = Int(time * (spec.fps ?? 12))
        self.blink = blink
    }

    private var palette: Palette { figure.avatar.palette }
    private var ink: CGColor { .hex(spec.ink ?? palette.outline) }

    private func color(_ paint: Paint) -> CGColor {
        switch paint {
        case .body: return .hex(palette.body)
        case .belly: return .hex(palette.belly)
        case .limbs: return .hex(palette.limbs)
        case .outline: return ink
        case .cheeks: return .hex(palette.cheeks)
        case .accent: return .hex(palette.accent)
        case .pattern: return .hex(palette.pattern ?? palette.accent)
        case .horns: return .hex(palette.horns ?? "#F3E6C8")
        case .hand: return palette.hands.map(CGColor.hex) ?? (spec.gloves ? CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1) : .hex(palette.limbs))
        case .foot: return .hex(palette.feet ?? palette.limbs)
        case .eyes: return .hex(palette.eyes)
        case .glass: return CGColor(srgbRed: 0.9, green: 0.97, blue: 1, alpha: 0.55)
        case .white: return CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        }
    }

    // MARK: Scene

    func paint(in cg: CGContext) {
        if let px = spec.pixel { paintPixelated(cg, pixel: px) } else { paintScene(cg) }
    }

    private func paintScene(_ cg: CGContext) {
        for leg in figure.legs { drawLimb(cg, leg, isArm: false) }

        cg.saveGState()
        cg.concatenate(figure.bodyTransform)
        for stem in figure.backStrokes { drawStem(cg, stem) }
        for (i, part) in figure.backParts.enumerated() { shape(cg, part.0, color(part.1), seed: 10 + i) }
        shape(cg, figure.body.path, color(.body), seed: 1) { cg in decorateBody(cg) }
        for (i, part) in figure.frontParts.enumerated() { shape(cg, part.0, color(part.1), seed: 30 + i) }
        drawFace(cg)
        cg.restoreGState()

        for arm in figure.arms { drawLimb(cg, arm, isArm: true) }
    }

    private func decorateBody(_ cg: CGContext) {
        let body = figure.body
        // Coat patterns (zebra, giraffe) go under the muzzle; the others are painted over the belly.
        let coat = [.zebra, .patches].contains(figure.avatar.pattern)
        if !coat, let belly = figure.bellyPath { shape(cg, belly, color(.belly), seed: 2, outlined: false) }
        for (i, p) in figure.patternParts.enumerated() { shape(cg, p, color(.pattern), seed: 3 + i, outlined: false) }
        if coat, let belly = figure.bellyPath { shape(cg, belly, color(.belly), seed: 2, outlined: false) }

        if spec.shine {
            cg.fill(CGPath(ellipseIn: CGRect(x: -body.half * 0.72, y: body.top + 9, width: body.half * 0.55, height: 13), transform: nil),
                    ink: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.4))
        }
        if spec.hatching {
            cg.saveGState()
            cg.addEllipse(in: CGRect(x: body.half * 0.55 - 44, y: -52, width: 88, height: 88))
            cg.clip()
            let lines = CGMutablePath()
            for x in stride(from: -body.half - 40, to: body.half + 40, by: 5) {
                lines.move(to: CGPoint(x: x, y: body.bottom + 4))
                lines.addLine(to: CGPoint(x: x + 44, y: body.bottom - 40))
            }
            cg.stroke(PathTools.roughen(lines, amplitude: spec.jitter * 0.6, seed: frame * 3 + 5), ink: ink.withAlpha(0.28), width: 0.8)
            cg.restoreGState()
        }
        if spec.grain {
            let speck = CGColor(srgbRed: 0.95, green: 0.9, blue: 0.8, alpha: 0.55)
            for i in 0..<14 {
                let x = PathTools.noise(frame, i, 1) * body.half
                let y = body.top + (PathTools.noise(frame, i, 2) + 1) / 2 * (body.bottom - body.top)
                let r = 0.5 + (PathTools.noise(frame, i, 3) + 1) * 0.45
                cg.fill(CGPath(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r), transform: nil), ink: speck)
            }
            if PathTools.noise(frame, 99, 1) > 0.55 {
                let x = PathTools.noise(frame, 99, 2) * body.half
                let scratch = CGMutablePath()
                scratch.move(to: CGPoint(x: x, y: body.top))
                scratch.addLine(to: CGPoint(x: x + 2, y: body.bottom))
                cg.stroke(scratch, ink: speck.withAlpha(0.6), width: 0.6)
            }
        }
    }

    // MARK: Shapes — where styles differ

    private func shape(_ cg: CGContext, _ path: CGPath, _ fill: CGColor, seed: Int, outlined: Bool = true,
                       decorate: ((CGContext) -> Void)? = nil) {
        guard fill.alpha > 0 else { return }
        func inside(_ clip: CGPath) {
            guard let decorate else { return }
            cg.saveGState()
            cg.addPath(clip)
            cg.clip()
            decorate(cg)
            cg.restoreGState()
        }

        switch spec.fill {
        case .flat:
            cg.fill(path, ink: fill)
            inside(path)
            if outlined, spec.outline > 0 { cg.stroke(path, ink: ink, width: spec.outline) }

        case .pencil:
            cg.saveGState()
            cg.translateBy(x: 1.3, y: 1.1)          // slightly off-register color, like a coloured pencil
            cg.fill(path, ink: fill.withAlpha(0.92))
            cg.restoreGState()
            inside(path)
            if outlined {
                cg.stroke(PathTools.roughen(path, amplitude: spec.jitter, seed: seed * 31 + frame * 7), ink: ink.withAlpha(0.9), width: spec.outline)
                cg.stroke(PathTools.roughen(path, amplitude: spec.jitter * 1.4, seed: seed * 31 + frame * 7 + 3), ink: ink.withAlpha(0.35), width: spec.outline * 0.8)
            }

        case .clay:
            let p = PathTools.roughen(path, amplitude: spec.jitter, seed: seed * 17 + frame, step: 6)
            cg.saveGState()
            cg.setShadow(offset: .zero, blur: 3, color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.3))
            cg.fill(p, ink: fill)
            cg.restoreGState()
            let box = p.boundingBoxOfPath
            cg.saveGState()
            cg.addPath(p)
            cg.clip()
            let center = CGPoint(x: box.minX + box.width * 0.35, y: box.minY + box.height * 0.3)
            if let gradient = CGGradient(colorsSpace: nil, colors: [fill.lighter(0.3), fill, fill.darker(0.3)] as CFArray, locations: [0, 0.45, 1]) {
                cg.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center,
                                      endRadius: max(box.width, box.height) * 0.9, options: [.drawsAfterEndLocation])
            }
            cg.restoreGState()
            inside(p)
            cg.saveGState()
            cg.addPath(p)
            cg.clip()
            cg.fill(CGPath(ellipseIn: CGRect(x: box.minX + box.width * 0.2, y: box.minY + box.height * 0.12,
                                             width: box.width * 0.26, height: box.height * 0.14), transform: nil),
                    ink: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.35))
            cg.restoreGState()
            cg.stroke(p, ink: fill.darker(0.4).withAlpha(0.5), width: 0.8)

        case .wash:
            let base = PathTools.roughen(path, amplitude: 1.4, seed: seed * 13)
            for i in 0..<3 {
                cg.saveGState()
                cg.setShadow(offset: .zero, blur: 3, color: fill.withAlpha(0.5))
                cg.fill(PathTools.roughen(path, amplitude: 2.3, seed: seed * 13 + i + 1), ink: fill.withAlpha(0.36))
                cg.restoreGState()
            }
            inside(base)
            cg.stroke(base, ink: fill.darker(0.3).withAlpha(0.35), width: 1.1)

        case .glow:
            cg.fill(path, ink: fill.withAlpha(0.1))
            inside(path)
            if outlined { glowStroke(cg, path, fill, width: spec.outline) }

        case .paper:
            let p = PathTools.roughen(path, amplitude: 0.9, seed: seed * 7, step: 7)
            cg.saveGState()
            cg.setShadow(offset: CGSize(width: 1.4, height: -2.2), blur: 2.4, color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.35))
            cg.fill(p, ink: fill)
            cg.restoreGState()
            inside(p)
        }
    }

    private func glowStroke(_ cg: CGContext, _ path: CGPath, _ color: CGColor, width: CGFloat) {
        cg.saveGState()
        cg.setShadow(offset: .zero, blur: 9, color: color)
        cg.stroke(path, ink: color, width: width)
        cg.restoreGState()
        cg.stroke(path, ink: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.85), width: max(0.8, width * 0.38))
    }

    // MARK: Limbs

    private func drawLimb(_ cg: CGContext, _ limb: Figure.Limb, isArm: Bool) {
        let s = limb.side
        let p = limb.points
        let seed = (isArm ? 40 : 50) + Int(s)
        let limbColor = color(.limbs)

        switch spec.limbs {
        case .hose:
            let hose = CGMutablePath()
            hose.move(to: p[0])
            hose.addQuadCurve(to: p[2], control: p[1])
            cg.stroke(hose, ink: ink, width: spec.limbWidth)
        case .line:
            let line = CGMutablePath()
            line.addLines(between: p)
            if spec.fill == .glow { glowStroke(cg, line, limbColor, width: spec.limbWidth) } else { cg.stroke(line, ink: ink, width: spec.limbWidth) }
        case .tube:
            let line = CGMutablePath()
            line.addLines(between: p)
            let tube = line.copy(strokingWithWidth: spec.limbWidth, lineCap: .round, lineJoin: .round, miterLimit: 10).normalized()
            shape(cg, tube, limbColor, seed: seed)
        }

        // Hands follow the forearm; feet stay flat and point outward.
        let e = limb.end
        var place: CGAffineTransform
        let parts: [ExtremityPart]
        if isArm {
            let d = CGPoint(x: p[2].x - p[1].x, y: p[2].y - p[1].y)
            let angle = atan2(d.y, d.x) - .pi / 2
            place = CGAffineTransform(translationX: e.x, y: e.y).rotated(by: angle).scaledBy(x: -s, y: 1)
            parts = Extremities.hand(figure.handKind)
        } else {
            place = CGAffineTransform(translationX: e.x, y: e.y).scaledBy(x: s, y: 1)
            parts = Extremities.foot(figure.footKind)
        }
        for (i, part) in parts.enumerated() {
            guard let path = part.path.copy(using: &place) else { continue }
            shape(cg, path, color(part.paint), seed: seed + 5 + i, outlined: part.outlined)
        }
    }

    private func drawStem(_ cg: CGContext, _ stem: CGPath) {
        let accent = color(.accent)
        switch spec.fill {
        case .glow: glowStroke(cg, stem, accent, width: 2.2)
        case .pencil: cg.stroke(PathTools.roughen(stem, amplitude: spec.jitter, seed: 77 + frame * 7), ink: ink, width: 1.6)
        default:
            if spec.outline > 0 {
                cg.stroke(stem, ink: ink, width: 2 + spec.outline)
                cg.stroke(stem, ink: accent, width: 2.2)
            } else {
                cg.stroke(stem, ink: accent.darker(0.25), width: 3)
            }
        }
    }

    // MARK: Face (local coordinates)

    private func drawFace(_ cg: CGContext) {
        let f = figure, pose = f.pose
        let eyeColor = CGColor.hex(palette.eyes)
        let line = max(2.8, spec.pixel ?? 0)
        let eyes: Eyes = (blink && pose.eyes == .open) ? .closed : pose.eyes
        let lookX = pose.look * 3

        cg.saveGState()
        if spec.fill == .glow { cg.setShadow(offset: .zero, blur: 6, color: CGColor.hex(palette.body)) }

        let cheeks = CGColor.hex(palette.cheeks)
        if cheeks.alpha > 0 {
            for s in [-1.0, 1.0] {
                cg.fill(CGPath(ellipseIn: CGRect(x: f.cheekDX * s - 6, y: f.cheekY - 3.5, width: 12, height: 7), transform: nil),
                        ink: cheeks.withAlpha(spec.fill == .glow ? 0.55 : 0.75))
            }
        }

        // Cyclops get one big centered eye, some monsters a third one; eyes on stalks live on the head.
        var eyeList: [(CGPoint, CGFloat)] = f.has(.cyclops) ? [(CGPoint(x: lookX, y: f.eyeY - 2), 1.6)]
            : [-1.0, 1.0].map { (CGPoint(x: f.eyeDX * $0 + lookX, y: f.eyeY), 1) }
        if f.has(.threeEyes) { eyeList.append((CGPoint(x: lookX, y: f.eyeY - 16), 0.8)) }
        if f.has(.eyeStalks) { eyeList = [] }
        for (c, eyeScale) in eyeList {
            cg.saveGState()
            cg.translateBy(x: c.x, y: c.y)
            cg.scaleBy(x: eyeScale, y: eyeScale)
            cg.translateBy(x: -c.x, y: -c.y)
            defer { cg.restoreGState() }
            switch eyes {
            case .open, .wide:
                let wide = eyes == .wide
                switch spec.eyes {
                case .bead:
                    let boost: CGFloat = spec.lcd ? 2 : 0
                    let w: CGFloat = (wide ? 12 : 10) + boost, h: CGFloat = (wide ? 15 : 13) + boost
                    cg.fill(CGPath(ellipseIn: CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h), transform: nil), ink: eyeColor)
                    if spec.pixel == nil {
                        cg.fill(CGPath(ellipseIn: CGRect(x: c.x - 3.8, y: c.y - 5.5, width: 4.2, height: 4.2), transform: nil), ink: color(.white))
                    }
                case .dot:
                    let w: CGFloat = wide ? 7 : 5.5, h: CGFloat = wide ? 9 : 7
                    cg.fill(CGPath(ellipseIn: CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h), transform: nil), ink: eyeColor)
                case .pie:
                    let w: CGFloat = wide ? 10.5 : 9, h: CGFloat = wide ? 17 : 15
                    cg.fill(CGPath(ellipseIn: CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h), transform: nil), ink: eyeColor)
                    let notch = CGMutablePath()
                    notch.addLines(between: [CGPoint(x: c.x + 0.5, y: c.y - 1.5), CGPoint(x: c.x + 5.5, y: c.y - 8.5), CGPoint(x: c.x + 5.5, y: c.y - 1)])
                    notch.closeSubpath()
                    cg.fill(notch, ink: color(figure.avatar.pattern == .facePatch ? .pattern : .body))
                case .big:
                    let r: CGFloat = wide ? 10 : 9
                    let white = CGPath(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r), transform: nil)
                    cg.fill(white, ink: color(.white))
                    cg.stroke(white, ink: ink, width: max(2, spec.outline * 0.6))
                    let pc = CGPoint(x: c.x + lookX * 0.6, y: c.y + 1)
                    cg.fill(CGPath(ellipseIn: CGRect(x: pc.x - 3.5, y: pc.y - 3.5, width: 7, height: 7), transform: nil), ink: eyeColor)
                }
            case .closed:
                let p = CGMutablePath()
                p.move(to: CGPoint(x: c.x - 6, y: c.y))
                p.addQuadCurve(to: CGPoint(x: c.x + 6, y: c.y), control: CGPoint(x: c.x, y: c.y + 5))
                cg.stroke(p, ink: eyeColor, width: line)
            case .happy:
                let p = CGMutablePath()
                p.move(to: CGPoint(x: c.x - 6, y: c.y + 2))
                p.addQuadCurve(to: CGPoint(x: c.x + 6, y: c.y + 2), control: CGPoint(x: c.x, y: c.y - 7))
                cg.stroke(p, ink: eyeColor, width: line)
            }
        }

        if let beak = f.beakPath {
            cg.restoreGState()
            shape(cg, beak, color(.accent), seed: 60)
            return
        }

        if f.has(.noseHorn) {
            let horn = CGMutablePath()
            horn.addLines(between: [CGPoint(x: lookX * 0.5 - 4, y: f.mouthY - 6), CGPoint(x: lookX * 0.5 + 4, y: f.mouthY - 6),
                                    CGPoint(x: lookX * 0.5 + 1, y: f.mouthY - 17)])
            horn.closeSubpath()
            shape(cg, horn, color(.horns), seed: 61)
        }

        let m = CGPoint(x: lookX * 0.5, y: f.mouthY)
        let mouthColor = spec.fill == .glow ? eyeColor : CGColor.hex("#7A2E3E")
        defer {
            if f.has(.teeth) {
                for x in stride(from: -12.0, through: 12, by: 6) {
                    let tooth = CGMutablePath()
                    tooth.addLines(between: [CGPoint(x: m.x + x - 3, y: m.y - 1), CGPoint(x: m.x + x + 3, y: m.y - 1), CGPoint(x: m.x + x, y: m.y + 5)])
                    tooth.closeSubpath()
                    cg.fill(tooth, ink: color(.white))
                    cg.stroke(tooth, ink: ink.withAlpha(0.7), width: 0.7)
                }
            }
            if f.has(.fangs) {
                for s in [-1.0, 1.0] {
                    let fang = CGMutablePath()
                    fang.addLines(between: [CGPoint(x: m.x + s * 2, y: m.y + 1.5), CGPoint(x: m.x + s * 6, y: m.y + 1),
                                            CGPoint(x: m.x + s * 4.2, y: m.y + 6.5)])
                    fang.closeSubpath()
                    cg.fill(fang, ink: color(.white))
                    cg.stroke(fang, ink: ink.withAlpha(0.8), width: 0.8)
                }
            }
            cg.restoreGState()
        }
        switch f.has(.trunk) ? nil : pose.mouth {
        case nil:
            break
        case .smile?:
            let p = CGMutablePath()
            p.move(to: CGPoint(x: m.x - 7, y: m.y))
            p.addQuadCurve(to: CGPoint(x: m.x + 7, y: m.y), control: CGPoint(x: m.x, y: m.y + 7))
            cg.stroke(p, ink: eyeColor, width: line)
        case .grin?:
            let p = CGMutablePath()
            p.move(to: CGPoint(x: m.x - 9, y: m.y - 1))
            p.addQuadCurve(to: CGPoint(x: m.x + 9, y: m.y - 1), control: CGPoint(x: m.x, y: m.y + 14))
            p.closeSubpath()
            cg.fill(p, ink: mouthColor)
            if cheeks.alpha > 0 {
                cg.fill(CGPath(ellipseIn: CGRect(x: m.x - 4, y: m.y + 2.5, width: 8, height: 3.5), transform: nil), ink: cheeks)
            }
        case .open?:
            cg.fill(CGPath(ellipseIn: CGRect(x: m.x - 5, y: m.y - 3, width: 10, height: 9), transform: nil), ink: mouthColor)
        case .o?:
            cg.fill(CGPath(ellipseIn: CGRect(x: m.x - 3, y: m.y - 2, width: 6, height: 7), transform: nil), ink: mouthColor)
        case .flat?:
            let p = CGMutablePath()
            p.move(to: CGPoint(x: m.x - 5, y: m.y + 1))
            p.addLine(to: CGPoint(x: m.x + 5, y: m.y + 1))
            cg.stroke(p, ink: eyeColor, width: line)
        }
    }

    // MARK: Pixel art & LCD

    private func paintPixelated(_ cg: CGContext, pixel px: CGFloat) {
        let n = Int((200 / px).rounded(.up))
        guard let off = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: n * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
        off.translateBy(x: 0, y: CGFloat(n))
        off.scaleBy(x: 1 / px, y: -1 / px)
        off.setShouldAntialias(false)
        off.setAllowsAntialiasing(false)
        paintScene(off)

        if spec.lcd {
            guard let data = off.data else { return }
            let buf = data.bindMemory(to: UInt8.self, capacity: n * n * 4)
            let dark = CGColor.hex("#1C271C"), mid = CGColor.hex("#5A6E4E"), light = CGColor.hex("#C6D7A8")
            for row in 0..<n {
                for col in 0..<n {
                    let i = (row * n + col) * 4
                    let a = CGFloat(buf[i + 3])
                    guard a > 110 else { continue }
                    let l = (0.2126 * CGFloat(buf[i]) + 0.7152 * CGFloat(buf[i + 1]) + 0.0722 * CGFloat(buf[i + 2])) / a
                    let tone = l < 0.35 ? dark : (l < 0.72 ? mid : light)
                    cg.setFillColor(tone)
                    cg.fill(CGRect(x: CGFloat(col) * px + 0.5, y: CGFloat(row) * px + 0.5, width: px - 1, height: px - 1))
                }
            }
        } else if let image = off.makeImage() {
            let side = CGFloat(n) * px
            cg.saveGState()
            cg.interpolationQuality = .none
            cg.translateBy(x: 0, y: side)
            cg.scaleBy(x: 1, y: -1)
            cg.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            cg.restoreGState()
        }
    }
}

private extension CGContext {
    func fill(_ path: CGPath, ink: CGColor) {
        addPath(path)
        setFillColor(ink)
        fillPath()
    }

    func stroke(_ path: CGPath, ink: CGColor, width: CGFloat) {
        addPath(path)
        setStrokeColor(ink)
        setLineWidth(width)
        setLineCap(.round)
        setLineJoin(.round)
        strokePath()
    }
}
