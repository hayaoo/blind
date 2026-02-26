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
        let defaults = UserDefaults.standard
        return BlindSettings(
            reminderInterval: defaults.integer(forKey: "reminderInterval").nonZeroOr(30),
            eyeCloseDuration: defaults.integer(forKey: "eyeCloseDuration").nonZeroOr(5),
            soundEnabled: defaults.object(forKey: "soundEnabled") == nil ? true : defaults.bool(forKey: "soundEnabled"),
            launchAtLogin: defaults.bool(forKey: "launchAtLogin")
        )
    }
}

extension Int {
    public func nonZeroOr(_ defaultValue: Int) -> Int {
        self > 0 ? self : defaultValue
    }
}
