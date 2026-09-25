import SwiftUI

struct PetView: View {
    static let size = CGSize(width: 300, height: 390)

    @ObservedObject var controller: PetController
    @ObservedObject private var settings = Settings.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let scale = settings.size.scale
        content
            .frame(width: PetView.size.width, height: PetView.size.height)
            .scaleEffect(scale, anchor: .bottom)
            .frame(width: PetView.size.width * scale, height: PetView.size.height * scale, alignment: .bottom)
    }

    /// What VoiceOver says about the creature.
    private var accessibilityDescription: String {
        let name = controller.avatar.name
        switch controller.phase {
        case .exercising(let i) where i < controller.session.count:
            return tr("\(name) fait : \(controller.session[i].exercise.title)", "\(name) is doing: \(controller.session[i].exercise.title)")
        case .celebrating: return tr("\(name) fait la fête", "\(name) is cheering")
        default: return name
        }
    }

    private var durationLabel: String {
        settings.sessionSeconds >= 60 ? "\(settings.sessionSeconds / 60) min" : "\(settings.sessionSeconds) s"
    }

    private var content: some View {
        // Negative spacing: the top of the character canvas is headroom for ears and jumps.
        VStack(spacing: -16) {
            Spacer(minLength: 0)
            bubble
                .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
                .zIndex(1)
            TimelineView(.animation(minimumInterval: 1 / min(controller.avatar.style.spec.fps ?? 60, 60),
                                    paused: controller.phase == .hidden)) { timeline in
                // Stop-motion styles (clay, sketch) snap time to their own frame rate.
                let date = controller.avatar.style.spec.quantize(timeline.date)
                CharacterView(pose: controller.pose(at: date), avatar: controller.avatar,
                              blink: Blink.isBlinking(date), time: date.timeIntervalSinceReferenceDate)
            }
            .accessibilityElement()
            .accessibilityLabel(accessibilityDescription)
            .frame(width: 180, height: 180)
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.75), value: controller.phase)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.8), value: controller.showSnoozeOptions)
    }

    private var avatar: Avatar { controller.avatar }

    @ViewBuilder private var bubble: some View {
        switch controller.phase {
        case .asking:
            Bubble(avatar: avatar) {
                Text("Hopla ! 👋").font(.hopla(17, .bold))
                Text(tr("On bouge \(durationLabel) ensemble ?", "Shall we move for \(durationLabel)?")).font(.hopla(13)).foregroundColor(.bubbleSecondary)
                if controller.showSnoozeOptions {
                    HStack(spacing: 6) {
                        ForEach(PetController.snoozeChoices, id: \.self) { minutes in
                            Button(minutes < 60 ? "\(minutes) min" : "1 h") { controller.snooze(minutes: minutes) }
                                .buttonStyle(PillButtonStyle(fill: .black.opacity(0.07), foreground: .bubbleText, compact: true))
                        }
                    }
                    .padding(.top, 2)
                } else {
                    HStack(spacing: 8) {
                        Button(tr("Go !", "Go!")) { controller.go() }
                            .buttonStyle(PillButtonStyle(fill: avatar.buttonColor, foreground: .white))
                        Button(tr("Plus tard 💤", "Later 💤")) { controller.showSnoozeOptions = true }
                            .accessibilityLabel(tr("Plus tard", "Later"))
                            .buttonStyle(PillButtonStyle(fill: .black.opacity(0.07), foreground: .bubbleText))
                    }
                    .padding(.top, 2)
                }
            }
        case .exercising(let i) where i < controller.session.count:
            let exercise = controller.session[i].exercise
            Bubble(avatar: avatar) {
                HStack {
                    Text(exercise.title).font(.hopla(15, .bold))
                    Spacer()
                    Text("\(i + 1)/\(controller.session.count)").font(.hopla(12, .semibold)).foregroundColor(.bubbleSecondary)
                }
                Text(exercise.instruction).font(.hopla(12.5)).foregroundColor(.bubbleSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressBar(value: controller.progress, color: avatar.progressColor)
                HStack(spacing: 6) {
                    Text("\(controller.remaining) s").font(.hopla(12, .semibold)).monospacedDigit().foregroundColor(.bubbleText)
                    Spacer()
                    Button(tr("Passer ›", "Skip ›")) { controller.skip() }
                        .buttonStyle(PillButtonStyle(fill: .black.opacity(0.07), foreground: .bubbleText, compact: true))
                    Button("Stop") { controller.stop() }
                        .buttonStyle(PillButtonStyle(fill: .black.opacity(0.07), foreground: .bubbleText, compact: true))
                }
            }
            .id("\(i)-\(exercise.id)")
        case .changingPosture(let i) where i < controller.session.count:
            let standing = controller.session[i].exercise.posture == .standing
            Bubble(avatar: avatar) {
                Text(standing ? tr("Debout ! 🧍", "Stand up! 🧍") : tr("On se rassoit 🪑", "Sit back down 🪑")).font(.hopla(16, .bold))
                Text(tr("Ensuite : \(controller.session[i].exercise.title)", "Next: \(controller.session[i].exercise.title)"))
                    .font(.hopla(12.5)).foregroundColor(.bubbleSecondary)
                ProgressBar(value: controller.progress, color: avatar.progressColor)
                HStack(spacing: 6) {
                    Text("\(controller.remaining) s").font(.hopla(12, .semibold)).monospacedDigit().foregroundColor(.bubbleText)
                    Spacer()
                    Button(tr("Prêt ›", "Ready ›")) { controller.skip() }
                        .buttonStyle(PillButtonStyle(fill: .black.opacity(0.07), foreground: .bubbleText, compact: true))
                }
            }
            .id("posture-\(i)")
        case .celebrating:
            Bubble(avatar: avatar) {
                Text(tr("Bravo ! 🎉", "Well done! 🎉")).font(.hopla(17, .bold))
                Text(celebrationLine).font(.hopla(13)).foregroundColor(.bubbleSecondary)
            }
        case .farewell(let message):
            Bubble(avatar: avatar) {
                Text(message).font(.hopla(14, .semibold))
            }
        default:
            EmptyView()
        }
    }

    private var celebrationLine: String {
        let today = Stats.shared.sessionsToday, streak = Stats.shared.streak
        let sessions = today > 1 ? tr("\(today) pauses aujourd'hui", "\(today) breaks today") : tr("Première pause du jour", "First break of the day")
        return streak > 1 ? sessions + tr(" · série de \(streak) jours 🔥", " · \(streak)-day streak 🔥") : sessions
    }
}

