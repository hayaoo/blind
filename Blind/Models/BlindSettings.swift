import Foundation

struct BlindSettings: Codable {
    var reminderInterval: Int = 30      // minutes
    var eyeCloseDuration: Int = 5       // seconds
    var soundEnabled: Bool = true
    var launchAtLogin: Bool = false

    static var current: BlindSettings {
        BlindSettings(
            reminderInterval: UserDefaults.standard.integer(forKey: "reminderInterval").nonZeroOr(30),
            eyeCloseDuration: UserDefaults.standard.integer(forKey: "eyeCloseDuration").nonZeroOr(5),
            soundEnabled: UserDefaults.standard.bool(forKey: "soundEnabled"),
            launchAtLogin: UserDefaults.standard.bool(forKey: "launchAtLogin")
        )
    }
}

private extension Int {
    func nonZeroOr(_ defaultValue: Int) -> Int {
        self > 0 ? self : defaultValue
    }
}
