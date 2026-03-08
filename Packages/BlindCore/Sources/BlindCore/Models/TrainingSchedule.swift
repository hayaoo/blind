import Foundation

/// トレーニング時間帯の設定
/// オンボーディングで選択し、この範囲内でのみリマインドを送信する
public struct TrainingSchedule: Codable, Sendable, Equatable {
    /// トレーニング開始時刻（0-23）
    public let startHour: Int
    /// トレーニング終了時刻（0-23、startHourより後）
    public let endHour: Int

    public init(startHour: Int = 9, endHour: Int = 18) {
        self.startHour = max(0, min(23, startHour))
        self.endHour = max(0, min(23, endHour))
    }

    /// 指定時刻がトレーニング時間帯内かどうか
    public func isWithinWindow(at date: Date = Date()) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        if startHour <= endHour {
            return hour >= startHour && hour < endHour
        } else {
            // 深夜をまたぐ場合（例: 22:00-06:00）
            return hour >= startHour || hour < endHour
        }
    }

    /// トレーニング時間帯の長さ（時間）
    public var windowDurationHours: Int {
        if startHour <= endHour {
            return endHour - startHour
        } else {
            return (24 - startHour) + endHour
        }
    }

    /// 表示用テキスト
    public var displayText: String {
        "\(startHour):00 〜 \(endHour):00"
    }

    // MARK: - Presets

    /// 朝型（9:00-18:00）
    public static let morning = TrainingSchedule(startHour: 9, endHour: 18)
    /// 標準（10:00-19:00）
    public static let standard = TrainingSchedule(startHour: 10, endHour: 19)
    /// 遅め（11:00-20:00）
    public static let late = TrainingSchedule(startHour: 11, endHour: 20)
    /// フルタイム（9:00-21:00）
    public static let fullDay = TrainingSchedule(startHour: 9, endHour: 21)
}

/// オンボーディングのトレーニング時間帯選択肢
public enum TrainingWindowChoice: String, CaseIterable, Sendable {
    case morning    // 9:00-18:00
    case standard   // 10:00-19:00
    case late       // 11:00-20:00
    case fullDay    // 9:00-21:00

    public var displayText: String {
        switch self {
        case .morning:  return "朝型  9:00 〜 18:00"
        case .standard: return "標準  10:00 〜 19:00"
        case .late:     return "遅め  11:00 〜 20:00"
        case .fullDay:  return "ロング  9:00 〜 21:00"
        }
    }

    public var schedule: TrainingSchedule {
        switch self {
        case .morning:  return .morning
        case .standard: return .standard
        case .late:     return .late
        case .fullDay:  return .fullDay
        }
    }
}

/// 猶予（Grace）の状態管理
public struct GraceState: Codable, Sendable {
    /// 今回のリマインドで猶予を使用済みか
    public var usedForCurrentReminder: Bool = false
    /// 猶予使用回数（累計、Day 7レポート用）
    public var totalGraceCount: Int = 0

    public init() {}

    /// 猶予を使用（1回のみ、5分後に再通知）
    public mutating func useGrace() {
        usedForCurrentReminder = true
        totalGraceCount += 1
    }

    /// 次のリマインドサイクルでリセット
    public mutating func resetForNewReminder() {
        usedForCurrentReminder = false
    }
}
