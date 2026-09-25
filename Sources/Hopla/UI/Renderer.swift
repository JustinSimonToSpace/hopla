import AppKit
import SwiftUI

/// `Hopla --render <dir>` writes PNG contact sheets of every skin and pose, and of the bubbles.
/// Useful to review art changes (and for skin pull requests) without launching the app.
@MainActor
enum Renderer {
    static func run(outputDirectory: String) {
        let dir = URL(fileURLWithPath: outputDirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        write(posesSheet, to: dir.appendingPathComponent("poses.png"))
        write(directionsSheet, to: dir.appendingPathComponent("directions.png"))
        write(extremitiesSheet, to: dir.appendingPathComponent("extremites.png"))
        write(exercisesSheet, to: dir.appendingPathComponent("exercices.png"))
        write(catalogSheet, to: dir.appendingPathComponent("catalogue.png"))
        write(socialPreview, to: dir.appendingPathComponent("social-preview.png"), scale: 1)
        write(bubblesSheet, to: dir.appendingPathComponent("bulles.png"))
    }

    private static var posesSheet: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(ArtStyle.allCases.compactMap { style in Avatar.catalog.first { $0.style == style } }) { avatar in
                HStack(spacing: 0) {
                    Text(avatar.name).font(.hopla(13, .bold)).frame(width: 80, alignment: .leading)
                    ForEach(Moves.showcase.indices, id: \.self) { i in
                        VStack(spacing: 0) {
                            CharacterView(pose: Moves.showcase[i].1, avatar: avatar).frame(width: 150, height: 150)
                            Text(Moves.showcase[i].0).font(.hopla(11)).foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding(16)
        .foregroundColor(.black)
        .background(Color(hex: "#F4F1EA"))
    }

    /// One avatar per art direction, in a few poses, on a light and a dark desktop.
    private static var directionsSheet: some View {
        let picks = ArtStyle.allCases.compactMap { style in Avatar.catalog.first { $0.style == style } }
        let light: [(String, Pose)] = [("Repos", Moves.idle.sample(0)), ("Bras au ciel", Moves.reachUp.sample(2)),
                                        ("Squat", Moves.squat.sample(1.3)), ("Bravo", Moves.celebrate.sample(0.3))]
        let columns = [GridItem(.fixed(640)), GridItem(.fixed(640))]
        return VStack(alignment: .leading, spacing: 14) {
            Text("Hopla — 11 collections : un style + une famille de créatures").font(.hopla(26, .bold))
            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                ForEach(picks.indices, id: \.self) { i in
                    let avatar = picks[i]
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(i). \(avatar.style.collectionName)").font(.hopla(16, .bold))
                            Text(avatar.style.displayName).font(.hopla(13, .semibold)).foregroundColor(Color(hex: "#8A7F70"))
                            Text(avatar.name).font(.hopla(13)).foregroundColor(.gray)
                        }
                        HStack(spacing: 0) {
                            HStack(spacing: 0) {
                                ForEach(light.indices, id: \.self) { j in
                                    CharacterView(pose: light[j].1, avatar: avatar, time: 0.4).frame(width: 125, height: 125)
                                }
                            }
                            .background(Color(hex: "#E9E4DA"))
                            CharacterView(pose: Moves.wave.sample(0.2), avatar: avatar, time: 0.4)
                                .frame(width: 125, height: 125)
                                .background(Color(hex: "#23272F"))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(24)
        .foregroundColor(.black)
        .background(Color(hex: "#FAF8F4"))
    }

    /// The 1280×640 image GitHub shows when the repository is shared.
    private static var socialPreview: some View {
        let stars = ["hopla", "leon", "blip", "trice", "axo", "licorne", "citrouille", "dragonnet"].compactMap { id in Avatar.catalog.first { $0.id == id } }
        let poses = [Moves.wave.sample(0.2), Moves.celebrate.sample(0.3), Moves.reachUp.sample(2), Moves.squat.sample(1.3)]
        return ZStack {
            LinearGradient(colors: [Color(hex: "#F4FBF6"), Color(hex: "#DCF2E3")], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 18) {
                HStack(spacing: 28) {
                    IconArtwork().frame(width: 1024, height: 1024).scaleEffect(0.2).frame(width: 205, height: 205)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hopla").font(.hopla(88, .heavy)).foregroundColor(Color(hex: "#15543A"))
                        Text("A tiny desk buddy for macOS that gets you moving.").font(.hopla(30, .semibold)).foregroundColor(Color(hex: "#2C6A4A"))
                        Text("55 creatures · 18 moves · source available").font(.hopla(22)).foregroundColor(Color(hex: "#4E8A6A"))
                    }
                }
                HStack(spacing: 0) {
                    ForEach(stars.indices, id: \.self) { i in
                        CharacterView(pose: poses[i % poses.count], avatar: stars[i], time: 0.4).frame(width: 150, height: 150)
                    }
                }
            }
        }
        .frame(width: 1280, height: 640)
        .foregroundColor(.black)
    }

    /// All built-in creatures, one row per collection.
    private static var catalogSheet: some View {
        let poses = [Moves.wave.sample(0.2), Moves.idle.sample(0), Moves.celebrate.sample(0.3), Moves.reachUp.sample(2), Moves.squat.sample(1.3)]
        return VStack(alignment: .leading, spacing: 2) {
            Text("Hopla — 55 créatures").font(.hopla(28, .bold)).padding(.bottom, 8)
            ForEach(ArtStyle.allCases) { style in
                let members = Avatar.catalog.filter { $0.style == style }
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(style.collectionName).font(.hopla(15, .bold))
                        Text(style.displayName).font(.hopla(12)).foregroundColor(Color(hex: "#8A7F70"))
                    }
                    .frame(width: 150, alignment: .leading)
                    ForEach(members.indices, id: \.self) { i in
                        VStack(spacing: 0) {
                            CharacterView(pose: poses[i % poses.count], avatar: members[i], time: 0.4).frame(width: 140, height: 140)
                            Text(members[i].name).font(.hopla(11, .semibold))
                        }
                    }
                }
            }
        }
        .padding(20)
        .foregroundColor(.black)
        .background(Color(hex: "#EDE8DE"))
    }

    /// Every exercise at three moments of its loop.
    private static var exercisesSheet: some View {
        let avatar = Avatar.catalog[0]
        let rows = stride(from: 0, to: Exercise.all.count, by: 3).map { Array(Exercise.all[$0..<min($0 + 3, Exercise.all.count)]) }
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: 18) {
                    ForEach(rows[r]) { exercise in
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(exercise.titles.fr)\(exercise.posture == .standing ? " · debout" : "")").font(.hopla(13, .bold))
                            HStack(spacing: 0) {
                                ForEach([0.12, 0.4, 0.7], id: \.self) { f in
                                    CharacterView(pose: exercise.clip.sample(exercise.clip.duration * f), avatar: avatar).frame(width: 120, height: 120)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .foregroundColor(.black)
        .background(Color(hex: "#F4F1EA"))
    }

    /// Close-ups to review hands and feet.
    private static var extremitiesSheet: some View {
        let picks = ArtStyle.allCases.compactMap { style in Avatar.catalog.first { $0.style == style } }
        let rows = stride(from: 0, to: picks.count, by: 3).map { Array(picks[$0..<min($0 + 3, picks.count)]) }
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(rows[r], id: \.id) { avatar in
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                CharacterView(pose: Moves.wave.sample(0.2), avatar: avatar, time: 0.4).frame(width: 230, height: 230)
                                CharacterView(pose: Moves.squat.sample(1.3), avatar: avatar, time: 0.4).frame(width: 230, height: 230)
                            }
                            Text("\(avatar.style.collectionName) — \(avatar.name)").font(.hopla(13, .semibold))
                        }
                    }
                }
            }
        }
        .padding(16)
        .foregroundColor(.black)
        .background(Color(hex: "#E9E4DA"))
    }

    private static var bubblesSheet: some View {
        let session = RouteBook.session(route: 0)
        let phases: [(PetController.Phase, Double, Int)] = [(.asking, 0, 0), (.exercising(1), 0.4, 12), (.changingPosture(3), 0.35, 2), (.celebrating, 0, 0)]
        return HStack(spacing: 10) {
            ForEach(phases.indices, id: \.self) { i in
                let controller = PetController()
                let _ = controller.debugFreeze(phases[i].0, session: session, progress: phases[i].1, remaining: phases[i].2)
                PetView(controller: controller)
            }
        }
        .padding(16)
        .background(Color(hex: "#3B4A5A"))
    }

    private static func write(_ view: some View, to url: URL, scale: CGFloat = 2) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        guard let image = renderer.cgImage,
              let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            print("Rendu impossible : \(url.lastPathComponent)")
            return
        }
        try? png.write(to: url)
        print("→ \(url.path)")
    }
}