// MARK: - Pieces

private struct Bubble<Content: View>: View {
    let avatar: Avatar
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) { content }
            .foregroundColor(.bubbleText)
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12 + BubbleShape.tail)
            .frame(width: 256, alignment: .leading)
            .background(
                BubbleShape()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
            )
            .overlay(BubbleShape().stroke(avatar.buttonColor.opacity(0.25), lineWidth: 1.5))
            .padding(.bottom, 2)
    }
}

private struct BubbleShape: Shape {
    static let tail: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 16, w: CGFloat = 9
        let b = rect.maxY - BubbleShape.tail
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY + r), radius: r)
        p.addLine(to: CGPoint(x: rect.maxX, y: b - r))
        p.addArc(tangent1End: CGPoint(x: rect.maxX, y: b), tangent2End: CGPoint(x: rect.maxX - r, y: b), radius: r)
        p.addLine(to: CGPoint(x: rect.midX + w, y: b))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - w, y: b))
        p.addLine(to: CGPoint(x: rect.minX + r, y: b))
        p.addArc(tangent1End: CGPoint(x: rect.minX, y: b), tangent2End: CGPoint(x: rect.minX, y: b - r), radius: r)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.minX + r, y: rect.minY), radius: r)
        p.closeSubpath()
        return p
    }
}

private struct PillButtonStyle: ButtonStyle {
    var fill: Color
    var foreground: Color
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.hopla(compact ? 12 : 13.5, .semibold))
            .padding(.horizontal, compact ? 10 : 16)
            .padding(.vertical, compact ? 5 : 7)
            .background(Capsule().fill(fill))
            .foregroundColor(foreground)
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct ProgressBar: View {
    var value: Double
    var color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.08))
                Capsule().fill(color).frame(width: max(8, geo.size.width * value))
            }
        }
        .frame(height: 7)
        .animation(.linear(duration: 0.1), value: value)
    }
}

private extension Color {
    static let bubbleText = Color(hex: "#1F2A2E")
    static let bubbleSecondary = Color(hex: "#5B6770")
}

extension Font {
    static func hopla(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
