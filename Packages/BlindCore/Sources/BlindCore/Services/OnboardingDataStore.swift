import Foundation

/// 拡張オンボーディングのデータ永続化
/// UserDefaultsを使用してシンプルに実装
public final class OnboardingDataStore: Sendable {
    public static let shared = OnboardingDataStore()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let onboardingCompleted = "onboardingCompleted"
        static let extendedOnboardingCompleted = "extendedOnboardingCompleted"
        static let diagnosisResult = "diagnosisResult"
        static let personalizedPlan = "personalizedPlan"
        static let installDate = "installDate"
        static let currentDay = "currentOnboardingDay"
        static let sessionLogs = "sessionLogs"
        static let dailyTipStatuses = "dailyTipStatuses"
        static let day7ReportShown = "day7ReportShown"
        static let proUnlocked = "proUnlocked"
        static let lastOnboardingPhase = "lastOnboardingPhase"
        static let consecutiveSkips = "consecutiveSkips"
    }

    private init() {}

    // MARK: - Install Date

    /// アプリインストール日（初回起動日）
    public var installDate: Date {
        get {
            if let date = defaults.object(forKey: Keys.installDate) as? Date {
                return date
            }
            let now = Date()
            defaults.set(now, forKey: Keys.installDate)
            return now
        }
        set { defaults.set(newValue, forKey: Keys.installDate) }
    }

    /// インストールからの経過日数（1-indexed: Day 1 = インストール日）
    public var daysSinceInstall: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return days + 1 // 1-indexed
    }

    // MARK: - Onboarding State

    /// 拡張オンボーディングが完了したか
    public var isExtendedOnboardingCompleted: Bool {
        get { defaults.bool(forKey: Keys.extendedOnboardingCompleted) }
        set { defaults.set(newValue, forKey: Keys.extendedOnboardingCompleted) }
    }

    // MARK: - Diagnosis

    /// 診断結果の保存・読み込み
    public var diagnosisResult: DiagnosisResult? {
        get {
            guard let data = defaults.data(forKey: Keys.diagnosisResult) else { return nil }
            return try? decoder.decode(DiagnosisResult.self, from: data)
        }
        set {
            if let value = newValue, let data = try? encoder.encode(value) {
                defaults.set(data, forKey: Keys.diagnosisResult)
            } else {
                defaults.removeObject(forKey: Keys.diagnosisResult)
            }
        }
    }

    /// パーソナライズプラン
    public var personalizedPlan: PersonalizedPlan? {
        get {
            guard let data = defaults.data(forKey: Keys.personalizedPlan) else { return nil }
            return try? decoder.decode(PersonalizedPlan.self, from: data)
        }
        set {
            if let value = newValue, let data = try? encoder.encode(value) {
                defaults.set(data, forKey: Keys.personalizedPlan)
            } else {
                defaults.removeObject(forKey: Keys.personalizedPlan)
            }
        }
    }

    /// 診断結果からプランを生成して保存し、設定にも反映
    public func generateAndApplyPlan(from diagnosis: DiagnosisResult) {
        self.diagnosisResult = diagnosis
        let plan = PersonalizedPlan(from: diagnosis)
        self.personalizedPlan = plan

        // 設定に反映
        defaults.set(plan.reminderInterval, forKey: "reminderInterval")
        defaults.set(plan.eyeCloseDuration, forKey: "eyeCloseDuration")
    }

    // MARK: - Session Logs

    /// セッションログ
    public var sessionLogs: [SessionLogEntry] {
        get {
            guard let data = defaults.data(forKey: Keys.sessionLogs) else { return [] }
            return (try? decoder.decode([SessionLogEntry].self, from: data)) ?? []
        }
        set {
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: Keys.sessionLogs)
            }
        }
    }

    /// セッションログを追加
    public func addSessionLog(_ entry: SessionLogEntry) {
        var logs = sessionLogs
        logs.append(entry)
        sessionLogs = logs
    }

    /// 指定期間のセッションログを取得
    public func sessionLogs(from startDate: Date, to endDate: Date = Date()) -> [SessionLogEntry] {
        sessionLogs.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }

    /// 過去7日間のセッションログ
    public var last7DaysLogs: [SessionLogEntry] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessionLogs(from: sevenDaysAgo)
    }

    // MARK: - Consecutive Skips (暴走検知)

    /// 連続スキップ回数
    public var consecutiveSkips: Int {
        get { defaults.integer(forKey: Keys.consecutiveSkips) }
        set { defaults.set(newValue, forKey: Keys.consecutiveSkips) }
    }

    /// スキップを記録し、連続回数を返す
    public func recordSkip() -> Int {
        consecutiveSkips += 1
        return consecutiveSkips
    }

    /// セッション完了時にスキップカウントをリセット
    public func resetSkipCount() {
        consecutiveSkips = 0
    }

    // MARK: - Daily Tips

    /// デイリーTipの表示状態
    public var dailyTipStatuses: [DailyTipStatus] {
        get {
            guard let data = defaults.data(forKey: Keys.dailyTipStatuses) else {
                return (2...6).map { DailyTipStatus(day: $0) }
            }
            return (try? decoder.decode([DailyTipStatus].self, from: data))
                ?? (2...6).map { DailyTipStatus(day: $0) }
        }
        set {
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: Keys.dailyTipStatuses)
            }
        }
    }

    /// 今日表示すべきデイリーTipのday番号（nilなら表示不要）
    public var todaysTipDay: Int? {
        let day = daysSinceInstall
        guard (2...6).contains(day) else { return nil }
        let statuses = dailyTipStatuses
        guard let status = statuses.first(where: { $0.day == day }) else { return nil }
        return status.shown ? nil : day
    }

    /// デイリーTipを表示済みにする
    public func markTipShown(day: Int) {
        var statuses = dailyTipStatuses
        if let index = statuses.firstIndex(where: { $0.day == day }) {
            statuses[index] = DailyTipStatus(day: day, shown: true, shownAt: Date())
            dailyTipStatuses = statuses
        }
    }

    // MARK: - Day 7 Report

    /// Day 7レポートが表示済みか
    public var isDay7ReportShown: Bool {
        get { defaults.bool(forKey: Keys.day7ReportShown) }
        set { defaults.set(newValue, forKey: Keys.day7ReportShown) }
    }

    /// Day 7レポートを表示すべきか
    public var shouldShowDay7Report: Bool {
        daysSinceInstall >= 7 && !isDay7ReportShown
    }

    // MARK: - Pro

    /// Proがアンロックされているか
    public var isProUnlocked: Bool {
        get { defaults.bool(forKey: Keys.proUnlocked) }
        set { defaults.set(newValue, forKey: Keys.proUnlocked) }
    }

    // MARK: - Statistics (Day 7レポート用)

    /// 7日間の統計データ
    public struct WeeklyStats {
        public let totalSessions: Int
        public let completedSessions: Int
        public let skippedSessions: Int
        public let totalClosedDuration: TimeInterval
        public let skipRate: Double
        public let courseCorrections: Int
        public let voiceDistribution: [InnerVoiceType: Int]

        /// スキップ率が高い曜日×時間帯（簡易ヒートマップ用）
        public let skipsByDayHour: [(weekday: Int, hour: Int, count: Int)]
    }

    /// 過去7日間の統計を計算
    public func computeWeeklyStats() -> WeeklyStats {
        let logs = last7DaysLogs
        let completed = logs.filter { !$0.skipped }
        let skipped = logs.filter { $0.skipped }

        // 内なる声の分布
        var voiceDist: [InnerVoiceType: Int] = [:]
        for log in completed {
            if let voice = log.preCloseVoice {
                voiceDist[voice, default: 0] += 1
            }
        }

        // 軌道修正回数
        let corrections = completed.filter { $0.postCloseAction == .courseCorrect }.count

        // スキップのヒートマップ
        let calendar = Calendar.current
        var skipMap: [String: Int] = [:]
        for log in skipped {
            let weekday = calendar.component(.weekday, from: log.timestamp)
            let hour = calendar.component(.hour, from: log.timestamp)
            let key = "\(weekday)-\(hour)"
            skipMap[key, default: 0] += 1
        }
        let skipsByDayHour = skipMap.map { key, count -> (weekday: Int, hour: Int, count: Int) in
            let parts = key.split(separator: "-").map { Int($0) ?? 0 }
            return (weekday: parts[0], hour: parts[1], count: count)
        }.sorted { $0.count > $1.count }

        return WeeklyStats(
            totalSessions: logs.count,
            completedSessions: completed.count,
            skippedSessions: skipped.count,
            totalClosedDuration: completed.reduce(0) { $0 + $1.closedDuration },
            skipRate: logs.isEmpty ? 0 : Double(skipped.count) / Double(logs.count),
            courseCorrections: corrections,
            voiceDistribution: voiceDist,
            skipsByDayHour: skipsByDayHour
        )
    }

    // MARK: - Reset (デバッグ/テスト用)

    /// 全データをリセット
    public func resetAll() {
        let keys = [
            Keys.extendedOnboardingCompleted,
            Keys.diagnosisResult,
            Keys.personalizedPlan,
            Keys.installDate,
            Keys.sessionLogs,
            Keys.dailyTipStatuses,
            Keys.day7ReportShown,
            Keys.proUnlocked,
            Keys.consecutiveSkips,
            Keys.onboardingCompleted,
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
}
