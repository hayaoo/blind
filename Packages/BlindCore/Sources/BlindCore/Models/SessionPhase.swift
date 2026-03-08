import Foundation

public enum SessionPhase: Equatable, Sendable {
    case idle           // セッション未開始
    case summon         // Phase 1: ノッチからUI出現 (~0.6s)
    case preClose       // Phase 1.5 (Pro): 内なる声チェック（目を閉じる前）
    case encounter      // Phase 2: 目キャラがEyeStateに反応
    case immersion      // Phase 3: フルスクリーン黒 + 音量ダウン (5s設定可)
    case awakening      // Phase 4: 縮小 + 音量復帰 + ウインク (~2.0s)
    case postClose      // Phase 4.5 (Pro): 象使いの判断ガイド（目を開けた後）
    case completed      // セッション完了
    case cancelled      // キャンセル
}

public enum SessionPhaseTransition {
    public enum Trigger: Equatable, Sendable {
        case animationCompleted
        case eyesClosedDurationMet
        case immersionTimerCompleted
        case userCancelled
        case preCloseCompleted      // Pro: 内なる声チェック完了
        case postCloseCompleted     // Pro: 象使い判断完了
    }

    /// Pro機能（preClose/postClose）が有効かを外部から渡す
    public static func next(from phase: SessionPhase, trigger: Trigger, proEnabled: Bool = false) -> SessionPhase? {
        // キャンセルはアクティブなフェーズからのみ可能
        if trigger == .userCancelled {
            switch phase {
            case .summon, .preClose, .encounter, .immersion, .awakening, .postClose:
                return .cancelled
            default:
                return nil
            }
        }

        switch (phase, trigger) {
        case (.summon, .animationCompleted):
            return proEnabled ? .preClose : .encounter
        case (.preClose, .preCloseCompleted):
            return .encounter
        case (.encounter, .eyesClosedDurationMet):
            return .immersion
        case (.immersion, .immersionTimerCompleted):
            return .awakening
        case (.awakening, .animationCompleted):
            return proEnabled ? .postClose : .completed
        case (.postClose, .postCloseCompleted):
            return .completed
        default:
            return nil
        }
    }
}
