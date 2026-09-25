import CoreGraphics
import Foundation
import Testing
@testable import Hopla

/// Avatar files come from strangers: loading them must never crash, escape the folder or break the app.
@Suite(.serialized) struct AvatarFileTests {
    private let folder = AvatarLibrary.userFolder

    init() throws {
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        AvatarLibrary.invalidate()
    }

    private func write(_ name: String, _ text: String) throws {
        try Data(text.utf8).write(to: folder.appendingPathComponent(name))
        AvatarLibrary.invalidate()
    }

    private let palette = ##"{"body":"#7ED9A4","belly":"#FFF","limbs":"#57BD84","outline":"#2C6A4A","cheeks":"#FF9DAE","eyes":"#1F2A2E","accent":"#3FA35F"}"##

    @Test func idsCanNeverBecomePaths() {
        #expect(AvatarLibrary.safeID("../../Library/LaunchAgents/evil") == "librarylaunchagentsevil")
        #expect(AvatarLibrary.safeID("/etc/passwd") == "etcpasswd")
        #expect(AvatarLibrary.safeID("") == "avatar")
        #expect(AvatarLibrary.safeID(String(repeating: "a", count: 500)).count == 64)
    }

    @Test func sharedFilesCannotReplaceBuiltInsOrEachOther() throws {
        try write("a.json", ##"{"id":"hopla","name":"Faux Hopla","palette":\##(palette)}"##)
        try write("b.json", ##"{"id":"perso","name":"Un","palette":\##(palette)}"##)
        try write("c.json", ##"{"id":"perso","name":"Deux","palette":\##(palette)}"##)
        let all = AvatarLibrary.all()
        #expect(all.first { $0.id == "hopla" }?.name == "Hopla", "the built-in Hopla stays")
        #expect(all.contains { $0.id == "hopla-2" && $0.name == "Faux Hopla" })
        #expect(all.contains { $0.id == "perso" } && all.contains { $0.id == "perso-2" })
        #expect(Set(all.map(\.id)).count == all.count, "ids are unique")
    }

    @Test func invisibleOrInvalidColorsAreFixed() throws {
        try write("ghost.json", ##"{"id":"g","name":"G","palette":{"body":"#FFFFFF00","belly":"#FFF","limbs":"nope","outline":"#000","cheeks":"#00000000","eyes":"#12345","accent":"#ABC"}}"##)
        let avatar = try #require(AvatarLibrary.all().first { $0.id == "g" })
        #expect(CGColor.hex(avatar.palette.body).alpha == 1, "the body can't be invisible")
        #expect(avatar.palette.limbs == "#888888")
        #expect(avatar.palette.eyes == "#888888")
        #expect(avatar.palette.cheeks == "#00000000", "transparent cheeks are allowed")
    }

    @Test func garbageFilesAreIgnoredWithoutCrashing() throws {
        var rng = SeededGenerator(seed: 42)
        let fragments = [##"{"id":"##, ##""x""##, ##","name":"##, ##"null"##, "[", "]", "{", "}", ":", ",", ##""palette""##, "1e999", ##""\u0000""##,
                         "true", palette, ##""extras":["fur","fur","wings"]"##, ##""style":"nope""##, String(repeating: "##", count: 300)]
        for i in 0..<300 {
            let count = Int(rng.next() % 12) + 1
            let text = (0..<count).map { _ in fragments[Int(rng.next() % UInt64(fragments.count))] }.joined()
            try write("junk-\(i).json", text)
        }
        try write("huge.json", ##"{"id":"big","name":"Big","palette":\##(palette),"x":""## + String(repeating: "a", count: 100_000) + ##""}"##)
        try write("dup-extras.json", ##"{"id":"many","name":"Many","palette":\##(palette),"extras":[\##(Array(repeating: "\"fur\"", count: 500).joined(separator: ","))]}"##)
        let all = AvatarLibrary.all()
        #expect(all.count >= Avatar.catalog.count)
        #expect(!all.contains { $0.id == "big" }, "oversized files are refused")
        #expect(all.first { $0.id == "many" }?.extras == [.fur], "duplicate extras are merged")
    }

    @Test func deletingOnlyTouchesTheAvatarsFolder() throws {
        let outside = folder.deletingLastPathComponent().appendingPathComponent("keep-me.json")
        try Data("{}".utf8).write(to: outside)
        try write("mine.json", ##"{"id":"../keep-me","name":"Mine","palette":\##(palette)}"##)
        let mine = try #require(AvatarLibrary.all().first { $0.name == "Mine" })
        AvatarLibrary.delete(mine)
        #expect(FileManager.default.fileExists(atPath: outside.path), "the file outside the folder is untouched")
        #expect(!FileManager.default.fileExists(atPath: folder.appendingPathComponent("mine.json").path))
        try? FileManager.default.removeItem(at: outside)
    }

    @Test func savedAvatarsRoundTrip() throws {
        var avatar = Avatar.catalog[20]
        avatar.id = "perso-test"
        avatar.name = "Copie"
        AvatarLibrary.save(avatar)
        let loaded = try #require(AvatarLibrary.all().first { $0.id == "perso-test" })
        #expect(loaded.name == "Copie" && loaded.style == avatar.style && loaded.extras == avatar.extras)
    }
}

struct ColorTests {
    @Test func hexFormats() {
        #expect(CGColor.parse("#FFF")?.rgba == [1, 1, 1, 1])
        #expect(CGColor.parse("F00")?.rgba == [1, 0, 0, 1])
        #expect(CGColor.parse("#00FF0080")?.alpha ?? 0 > 0.49)
        #expect(CGColor.parse("#12345") == nil)
        #expect(CGColor.parse("#GGGGGG") == nil)
        #expect(CGColor.parse("") == nil)
    }
}
