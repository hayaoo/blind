import AVFoundation
import AppKit

public class SoundService {
    public static let shared = SoundService()

    private var audioPlayer: AVAudioPlayer?

    private init() {}

    public var soundEnabled: Bool {
        UserDefaults.standard.bool(forKey: "soundEnabled")
    }

    public func playCompletionSound() {
        guard soundEnabled else { return }

        // Try to play custom sound first
        if let soundURL = Bundle.main.url(forResource: "bell", withExtension: "mp3") {
            playSound(url: soundURL)
            return
        }

        // Fallback to system sound
        NSSound.beep()
    }

    private func playSound(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
            NSSound.beep()
        }
    }
}
