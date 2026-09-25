import Foundation

// Display names for every option shown in the settings and the avatar editor.

extension BodyShape {
    var label: String {
        switch self {
        case .round: return tr("Rond", "Round")
        case .apple: return tr("Pomme", "Apple")
        case .tall: return tr("Allongé", "Tall")
        case .square: return tr("Carré", "Square")
        case .blob: return tr("Goutte molle", "Blob")
        case .cloud: return tr("Nuage", "Cloud")
        case .pear: return tr("Poire", "Pear")
        case .berry: return tr("Fraise", "Berry")
        case .lemon: return tr("Citron", "Lemon")
        case .ghost: return tr("Fantôme", "Ghost")
        case .egg: return tr("Œuf", "Egg")
        case .flame: return tr("Flamme", "Flame")
        case .drop: return tr("Goutte", "Drop")
        case .rock: return tr("Rocher", "Rock")
        }
    }
}

extension Ears {
    var label: String {
        switch self {
        case .none: return tr("Aucune", "None")
        case .cat: return tr("Chat", "Cat")
        case .bunny: return tr("Lapin", "Bunny")
        case .bear: return tr("Ourson", "Bear")
        case .fox: return tr("Renard", "Fox")
        case .mouse: return tr("Souris", "Mouse")
        case .elephant: return tr("Éléphant", "Elephant")
        case .bat: return tr("Chauve-souris", "Bat")
        case .pointy: return tr("Pointues", "Pointy")
        }
    }
}

extension Topper {
    var label: String {
        switch self {
        case .none: return tr("Rien", "Nothing")
        case .sprout: return tr("Pousse", "Sprout")
        case .antenna: return tr("Antenne", "Antenna")
        case .beret: return tr("Béret de marin", "Sailor cap")
        case .leaf: return tr("Feuille", "Leaf")
        case .mushroomCap: return tr("Chapeau de champignon", "Mushroom cap")
        case .tuft: return tr("Mèche rebelle", "Hair tuft")
        case .bolt: return tr("Éclair", "Lightning bolt")
        }
    }
}

extension Belly {
    var label: String {
        switch self {
        case .none: return tr("Aucun", "None")
        case .oval: return tr("Ovale", "Oval")
        case .large: return tr("Grand", "Large")
        case .muzzle: return tr("Museau", "Muzzle")
        }
    }
}

extension Pattern {
    var label: String {
        switch self {
        case .none: return tr("Aucun", "None")
        case .stripes: return tr("Rayures", "Stripes")
        case .band: return tr("Bande", "Band")
        case .facePatch: return tr("Masque", "Face patch")
        case .spots: return tr("Taches", "Spots")
        case .ribs: return tr("Côtes de citrouille", "Pumpkin ribs")
        case .cleft: return tr("Sillon de pêche", "Peach cleft")
        case .seeds: return tr("Graines", "Seeds")
        case .patches: return tr("Taches de girafe", "Giraffe patches")
        case .zebra: return tr("Zébrures", "Zebra stripes")
        case .drips: return tr("Coulures", "Drips")
        case .bandages: return tr("Bandelettes", "Bandages")
        case .stars: return tr("Étoiles", "Stars")
        case .cracks: return tr("Fissures", "Cracks")
        case .chest: return tr("Coffre", "Treasure chest")
        case .eggCrack: return tr("Coquille fêlée", "Cracked shell")
        case .grooves: return tr("Sillons de baleine", "Whale grooves")
        case .rivets: return tr("Rivets", "Rivets")
        case .glitch: return tr("Bug numérique", "Glitch")
        case .marks: return tr("Marques magiques", "Magic marks")
        case .swirl: return tr("Tourbillons", "Swirls")
        }
    }
}

extension Tail {
    var label: String {
        switch self {
        case .none: return tr("Aucune", "None")
        case .fox: return tr("Renard", "Fox")
        case .dino: return tr("Dino", "Dino")
        case .dragon: return tr("Dragon", "Dragon")
        }
    }
}

extension Extra: CaseIterable {
    static var allCases: [Extra] {
        [.cyclops, .threeEyes, .eyeStalks, .fangs, .teeth, .horns, .unicornHorn, .noseHorn, .ossicones, .antennae, .propellers,
         .stem, .leafCrown, .calyx, .forelock, .crest, .flame, .spout, .mane, .fur, .beard, .whiskers, .trunk, .nostrils,
         .frill, .plates, .gills, .wings, .bugWings, .shell, .tentacles, .nineTails]
    }

    var label: String {
        switch self {
        case .cyclops: return tr("Œil unique", "One eye")
        case .fangs: return tr("Crocs", "Fangs")
        case .horns: return tr("Cornes", "Horns")
        case .unicornHorn: return tr("Corne de licorne", "Unicorn horn")
        case .noseHorn: return tr("Corne de nez", "Nose horn")
        case .antennae: return tr("Antennes", "Antennae")
        case .stem: return tr("Tige", "Stem")
        case .forelock: return tr("Mèche", "Forelock")
        case .mane: return tr("Crinière", "Mane")
        case .frill: return tr("Collerette", "Frill")
        case .gills: return tr("Branchies", "Gills")
        case .wings: return tr("Ailes", "Wings")
        case .leafCrown: return tr("Couronne de feuilles", "Leaf crown")
        case .calyx: return tr("Couronne de myrtille", "Berry crown")
        case .ossicones: return tr("Cornes de girafe", "Ossicones")
        case .trunk: return tr("Trompe", "Trunk")
        case .nostrils: return tr("Naseaux", "Nostrils")
        case .fur: return tr("Fourrure", "Fur")
        case .threeEyes: return tr("Troisième œil", "Third eye")
        case .eyeStalks: return tr("Yeux sur antennes", "Eye stalks")
        case .bugWings: return tr("Ailes d'insecte", "Bug wings")
        case .teeth: return tr("Dents", "Teeth")
        case .beard: return tr("Barbe", "Beard")
        case .plates: return tr("Plaques de stégosaure", "Back plates")
        case .crest: return tr("Crête", "Crest")
        case .tentacles: return tr("Tentacules", "Tentacles")
        case .spout: return tr("Jet d'eau", "Water spout")
        case .shell: return tr("Carapace", "Shell")
        case .whiskers: return tr("Moustaches", "Whiskers")
        case .propellers: return tr("Hélices", "Propellers")
        case .flame: return tr("Flamme", "Flame")
        case .nineTails: return tr("Neuf queues", "Nine tails")
        }
    }
}

