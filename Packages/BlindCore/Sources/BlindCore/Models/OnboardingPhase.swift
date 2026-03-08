import Foundation

/// 拡張オンボーディングの全フェーズ（33画面 + Day 2-7）
public enum OnboardingPhase: Equatable, Sendable {

    // MARK: - Day 1: 導入（3画面）

    /// #1: はじめまして！
    case welcome
    /// #2: 過集中のフック質問
    case hook
    /// #3: 「5分であなた専用の中断プランを作ります」
    case promise

    // MARK: - Day 1: 自己診断 Block A — 過集中の実態（4問）

    /// #4: 予定と違う作業をしていた頻度
    case diagnosisA1
    /// #5: 最長連続作業時間
    case diagnosisA2
    /// #6: 過集中後の影響（複数選択）
    case diagnosisA3
    /// #7: AIツール利用時の脱線
    case diagnosisA4

    // MARK: - Day 1: ブリッジ A→B

    /// Block A→B のブリッジ画面
    case diagnosisBridgeAB

    // MARK: - Day 1: 自己診断 Block B — 内なる声のパターン（4問）

    /// #8: 没頭時の内なる声（PQサボター分類）
    case diagnosisB1
    /// #9: 過集中後の最初の感情
    case diagnosisB2
    /// #10: 切り上げるまでの時間
    case diagnosisB3
    /// #11: 中断への抵抗感
    case diagnosisB4

    // MARK: - Day 1: ブリッジ B→C

    /// Block B→C のブリッジ画面
    case diagnosisBridgeBC

    // MARK: - Day 1: 自己診断 Block C — 気づきと行動のギャップ（4問）

    /// #12: 過集中中に気づくか（EQ自己認知レベル）
    case diagnosisC1
    /// #13: 気づいた後に行動を変えられるか（EQ自己制御レベル）
    case diagnosisC2
    /// #14: 定期的確認の習慣
    case diagnosisC3
    /// #15: Blindに一番期待すること
    case diagnosisC4

    // MARK: - Day 1: 知識教育（9画面）

    /// #16: 象と象使い — 2つの集中
    case knowledgeElephant1
    /// #17: あなたの象（Q5回答引用）
    case knowledgeElephant2
    /// #18: 内なる声の正体（Q8回答引用）
    case knowledgeVoice1
    /// #19: 声の4タイプ
    case knowledgeVoice2
    /// #20: 声の仕組み（敵ではない）
    case knowledgeVoice3
    /// #21: 気づきの力（Q12回答引用）
    case knowledgeAwareness1
    /// #22: ギャップ（Q13回答引用、自責解除）
    case knowledgeAwareness2
    /// #23: 5秒の構造（3ステップ）
    case knowledgeFiveSeconds1
    /// #24: なぜ5秒で十分か
    case knowledgeFiveSeconds2

    // MARK: - Day 1: 体験（3画面）

    /// #25: カメラ権限要求
    case camera
    /// #26: ミニセッション（3秒閉眼）
    case trySession
    /// #27: 気づきの確認
    case trialReflection

    // MARK: - Day 1: パーソナライズプラン提示（4画面）

    /// #28: ローディング演出
    case planLoading
    /// #29: プラン概要（処方箋）
    case planOverview
    /// #30: あなたの内なる声タイプ
    case planVoiceType
    /// #31: Pro予告（7日後のレポート）
    case planProPreview

    // MARK: - Day 1: ソフトペイウォール（1画面）

    /// #32: Pro紹介（軽い導入）
    case softPaywall

    // MARK: - Day 1: 完了（1画面）

    /// #33: 準備完了
    case done

    // MARK: - Day 2-6: デイリーTips

    /// Day 2-6 デイリーTip表示
    case dailyTip(day: Int)

    // MARK: - Day 7: 成果レポート + ハードペイウォール

    /// Day 7: トレーニング記録
    case reportTrainingLog
    /// Day 7: 暴走パターン（ヒートマップ）
    case reportRunawayPattern
    /// Day 7: 気づきの成長
    case reportGrowth
    /// Day 7: Pro価値提案
    case hardPaywallValue
    /// Day 7: 選択（Pro / 無料で続ける）
    case hardPaywallChoice
}

// MARK: - Navigation

extension OnboardingPhase {

