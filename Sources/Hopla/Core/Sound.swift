import AVFoundation
import Foundation

/// Tiny synthesizer: every sound is generated on the fly, so there are no audio files to license.
/// Each collection has its own voice (waveform, register, glide…) and each avatar its own pitch.
enum Sound {
    enum Event: String { case arrive, go, next, celebrate, snooze }

    private enum Wave { case sine, triangle, square, saw, kalimba }

    private struct Voice {
        var wave: Wave
        var base: Double            // Hz
        var decay: Double           // seconds
        var glide: Double = 0       // semitones slid over each note
        var vibrato: Double = 0     // depth, in semitones
        var noise: Double = 0       // breath / pencil scratch
    }

    private static func voice(for style: ArtStyle) -> Voice {
        switch style {
        case .classic: return Voice(wave: .sine, base: 660, decay: 0.18)
        case .ligneClaire: return Voice(wave: .kalimba, base: 440, decay: 0.14)
        case .sketch: return Voice(wave: .triangle, base: 520, decay: 0.1, noise: 0.25)
        case .rubberHose: return Voice(wave: .sine, base: 600, decay: 0.2, glide: 3, vibrato: 0.35)
        case .cartoon: return Voice(wave: .triangle, base: 520, decay: 0.16, glide: -4)
        case .pixel: return Voice(wave: .square, base: 523, decay: 0.1)
        case .lcd: return Voice(wave: .square, base: 1568, decay: 0.06)
        case .clay: return Voice(wave: .sine, base: 330, decay: 0.16, glide: 5)
        case .watercolor: return Voice(wave: .sine, base: 880, decay: 0.09, glide: 7)
        case .neon: return Voice(wave: .saw, base: 440, decay: 0.25, vibrato: 0.15)
        case .paper: return Voice(wave: .kalimba, base: 784, decay: 0.3)
        }
    }

    /// (semitone, duration) per event.
    private static func melody(_ event: Event) -> [(Double, Double)] {
        switch event {
        case .arrive: return [(0, 0.11), (7, 0.2)]
        case .go: return [(0, 0.07), (4, 0.07), (7, 0.07), (12, 0.16)]
        case .next: return [(12, 0.08)]
        case .celebrate: return [(0, 0.08), (4, 0.08), (7, 0.08), (12, 0.08), (16, 0.08), (19, 0.3)]
        case .snooze: return [(7, 0.16), (0, 0.32)]
        }
    }

    private static let engine = AVAudioEngine()
    private static let player = AVAudioPlayerNode()
    private static let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private static var cache: [String: AVAudioPCMBuffer] = [:]
    private static var started = false
    private static let silent = isTestRun || CommandLine.arguments.contains("--render")

    static func play(_ event: Event, for avatar: Avatar, force: Bool = false) {
        guard !silent, force || Settings.shared.soundsEnabled else { return }
        let key = "\(avatar.id)-\(avatar.style.rawValue)-\(event.rawValue)"
        let buffer = cache[key] ?? synthesize(event, avatar: avatar)
        cache[key] = buffer
        do {
            if !started {
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
                started = true
            }
            // The engine stops when the audio output changes (headphones, AirPods…): restart it,
            // otherwise playing would raise an exception.
            if !engine.isRunning { try engine.start() }
            player.volume = Float(min(max(Settings.shared.volume, 0), 1))
            player.scheduleBuffer(buffer, at: nil, options: .interrupts)
            if !player.isPlaying { player.play() }
        } catch {
            NSLog("Hopla: son indisponible (\(error.localizedDescription))")
        }
    }

    private static func synthesize(_ event: Event, avatar: Avatar) -> AVAudioPCMBuffer {
        var v = voice(for: avatar.style)
        // Each avatar sings a little higher or lower than its collection-mates.
        let hash = avatar.id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        v.base *= pow(2, Double(hash % 7 - 3) / 12)

        let rate = format.sampleRate
        let notes = melody(event)
        let total = notes.reduce(0) { $0 + $1.1 } + v.decay
        let frames = AVAudioFrameCount(total * rate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let out = buffer.floatChannelData![0]
        for i in 0..<Int(frames) { out[i] = 0 }

        var rng = SeededGenerator(seed: UInt64(hash))
        var start = 0.0
        for (semitone, duration) in notes {
            let length = duration + v.decay
            let n = Int(length * rate), offset = Int(start * rate)
            var phase = 0.0
            for i in 0..<n where offset + i < Int(frames) {
                let t = Double(i) / rate
                let slide = v.glide * min(t / duration, 1)
                let wobble = v.vibrato * sin(2 * .pi * 6 * t)
                let freq = v.base * pow(2, (semitone + slide + wobble) / 12)
                phase += freq / rate
                let p = phase - floor(phase)
                var sample: Double
                switch v.wave {
                case .sine: sample = sin(2 * .pi * p)
                case .triangle: sample = 1 - 4 * abs(p - 0.5)
                case .square: sample = (p < 0.5 ? 1 : -1) * 0.5
                case .saw: sample = (2 * p - 1) * 0.45 + sin(2 * .pi * p) * 0.3
                case .kalimba: sample = sin(2 * .pi * p) + 0.35 * sin(4 * .pi * p) * exp(-t * 30)
                }
                if v.noise > 0 { sample += v.noise * (Double(rng.next() % 2000) / 1000 - 1) * exp(-t * 40) }
                let attack = min(t / 0.005, 1)
                let body = t < duration ? 1 : exp(-(t - duration) / (v.decay * 0.5))
                let envelope = attack * body * exp(-t / (duration + v.decay))
                out[offset + i] += Float(sample * envelope * 0.28)
            }
            start += duration
        }
        return buffer
    }
}
