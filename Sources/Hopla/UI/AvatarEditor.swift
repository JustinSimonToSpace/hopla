import AppKit
import SwiftUI

/// "Crée ton Hopla": every part of an avatar can be changed, with a live preview.
/// Saving writes a JSON file to the avatars folder, which can be shared with other Hopla users.
struct AvatarEditor: View {
    @State var draft: Avatar
    let onSave: (Avatar) -> Void
    let onCancel: () -> Void
    @State private var preview = 1

    private var previews: [(String, Clip)] {
        [(tr("Repos", "Idle"), Moves.idle), (tr("Coucou", "Wave"), Moves.wave), (tr("Bras au ciel", "Reach"), Moves.reachUp),
         (tr("Squat", "Squat"), Moves.squat), (tr("Marche", "March"), Moves.march), (tr("Bravo", "Cheer"), Moves.celebrate)]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 10) {
                    AnimatedCharacter(avatar: draft, clip: previews[preview].1)
                        .frame(width: 230, height: 230)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.primary.opacity(0.05)))
                    Picker("", selection: $preview) {
                        ForEach(previews.indices, id: \.self) { Text(previews[$0].0).tag($0) }
                    }
                    .labelsHidden()
                    .frame(width: 230)
                    Text(tr("Ton avatar sait faire tous les mouvements, quels que soient ses réglages.",
                            "Your avatar can do every move, whatever its settings."))
                        .font(.hopla(11)).foregroundColor(.secondary).multilineTextAlignment(.center).frame(width: 230)
                }
                Form {
                    Section(tr("Identité", "Identity")) {
                        TextField(tr("Nom", "Name"), text: $draft.name)
                        Picker(tr("Style de dessin", "Drawing style"), selection: $draft.style) {
                            ForEach(ArtStyle.allCases) { Text($0.localizedStyle).tag($0) }
                        }
                    }
                    Section(tr("Silhouette", "Body")) {
                        picker(tr("Forme", "Shape"), $draft.shape, BodyShape.allCases) { $0.label }
                        picker(tr("Oreilles", "Ears"), $draft.ears, Ears.allCases) { $0.label }
                        picker(tr("Sur la tête", "On the head"), $draft.topper, Topper.allCases) { $0.label }
                        picker(tr("Ventre", "Belly"), $draft.belly, Belly.allCases) { $0.label }
                        picker(tr("Motif", "Pattern"), $draft.pattern, Pattern.allCases) { $0.label }
                        picker(tr("Queue", "Tail"), $draft.tail, Tail.allCases) { $0.label }
                        Toggle(tr("Bec", "Beak"), isOn: $draft.beak)
                    }
                    Section(tr("Anatomie en plus", "Extra anatomy")) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading) {
                            ForEach(Extra.allCases, id: \.self) { extra in
                                Toggle(extra.label, isOn: Binding(
                                    get: { draft.extras.contains(extra) },
                                    set: { on in
                                        draft.extras.removeAll { $0 == extra }
                                        if on { draft.extras.append(extra) }
                                    }))
                                .toggleStyle(.checkbox)
                            }
                        }
                    }
                    Section(tr("Mains et pieds", "Hands and feet")) {
                        extremityPicker(tr("Mains", "Hands"), $draft.hand, Extremity.hands, auto: draft.style.defaultHand)
                        extremityPicker(tr("Pieds", "Feet"), $draft.foot, Extremity.feet, auto: draft.style.defaultFoot)
                    }
                    Section(tr("Couleurs", "Colors")) {
                        color(tr("Corps", "Body"), \.body)
                        color(tr("Ventre", "Belly"), \.belly)
                        color(tr("Bras et jambes", "Arms and legs"), \.limbs)
                        color(tr("Contour", "Outline"), \.outline)
                        color(tr("Joues", "Cheeks"), \.cheeks, opacity: true)
                        color(tr("Yeux", "Eyes"), \.eyes)
                        color(tr("Accessoires", "Accessories"), \.accent)
                        optionalColor(tr("Motif", "Pattern"), \.pattern, fallback: draft.palette.accent)
                        optionalColor(tr("Cornes et griffes", "Horns and claws"), \.horns, fallback: "#F3E6C8")
                        optionalColor(tr("Mains", "Hands"), \.hands, fallback: draft.palette.limbs)
                        optionalColor(tr("Pieds", "Feet"), \.feet, fallback: draft.palette.limbs)
                    }
                }
                .formStyle(.grouped)
            }
            .padding(16)
            Divider()
            HStack {
                Text(tr("Enregistré dans le dossier des avatars, partageable en un fichier.", "Saved in the avatars folder, shareable as a single file."))
                    .font(.hopla(11)).foregroundColor(.secondary)
                Spacer()
                Button(tr("Annuler", "Cancel"), action: onCancel).keyboardShortcut(.cancelAction)
                Button(tr("Enregistrer", "Save")) { onSave(draft) }.keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
        .frame(width: 800, height: 620)
    }

    private func picker<T: Hashable>(_ title: String, _ selection: Binding<T>, _ options: [T], label: @escaping (T) -> String) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.self) { Text(label($0)).tag($0) }
        }
    }

    private func extremityPicker(_ title: String, _ selection: Binding<Extremity?>, _ options: [Extremity], auto: Extremity) -> some View {
        Picker(title, selection: selection) {
            Text(tr("Selon le style (\(auto.label))", "Style default (\(auto.label))")).tag(Extremity?.none)
            ForEach(options, id: \.self) { Text($0.label).tag(Extremity?.some($0)) }
        }
    }

    private func color(_ title: String, _ key: WritableKeyPath<Palette, String>, opacity: Bool = false) -> some View {
        ColorPicker(title, selection: Binding(
            get: { Color(hex: draft.palette[keyPath: key]) },
            set: { draft.palette[keyPath: key] = $0.hexString }), supportsOpacity: opacity)
    }

    private func optionalColor(_ title: String, _ key: WritableKeyPath<Palette, String?>, fallback: String) -> some View {
        ColorPicker(title, selection: Binding(
            get: { Color(hex: draft.palette[keyPath: key] ?? fallback) },
            set: { draft.palette[keyPath: key] = $0.hexString }), supportsOpacity: false)
    }
}

extension Color {
    var hexString: String {
        let c = NSColor(self).usingColorSpace(.sRGB) ?? .black
        let rgb = String(format: "#%02X%02X%02X", Int((c.redComponent * 255).rounded()),
                         Int((c.greenComponent * 255).rounded()), Int((c.blueComponent * 255).rounded()))
        return c.alphaComponent < 0.999 ? rgb + String(format: "%02X", Int((c.alphaComponent * 255).rounded())) : rgb
    }
}