extension Extremity: CaseIterable {
    static var allCases: [Extremity] { [.ball, .mitten, .paw, .claw, .glove, .threeFinger, .talon, .stubby, .splayed, .pincer, .hoof, .shoe, .sneaker, .boot] }
    static let hands: [Extremity] = [.ball, .mitten, .paw, .claw, .glove, .threeFinger, .talon, .stubby, .splayed, .pincer, .hoof]
    static let feet: [Extremity] = [.ball, .paw, .claw, .shoe, .sneaker, .talon, .stubby, .splayed, .boot, .hoof]

    var label: String {
        switch self {
        case .ball: return tr("Boule", "Ball")
        case .mitten: return tr("Moufle", "Mitten")
        case .paw: return tr("Patte", "Paw")
        case .claw: return tr("Griffes", "Claws")
        case .glove: return tr("Gant cartoon", "Cartoon glove")
        case .threeFinger: return tr("3 doigts", "3 fingers")
        case .talon: return tr("Serres", "Talons")
        case .stubby: return tr("Patte trapue", "Stubby")
        case .splayed: return tr("Doigts écartés", "Splayed")
        case .pincer: return tr("Pince", "Pincer")
        case .hoof: return tr("Sabot", "Hoof")
        case .shoe: return tr("Chaussure", "Shoe")
        case .sneaker: return tr("Basket", "Sneaker")
        case .boot: return tr("Botte", "Boot")
        }
    }
}

extension RouteVariation {
    var label: String {
        switch self {
        case .perVisit: return tr("À chaque passage", "Every visit")
        case .daily: return tr("Chaque jour", "Every day")
        case .weekly: return tr("Chaque semaine", "Every week")
        case .monthly: return tr("Chaque mois", "Every month")
        case .never: return tr("Jamais (parcours fixe)", "Never (fixed route)")
        }
    }
}

extension PetSize {
    var label: String {
        switch self {
        case .small: return tr("Petit", "Small")
        case .medium: return tr("Moyen", "Medium")
        case .large: return tr("Grand", "Large")
        }
    }
}

extension Corner {
    var label: String {
        switch self {
        case .bottomRight: return tr("En bas à droite", "Bottom right")
        case .bottomLeft: return tr("En bas à gauche", "Bottom left")
        case .topRight: return tr("En haut à droite", "Top right")
        case .topLeft: return tr("En haut à gauche", "Top left")
        case .custom: return tr("Là où je l'ai déposé", "Where I dropped it")
        }
    }
}

extension ScreenChoice {
    var label: String {
        switch self {
        case .main: return tr("Écran principal", "Main screen")
        case .mouse: return tr("Écran où se trouve la souris", "Screen with the mouse")
        }
    }
}

extension AppLanguage {
    var label: String {
        switch self {
        case .system: return tr("Langue du système", "System language")
        case .fr: return "Français"
        case .en: return "English"
        }
    }
}

extension ArtStyle {
    var fullName: String { "\(localizedCollection) · \(localizedStyle)" }

    var localizedCollection: String {
        switch self {
        case .classic: return tr("Le Verger", "The Orchard")
        case .ligneClaire: return tr("Grand Safari", "Grand Safari")
        case .sketch: return tr("Monstres de cahier", "Notebook Monsters")
        case .rubberHose: return tr("Fantômes rigolos", "Silly Spooks")
        case .cartoon: return tr("Aliens", "Aliens")
        case .pixel: return tr("Bestiaire RPG", "RPG Bestiary")
        case .lcd: return tr("Élémentaires", "Elementals")
        case .clay: return tr("Dinosaures", "Dinosaurs")
        case .watercolor: return tr("Monde marin", "Under the Sea")
        case .neon: return tr("Cyber-bestiaire", "Cyber Bestiary")
        case .paper: return tr("Légendes", "Legends")
        }
    }

    var localizedStyle: String {
        switch self {
        case .classic: return tr("Classique", "Classic")
        case .ligneClaire: return tr("Ligne claire", "Clear line")
        case .sketch: return tr("Carnet de croquis", "Sketchbook")
        case .rubberHose: return tr("Cartoon 1930", "1930s cartoon")
        case .cartoon: return tr("Cartoon TV", "TV cartoon")
        case .pixel: return tr("Pixel 16 bits", "16-bit pixel")
        case .lcd: return tr("LCD Tamagotchi", "Tamagotchi LCD")
        case .clay: return tr("Pâte à modeler", "Claymation")
        case .watercolor: return tr("Aquarelle", "Watercolor")
        case .neon: return tr("Néon", "Neon")
        case .paper: return tr("Papier découpé", "Paper cut")
        }
    }
}
