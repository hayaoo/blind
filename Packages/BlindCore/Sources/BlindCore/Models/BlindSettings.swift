import Foundation

public struct BlindSettings: Codable {
    public var reminderInterval: Int = 30      // minutes
    public var eyeCloseDuration: Int = 5       // seconds
    public var soundEnabled: Bool = true
    public var launchAtLogin: Bool = false
    public var trainingSchedule: TrainingSchedule = .standard

    public init(
        reminderInterval: Int = 30,
        eyeCloseDuration: Int = 5,
        soundEnabled: Bool = true,
        launchAtLogin: Bool = false,
        trainingSchedule: TrainingSchedule = .standard
    ) {
        self.reminderInterval = reminderInterval
        self.eyeCloseDuration = eyeCloseDuration
        self.soundEnabled = soundEnabled
        self.launchAtLogin = launchAtLogin
        self.trainingSchedule = trainingSchedule
    }

    public static var current: BlindSettings {
        let defaults = UserDefaults.standard
        var settings = BlindSettings(
            reminderInterval: defaults.integer(forKey: "reminderInterval").nonZeroOr(30),
            eyeCloseDuration: defaults.integer(forKey: "eyeCloseDuration").nonZeroOr(5),
            soundEnabled: defaults.object(forKey: "soundEnabled") == nil ? true : defaults.bool(forKey: "soundEnabled"),
            launchAtLogin: defaults.bool(forKey: "launchAtLogin")
        )
        if let data = defaults.data(forKey: "trainingSchedule"),
           let schedule = try? JSONDecoder().decode(TrainingSchedule.self, from: data) {
            settings.trainingSchedule = schedule
        }
        return settings
    }

    /// トレーニング時間帯をUserDefaultsに保存
    public static func saveTrainingSchedule(_ schedule: TrainingSchedule) {
        if let data = try? JSONEncoder().encode(schedule) {
            UserDefaults.standard.set(data, forKey: "trainingSchedule")
        }
    }
}

extension Int {
    public func nonZeroOr(_ defaultValue: Int) -> Int {
        self > 0 ? self : defaultValue
    }
}
