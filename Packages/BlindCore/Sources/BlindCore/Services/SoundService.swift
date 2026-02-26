import AppKit

public class SoundService {
    public static let shared = SoundService()

    private init() {}

    public var soundEnabled: Bool {
        BlindSettings.current.soundEnabled
    }

    public func playCompletionSound() {
        guard soundEnabled else { return }
        NSSound(named: "Glass")?.play()
    }

    public func playErrorSound() {
        guard soundEnabled else { return }
        NSSound(named: "Basso")?.play()
    }
}
