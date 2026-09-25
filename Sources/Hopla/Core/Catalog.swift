import Foundation

/// The 55 built-in creatures: 11 collections (an art style + a creature family) × 5.
extension Avatar {
    private static func p(_ body: String, _ belly: String, _ limbs: String, _ outline: String, _ cheeks: String, _ eyes: String,
                          _ accent: String, pattern: String? = nil, hands: String? = nil, feet: String? = nil, horns: String? = nil) -> Palette {
        Palette(body: body, belly: belly, limbs: limbs, outline: outline, cheeks: cheeks, eyes: eyes, accent: accent,
                pattern: pattern, hands: hands, feet: feet, horns: horns)
    }

    private static let none = "#00000000"
    private static let ink = "#161616"
    private static let pencil = "#3B3A36"
    private static let hose = "#141212"
    private static let glove = "#FBF7EE"
    private static let bone = "#F3E6C8"
    private static let lcd = p("#E8F0D8", "#E8F0D8", "#E8F0D8", "#1F2B1F", none, "#1F2B1F", "#1F2B1F", pattern: "#1F2B1F")

    static let catalog: [Avatar] = [
        // MARK: Le Verger — Classique
        Avatar(id: "hopla", name: "Hopla", style: .classic, shape: .apple, topper: .sprout,
               palette: p("#7ED9A4", "#E6FAEE", "#57BD84", "#2C6A4A", "#FF9DAE", "#1F2A2E", "#3FA35F")),
        Avatar(id: "peche", name: "Pêche", style: .classic, topper: .leaf, pattern: .cleft,
               palette: p("#FFB38A", "#FFE3CF", "#F59A6E", "#A2532F", "#FF7F8A", "#3A1E14", "#5DB36A", pattern: "#E8875C")),
        Avatar(id: "fraise", name: "Fraise", style: .classic, shape: .berry, belly: .none, pattern: .seeds, extras: [.leafCrown],
               palette: p("#F2545B", "#F2545B", "#D9434B", "#8C1F28", "#FFB3B8", "#2A0E10", "#4FAE5B", pattern: "#FFE38A")),
        Avatar(id: "myrtille", name: "Myrtille", style: .classic, extras: [.calyx],
               palette: p("#5B6CC9", "#A9B4EE", "#4A59B3", "#242C66", "#F29BC0", "#0F1433", "#5B6CC9", pattern: "#3A4494")),
        Avatar(id: "citron", name: "Citron", style: .classic, shape: .lemon, topper: .leaf,
               palette: p("#FFE45C", "#FFF6C2", "#F2CF3A", "#9A7A12", "#FFA98A", "#2E2508", "#6DBE5A")),

        // MARK: Grand Safari — Ligne claire
        Avatar(id: "leon", name: "Léon le lion", style: .ligneClaire, ears: .bear, belly: .muzzle, extras: [.mane],
               palette: p("#F2C14E", "#FCEBC4", "#E9B544", ink, "#F29A76", ink, "#C8742A")),
        Avatar(id: "girafe", name: "Girafe", style: .ligneClaire, shape: .tall, ears: .cat, belly: .muzzle, pattern: .patches, extras: [.ossicones],
               palette: p("#F4C25B", "#FBE8C0", "#EDB548", ink, "#F29A76", ink, "#F4C25B", pattern: "#B86B2C", horns: "#B86B2C")),
        Avatar(id: "zebre", name: "Zèbre", style: .ligneClaire, ears: .cat, belly: .muzzle, pattern: .zebra, extras: [.forelock],
               palette: p("#F7F5F0", "#D9D4CC", "#F7F5F0", ink, "#F4A7A7", ink, ink, pattern: "#1E1E1E")),
        Avatar(id: "ele", name: "Élé", style: .ligneClaire, ears: .elephant, belly: .none, extras: [.trunk],
               palette: p("#A7B3C2", "#A7B3C2", "#97A4B5", ink, "#F2A7B5", ink, "#A7B3C2")),
        Avatar(id: "hippo", name: "Hippo", style: .ligneClaire, ears: .bear, belly: .muzzle, extras: [.nostrils],
               palette: p("#B8A1D9", "#D9C9F0", "#A68FCB", ink, "#F59AB4", ink, "#B8A1D9")),

        // MARK: Monstres de cahier — Carnet de croquis
        Avatar(id: "gribouille", name: "Gribouille", style: .sketch, pattern: .spots, extras: [.cyclops, .horns, .fangs],
               palette: p("#A8D86E", "#D9F0B8", "#94C95C", pencil, "#F29AA8", "#2A2A2A", "#7A9CE0", pattern: "#8CC356", horns: "#F4EFE2")),
        Avatar(id: "tache", name: "Tache d'encre", style: .sketch, shape: .blob, belly: .none, pattern: .drips, extras: [.fangs],
               palette: p("#2F3F8F", "#2F3F8F", "#2A3880", "#1A1A1A", "#7A86D6", "#F4F1E8", "#2F3F8F", horns: "#F4EFE2")),
        Avatar(id: "poilu", name: "Poilu", style: .sketch, extras: [.fur, .horns],
               palette: p("#F29B38", "#FBD7A5", "#E58A2A", pencil, "#F2687A", "#2A2A2A", "#F29B38", horns: "#F4EFE2")),
        Avatar(id: "troisyeux", name: "Trois-Yeux", style: .sketch, pattern: .spots, extras: [.threeEyes, .fangs],
               palette: p("#F28DB2", "#FAD0E0", "#E678A2", pencil, "#D95F8C", "#2A2A2A", "#F28DB2", pattern: "#E070A0")),
        Avatar(id: "cornu", name: "Cornu", style: .sketch, shape: .tall, belly: .large, pattern: .spots, tail: .dragon, extras: [.horns, .fangs],
               palette: p("#9B7BD9", "#D2C4F2", "#8A69CC", pencil, "#F29AB8", "#221A33", "#6E4FB0", pattern: "#8A69CC", horns: "#F4EFE2")),

        // MARK: Fantômes rigolos — Cartoon 1930
        Avatar(id: "citrouille", name: "Citrouille", style: .rubberHose, belly: .none, pattern: .ribs, extras: [.stem],
               palette: p("#E8842C", "#E8842C", hose, hose, none, hose, "#4F6B2A", pattern: "#B8611A", hands: glove, feet: hose)),
        Avatar(id: "fantome", name: "Fantôme", style: .rubberHose, shape: .ghost, belly: .none,
               palette: p("#F4F1EA", "#F4F1EA", hose, hose, "#F2B8B8", hose, "#F4F1EA", hands: glove, feet: hose)),
        Avatar(id: "chauvesouris", name: "Chauve-souris", style: .rubberHose, ears: .bat, belly: .none, pattern: .facePatch, extras: [.wings, .fangs],
               palette: p("#3A3440", "#3A3440", hose, hose, none, hose, "#2A252F", pattern: "#F1E6CF", hands: glove, feet: hose)),
        Avatar(id: "momie", name: "Momie", style: .rubberHose, belly: .none, pattern: .bandages,
               palette: p("#E8DCC0", "#E8DCC0", hose, hose, none, hose, "#E8DCC0", pattern: "#CDBF9F", hands: glove, feet: hose)),
        Avatar(id: "diablotin", name: "Diablotin", style: .rubberHose, belly: .none, pattern: .facePatch, tail: .dragon, extras: [.horns, .fangs],
               palette: p("#D93A2B", "#D93A2B", hose, hose, none, hose, hose, pattern: "#F6D9C0", hands: glove, feet: hose, horns: hose)),

        // MARK: Aliens — Cartoon TV
        Avatar(id: "blip", name: "Blip", style: .cartoon, pattern: .spots, extras: [.cyclops, .antennae],
               palette: p("#9B6CF0", "#C9B3FF", "#2A1850", "#3A1F7A", "#F28BC4", "#1A0E33", "#7CF29B", pattern: "#8457E0", hands: "#B38BF7", feet: "#2A1850")),
        Avatar(id: "glorp", name: "Glorp", style: .cartoon, shape: .blob, pattern: .drips, extras: [.eyeStalks],
               palette: p("#8BE36B", "#C7F5B5", "#2D5A1F", "#2F6B22", "#F29AB8", "#1A2E12", "#8BE36B", hands: "#A5EC8C", feet: "#2D5A1F")),
        Avatar(id: "nebula", name: "Nébula", style: .cartoon, belly: .none, pattern: .stars, extras: [.antennae],
               palette: p("#2E2F7A", "#2E2F7A", "#1A1B4A", "#121338", "#F28BC4", "#0E0F2E", "#FFD86B", pattern: "#FFE58A", hands: "#4A4CB0", feet: "#1A1B4A")),
        Avatar(id: "zorg", name: "Zorg", style: .cartoon, shape: .tall, ears: .pointy, belly: .large, extras: [.threeEyes],
               palette: p("#3FC9B5", "#B5EFE6", "#1E4F48", "#1E6B60", "#F29AB8", "#0E2E2A", "#3FC9B5", hands: "#66D8C7", feet: "#1E4F48")),
        Avatar(id: "bzzz", name: "Bzzz", style: .cartoon, belly: .none, pattern: .stripes, extras: [.bugWings, .antennae],
               palette: p("#FFD23F", "#FFD23F", "#2A2210", "#5A4308", "#FF9F7A", "#1E1605", "#2A2210", pattern: "#2A2210", hands: "#FFE07A", feet: "#2A2210")),

        // MARK: Bestiaire RPG — Pixel 16 bits
        Avatar(id: "dragonnet", name: "Dragonnet", style: .pixel, tail: .dragon, extras: [.horns, .wings],
               palette: p("#E0503C", "#F6C98A", "#C8412F", "#5A1A12", "#FF9FB0", "#2A0E0A", "#9E2E22", horns: bone)),
        Avatar(id: "slime", name: "Slime", style: .pixel, shape: .blob, belly: .none, hand: .ball, foot: .ball,
               palette: p("#4FA8F0", "#4FA8F0", "#3E90D6", "#173F66", "#FF9FB0", "#0D2238", "#4FA8F0")),
        Avatar(id: "champignou", name: "Champignou", style: .pixel, shape: .tall, topper: .mushroomCap, hand: .mitten, foot: .ball,
               palette: p("#F4E6CF", "#FFF6E8", "#E8D3B0", "#6B4A2A", "#F2A08A", "#2A1A0E", "#D9382F")),
        Avatar(id: "golem", name: "Golem", style: .pixel, shape: .square, belly: .none, pattern: .cracks, hand: .stubby, foot: .stubby,
               palette: p("#9AA0A8", "#9AA0A8", "#858B93", "#3A3E44", none, "#1FB8E8", "#9AA0A8", pattern: "#5E646C", horns: "#C9CED4")),
        Avatar(id: "mimic", name: "Mimic", style: .pixel, shape: .square, belly: .none, pattern: .chest, extras: [.teeth], hand: .claw,
               palette: p("#A8662F", "#A8662F", "#8E5424", "#4A2A10", none, "#2A1606", "#A8662F", pattern: "#E0B040", horns: bone)),

        // MARK: Élémentaires — LCD Tamagotchi (shapes carry the element, the screen is monochrome)
        Avatar(id: "flammeche", name: "Flammèche", style: .lcd, shape: .flame, belly: .none, palette: lcd),
        Avatar(id: "gouttine", name: "Gouttine", style: .lcd, shape: .drop, belly: .none, palette: lcd),
        Avatar(id: "caillou", name: "Caillou", style: .lcd, shape: .rock, belly: .none, pattern: .cracks, palette: lcd),
        Avatar(id: "zephyr", name: "Zéphyr", style: .lcd, shape: .cloud, belly: .none, pattern: .swirl, palette: lcd),
        Avatar(id: "zap", name: "Zap", style: .lcd, topper: .bolt, belly: .none, palette: lcd),

        // MARK: Dinosaures — Pâte à modeler
        Avatar(id: "trice", name: "Tricé", style: .clay, tail: .dino, extras: [.frill, .horns, .noseHorn],
               palette: p("#7FB77E", "#DDEBC0", "#6FA56E", "#2F4F2E", "#F4A6A6", "#141814", "#4E8A5A", pattern: "#E8A04A", horns: bone)),
        Avatar(id: "trex", name: "T-Rex", style: .clay, belly: .large, tail: .dino, extras: [.teeth],
               palette: p("#6FAF6A", "#D6EBB8", "#5E9C5A", "#2C4A2A", "#F4A6A6", "#141814", "#4E8A5A", horns: bone)),
        Avatar(id: "stego", name: "Stégo", style: .clay, tail: .dino, extras: [.plates],
               palette: p("#E59E55", "#F7D9B0", "#D48C45", "#6B3E14", "#F4A6A6", "#1A1008", "#7FB06E", horns: bone)),
        Avatar(id: "diplo", name: "Diplo", style: .clay, shape: .tall, belly: .large, pattern: .spots, tail: .dino,
               palette: p("#6FA8D9", "#D2E6F5", "#5E96C8", "#24466B", "#F4A6B6", "#0E1A28", "#6FA8D9", pattern: "#5A8FC0", horns: bone)),
        Avatar(id: "ptero", name: "Ptéro", style: .clay, beak: true, extras: [.crest, .wings], hand: .talon, foot: .talon,
               palette: p("#C98BD9", "#EED3F5", "#B87AC9", "#5A2F66", "#F4A6C6", "#1E1024", "#9A5BB0", horns: bone)),

        // MARK: Monde marin — Aquarelle
        Avatar(id: "axo", name: "Axo l'axolotl", style: .watercolor, extras: [.gills],
               palette: p("#F7B6CA", "#FCE3EA", "#F2A0B9", "#D0708F", "#F07FA0", "#3A2030", "#E8628E")),
        Avatar(id: "meduse", name: "Méduse", style: .watercolor, shape: .ghost, belly: .none, extras: [.tentacles],
               palette: p("#C9B3F0", "#C9B3F0", "#B59BE6", "#7A62B8", "#F4A7C9", "#2A1E44", "#C9B3F0")),
        Avatar(id: "poulpe", name: "Poulpe", style: .watercolor, belly: .none, pattern: .spots, extras: [.tentacles],
               palette: p("#F2826A", "#F2826A", "#E5705A", "#B84A3A", "#F9B5A8", "#3A1610", "#F2826A", pattern: "#D9624C")),
        Avatar(id: "baleineau", name: "Baleineau", style: .watercolor, shape: .lemon, belly: .large, pattern: .grooves, extras: [.spout],
               palette: p("#6FA0D9", "#DCEBF8", "#5E8FC8", "#3E6FA8", "#F4A7B9", "#10223A", "#A8D8F5", pattern: "#9FBFE6")),
        Avatar(id: "tortue", name: "Tortue", style: .watercolor, extras: [.shell],
               palette: p("#8CCB8A", "#D8F0C8", "#7BBB79", "#4E8A4C", "#F4A7B0", "#16301A", "#B58A4A", pattern: "#8E6A34")),

        // MARK: Cyber-bestiaire — Néon
        Avatar(id: "robo", name: "Robo", style: .neon, shape: .square, topper: .antenna, belly: .none,
               palette: p("#3CF0FF", "#3CF0FF", "#FF4FD8", "#3CF0FF", "#FF4FD8", "#FFFFFF", "#FFE45C")),
        Avatar(id: "neochat", name: "Néo-chat", style: .neon, ears: .cat, belly: .none, extras: [.whiskers],
               palette: p("#FF4FD8", "#FF4FD8", "#3CF0FF", "#FF4FD8", "#3CF0FF", "#FFFFFF", "#FFE45C")),
        Avatar(id: "drone", name: "Drone", style: .neon, shape: .square, belly: .none, extras: [.propellers, .cyclops],
               palette: p("#7CFF6B", "#7CFF6B", "#3CF0FF", "#7CFF6B", none, "#FFFFFF", "#FFE45C")),
        Avatar(id: "mecalapin", name: "Méca-lapin", style: .neon, ears: .bunny, belly: .none, pattern: .rivets,
               palette: p("#FFE45C", "#FFE45C", "#FF7A3C", "#FFE45C", "#FF7A3C", "#FFFFFF", "#FFE45C", pattern: "#FF7A3C")),
        Avatar(id: "glitch", name: "Glitch", style: .neon, shape: .ghost, belly: .none, pattern: .glitch,
               palette: p("#B06BFF", "#B06BFF", "#3CF0FF", "#B06BFF", "#FF4FD8", "#FFFFFF", "#B06BFF", pattern: "#3CF0FF")),

        // MARK: Légendes — Papier découpé
        Avatar(id: "licorne", name: "Licorne", style: .paper, ears: .cat, belly: .none, extras: [.unicornHorn, .forelock],
               palette: p("#F8F4EE", "#F8F4EE", "#EFE8DE", "#A89A88", "#F6B3C6", "#2A2230", "#F2C94C", pattern: "#B89AF0",
                          hands: "#B8A6D9", feet: "#B8A6D9", horns: "#F2C94C")),
        Avatar(id: "yeti", name: "Yéti", style: .paper, shape: .tall, belly: .muzzle, extras: [.fur, .horns], hand: .paw, foot: .paw,
               palette: p("#EEF2F7", "#C9D6E6", "#E2E8F0", "#8A9AB0", "#F4B5C6", "#1E2633", "#EEF2F7", horns: "#B7C2D1")),
        Avatar(id: "phenix", name: "Phénix", style: .paper, beak: true, extras: [.flame, .wings], hand: .talon, foot: .talon,
               palette: p("#F2663A", "#FFC56B", "#E2552C", "#8A2A10", "#FFB08A", "#2A0E06", "#FFB23A", pattern: "#E8402A", horns: bone)),
        Avatar(id: "griffon", name: "Griffon", style: .paper, ears: .cat, beak: true, extras: [.wings], hand: .talon, foot: .paw,
               palette: p("#D9A94E", "#F2DDA8", "#C99A40", "#6B4A14", "#F2B08A", "#221605", "#8A5A2A", horns: bone)),
        Avatar(id: "kitsune", name: "Kitsune", style: .paper, ears: .fox, belly: .muzzle, pattern: .marks, extras: [.nineTails], hand: .paw, foot: .paw,
               palette: p("#FAF6F0", "#FFFFFF", "#F0E9DF", "#B8A690", "#F6B8C0", "#2A1A12", "#F2B35A", pattern: "#E0433A")),
    ]
}
