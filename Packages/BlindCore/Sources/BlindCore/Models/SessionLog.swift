import Foundation

/// セッションログエントリ（1回のセッション記録）
public struct SessionLogEntry: Codable, Sendable {
    /// セッション実行日時
    public let timestamp: Date
    /// スキップされたか
    public let skipped: Bool
    /// Pre-closeで選択された内なる声（Pro機能、nilなら未使用）
    public let preCloseVoice: InnerVoiceType?
    /// Post-closeの判断（Pro機能、nilなら未使用）
    public let postCloseAction: PostCloseAction?
    /// 閉眼時間（秒）
    public let closedDuration: TimeInterval

    public init(
        timestamp: Date = Date(),
        skipped: Bool = false,
        preCloseVoice: InnerVoiceType? = nil,
        postCloseAction: PostCloseAction? = nil,
        closedDuration: TimeInterval = 0
    ) {
        self.timestamp = timestamp
        self.skipped = skipped
        self.preCloseVoice = preCloseVoice
        self.postCloseAction = postCloseAction
        self.closedDuration = closedDuration
    }
}

/// Post-closeガイドでの判断結果
public enum PostCloseAction: String, Codable, Sendable {
    /// 正しい方向に進んでいた
    case onTrack
    /// 方向転換する
    case courseCorrect
    /// 意図的に別のことをしている
    case intentionalDetour
    /// まだ必要（完璧派向け）
    case stillNeeded
    /// 穏やか（自動終了）
    case calm
}

/// デイリーTipの表示状態
public struct DailyTipStatus: Codable, Sendable {
    /// インストールからの日数（1-indexed）
    public let day: Int
    /// 表示済みか
    public var shown: Bool
    /// 表示日時
    public var shownAt: Date?

    public init(day: Int, shown: Bool = false, shownAt: Date? = nil) {
        self.day = day
        self.shown = shown
        self.shownAt = shownAt
    }
}