    /// Day 1 の全フェーズを順序通りに返す
    public static var day1Sequence: [OnboardingPhase] {
        [
            // 導入
            .welcome, .hook, .promise,
            // 診断 Block A
            .diagnosisA1, .diagnosisA2, .diagnosisA3, .diagnosisA4,
            .diagnosisBridgeAB,
            // 診断 Block B
            .diagnosisB1, .diagnosisB2, .diagnosisB3, .diagnosisB4,
            .diagnosisBridgeBC,
            // 診断 Block C
            .diagnosisC1, .diagnosisC2, .diagnosisC3, .diagnosisC4,
            // 知識教育
            .knowledgeElephant1, .knowledgeElephant2,
            .knowledgeVoice1, .knowledgeVoice2, .knowledgeVoice3,
            .knowledgeAwareness1, .knowledgeAwareness2,
            .knowledgeFiveSeconds1, .knowledgeFiveSeconds2,
            // 体験
            .camera, .trySession, .trialReflection,
            // プラン提示
            .planLoading, .planOverview, .planVoiceType, .planProPreview,
            // ペイウォール
            .softPaywall,
            // 完了
            .done,
        ]
    }

    /// Day 7 レポートの全フェーズ
    public static var day7Sequence: [OnboardingPhase] {
        [
            .reportTrainingLog, .reportRunawayPattern, .reportGrowth,
            .hardPaywallValue, .hardPaywallChoice,
        ]
    }

    /// 現在のフェーズのDay 1シーケンス内インデックス（0-based）
    public var day1Index: Int? {
        Self.day1Sequence.firstIndex(of: self)
    }

    /// Day 1の全画面数
    public static var day1ScreenCount: Int { day1Sequence.count }

    /// 診断フェーズかどうか
    public var isDiagnosis: Bool {
        switch self {
        case .diagnosisA1, .diagnosisA2, .diagnosisA3, .diagnosisA4,
             .diagnosisBridgeAB,
             .diagnosisB1, .diagnosisB2, .diagnosisB3, .diagnosisB4,
             .diagnosisBridgeBC,
             .diagnosisC1, .diagnosisC2, .diagnosisC3, .diagnosisC4:
            return true
        default:
            return false
        }
    }

    /// 知識教育フェーズかどうか
    public var isKnowledge: Bool {
        switch self {
        case .knowledgeElephant1, .knowledgeElephant2,
             .knowledgeVoice1, .knowledgeVoice2, .knowledgeVoice3,
             .knowledgeAwareness1, .knowledgeAwareness2,
             .knowledgeFiveSeconds1, .knowledgeFiveSeconds2:
            return true
        default:
            return false
        }
    }

    /// 体験フェーズかどうか
    public var isExperience: Bool {
        switch self {
        case .camera, .trySession, .trialReflection:
            return true
        default:
            return false
        }
    }

    /// ブリッジ画面かどうか
    public var isBridge: Bool {
        switch self {
        case .diagnosisBridgeAB, .diagnosisBridgeBC:
            return true
        default:
            return false
        }
    }

    /// このフェーズに必要なテキスト帯の高さ
    public var contentHeight: NotchGeometry.OnboardingContentHeight {
        switch self {
        // 導入
        case .welcome, .promise: return .info
        case .hook: return .infoLarge

        // 診断ブリッジ
        case .diagnosisBridgeAB, .diagnosisBridgeBC: return .bridge

        // 診断質問
        case .diagnosisA3: return .questionLarge // 複数選択（5つ）
        case .diagnosisB1: return .questionLarge // 長い台詞の選択肢
        case .diagnosisA1, .diagnosisA2, .diagnosisA4,
             .diagnosisB2, .diagnosisB3, .diagnosisB4,
             .diagnosisC1, .diagnosisC2, .diagnosisC3, .diagnosisC4:
            return .question

        // 知識教育
        case .knowledgeElephant1, .knowledgeElephant2: return .infoLarge
        case .knowledgeVoice1, .knowledgeVoice3: return .infoLarge
        case .knowledgeVoice2: return .cards // 4タイプカード表示
        case .knowledgeAwareness1, .knowledgeAwareness2: return .infoLarge
        case .knowledgeFiveSeconds1: return .infoLarge
        case .knowledgeFiveSeconds2: return .infoLarge

        // 体験
        case .camera: return .info
        case .trySession: return .info // encounterフレームに切り替わる
        case .trialReflection: return .info

        // プラン提示
        case .planLoading: return .info
        case .planOverview: return .infoLarge
        case .planVoiceType: return .info
        case .planProPreview: return .info

        // ペイウォール
        case .softPaywall: return .paywall

        // 完了
        case .done: return .info

        // Day 2-7
        case .dailyTip: return .infoLarge
        case .reportTrainingLog, .reportRunawayPattern, .reportGrowth: return .cards
        case .hardPaywallValue: return .paywall
        case .hardPaywallChoice: return .info
        }
    }
}
