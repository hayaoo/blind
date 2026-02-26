import Foundation

public enum SessionPhase: Equatable, Sendable {
    case idle           // セッション未開始
    case summon         // Phase 1: ノッチからUI出現 (~0.6s)
    case encounter      // Phase 2: 目キャラがEyeStateに反応
    case immersion      // Phase 3: フルスクリーン黒 + 音量ダウン (5s設定可)
    case awakening      // Phase 4: 縮小 + 音量復帰 + ウインク (~2.0s)
    case completed      // セッション完了
    case cancelled      // キャンセル
}

public enum SessionPhaseTransition {
    public enum Trigger: Equatable, Sendable {
        case animationCompleted
        case eyesClosedDurationMet
        case immersionTimerCompleted
        case userCancelled
    }

    public static func next(from phase: SessionPhase, trigger: Trigger) -> SessionPhase? {
        // キャンセルはアクティブなフェーズからのみ可能
        if trigger == .userCancelled {
            switch phase {
            case .summon, .encounter, .immersion, .awakening:
                return .cancelled
            default:
                return nil
            }
        }

        switch (phase, trigger) {
        case (.summon, .animationCompleted):
            return .encounter
        case (.encounter, .eyesClosedDurationMet):
            return .immersion
        case (.immersion, .immersionTimerCompleted):
            return .awakening
        case (.awakening, .animationCompleted):
            return .completed
        default:
            return nil
        }
    }
}
