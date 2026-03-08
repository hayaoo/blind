import Foundation

public class TimerService {
    public var onTimerFired: (() -> Void)?

    private var timer: Timer?
    private var graceTimer: Timer?
    private var graceState = GraceState()

    public var intervalMinutes: Int {
        let stored = UserDefaults.standard.integer(forKey: "reminderInterval")
        return stored > 0 ? stored : 30
    }

    /// 猶予時間（秒）
    public static let graceDurationSeconds: TimeInterval = 300 // 5分

    public init() {}

    public func start() {
        scheduleTimer()
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        graceTimer?.invalidate()
        graceTimer = nil
    }

    public func reset() {
        stop()
        start()
    }

    // MARK: - Grace (猶予)

    /// 猶予を使用して5分後にリマインド（1回のみ）
    /// - Returns: trueなら猶予が使えた、falseなら既に使用済み
    public func useGrace() -> Bool {
        guard !graceState.usedForCurrentReminder else { return false }
        graceState.useGrace()

        // 猶予カウントをDataStoreに記録
        let defaults = UserDefaults.standard
        let total = defaults.integer(forKey: "totalGraceCount") + 1
        defaults.set(total, forKey: "totalGraceCount")

        // 5分後に再通知
        graceTimer?.invalidate()
        graceTimer = Timer.scheduledTimer(withTimeInterval: Self.graceDurationSeconds, repeats: false) { [weak self] _ in
            self?.onTimerFired?()
        }
        return true
    }

    /// 今回のリマインドで猶予が使用可能か
    public var canUseGrace: Bool {
        !graceState.usedForCurrentReminder
    }

    /// 累計猶予使用回数
    public static var totalGraceCount: Int {
        UserDefaults.standard.integer(forKey: "totalGraceCount")
    }

    // MARK: - Training Window

    /// トレーニング時間帯内かどうか
    public var isWithinTrainingWindow: Bool {
        BlindSettings.current.trainingSchedule.isWithinWindow()
    }

    // MARK: - Escalation

    /// 連続スキップに基づくエスカレーション間隔（分）
    public var escalatedIntervalMinutes: Int {
        let skips = OnboardingDataStore.shared.consecutiveSkips
        let base = intervalMinutes

        if skips >= 3 {
            // 3回以上連続スキップ → 間隔を1/3に
            return max(5, base / 3)
        } else if skips >= 2 {
            // 2回連続スキップ → 間隔を半分に
            return max(5, base / 2)
        }
        return base
    }

    /// エスカレーションレベル（通知テキスト変更用）
    public var escalationLevel: EscalationLevel {
        let skips = OnboardingDataStore.shared.consecutiveSkips
        switch skips {
        case 0...1: return .normal
        case 2: return .elevated
        default: return .urgent
        }
    }

    // MARK: - Private

    private func scheduleTimer() {
        timer?.invalidate()

        let interval = TimeInterval(escalatedIntervalMinutes * 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.handleTimerFired()
        }
    }

    private func handleTimerFired() {
        // トレーニング時間帯外なら次のタイマーだけスケジュールして通知しない
        guard isWithinTrainingWindow else {
            scheduleTimer()
            return
        }

        // 新しいリマインドサイクル: 猶予をリセット
        graceState.resetForNewReminder()

        onTimerFired?()

        // 次のタイマーをスケジュール
        scheduleTimer()
    }
}

// MARK: - Escalation Level

public enum EscalationLevel: Sendable {
    /// 通常（スキップ0-1回）
    case normal
    /// 警告（スキップ2回連続）
    case elevated
    /// 緊急（スキップ3回以上連続）
    case urgent
}
