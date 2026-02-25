import Foundation

public struct BlindSettings: Codable {
    public var reminderInterval: Int = 30      // minutes
    public var eyeCloseDuration: Int = 5       // seconds
    public var soundEnabled: Bool = true
    public var launchAtLogin: Bool = false

    public init(
        reminderInterval: Int = 30,
        eyeCloseDuration: Int = 5,
        soundEnabled: Bool = true,
        launchAtLogin: Bool = false
    ) {
        self.reminderInterval = reminderInterval
        self.eyeCloseDuration = eyeCloseDuration
        self.soundEnabled = soundEnabled
        self.launchAtLogin = launchAtLogin
    }

    public static var current: BlindSettings {
        BlindSettings(
            reminderInterval: UserDefaults.standard.integer(forKey: "reminderInterval").nonZeroOr(30),
            eyeCloseDuration: UserDefaults.standard.integer(forKey: "eyeCloseDuration").nonZeroOr(5),
            soundEnabled: UserDefaults.standard.bool(forKey: "soundEnabled"),
            launchAtLogin: UserDefaults.standard.bool(forKey: "launchAtLogin")
        )
    }
}

extension Int {
    func nonZeroOr(_ defaultValue: Int) -> Int {
        self > 0 ? self : defaultValue
    }
}
