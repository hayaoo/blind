import Foundation

/// オンボーディングの4ステップ
public enum OnboardingPhase: Equatable, Sendable {
    /// Step 1: アプリ紹介、目キャラ出現
    case welcome
    /// Step 2: カメラ権限の説明と要求
    case camera
    /// Step 3: お試しセッション（短縮版）
    case trySession
    /// Step 4: 完了メッセージ
    case done
}
