import Foundation

// MARK: - 内なる声タイプ（PQサボター分類）

/// ユーザーの内なる声パターン（PQ理論のサボター分類に基づく）
/// ユーザー向けには「もっと派」等の日本語ラベルを使用し、PQ用語は使わない
public enum InnerVoiceType: String, Codable, CaseIterable, Sendable {
    /// 🏃 もっと派（PQ: Hyper-Achiever）
    /// 「もっと良くできるはず。手を止めたら負ける」
    case hyperAchiever
    /// 🔍 完璧派（PQ: Stickler）
    /// 「あと少しで完璧になる。ここで止めるのは中途半端だ」
    case stickler
    /// ✨ 好奇心派（PQ: Restless）
    /// 「これも面白い、あれも気になる。全部やりたい」
    case restless
    /// 🎛️ 全部自分派（PQ: Controller）
    /// 「自分がやらないと誰もやらない」
    case controller

    /// ユーザー向け表示名
    public var displayName: String {
        switch self {
        case .hyperAchiever: return "もっと派"
        case .stickler: return "完璧派"
        case .restless: return "好奇心派"
        case .controller: return "全部自分派"
        }
    }

    /// ユーザー向けアイコン
    public var icon: String {
        switch self {
        case .hyperAchiever: return "🏃"
        case .stickler: return "🔍"
        case .restless: return "✨"
        case .controller: return "🎛️"
        }
    }

    /// 内なる声の台詞
    public var voiceQuote: String {
        switch self {
        case .hyperAchiever: return "もっと良くできるはず。手を止めたら負ける"
        case .stickler: return "あと少しで完璧になる。ここで止めるのは中途半端だ"
        case .restless: return "これも面白い、あれも気になる。全部やりたい"
        case .controller: return "自分がやらないと誰もやらない"
        }
    }

    /// 暴走パターンの説明
    public var runawayPattern: String {
        switch self {
        case .hyperAchiever: return "次々とタスクを追加して止まれない"
        case .stickler: return "一つのタスクに固執して完璧を追求"
        case .restless: return "新しいことに飛びついて本来の目的から脱線"
        case .controller: return "委譲できず全部抱え込んで暴走"
        }
    }
}

// MARK: - EQ自己認知レベル

/// 過集中中の自己認知レベル（EQ理論の自己認知に基づく）
public enum SelfAwarenessLevel: String, Codable, CaseIterable, Sendable {
    /// よく気づく
    case high
    /// たまに気づく
    case moderate
    /// 終わってから気づく
    case low
    /// 人に指摘されて気づく
    case veryLow

    public var displayText: String {
        switch self {
        case .high: return "よく気づく"
        case .moderate: return "たまに気づく"
        case .low: return "終わってから気づく"
        case .veryLow: return "人に指摘されて気づく"
        }
    }
}

// MARK: - EQ自己制御レベル

/// 気づいた後の行動変更能力（EQ理論の自己制御に基づく）
public enum SelfRegulationLevel: String, Codable, CaseIterable, Sendable {
    /// すぐ変えられる
    case canChange
    /// わかっていてもやめられない
    case knowButCant
    /// 変えようとするが結局戻る
    case triesButReverts
    /// 気づいても無視する
    case ignores

    public var displayText: String {
        switch self {
        case .canChange: return "すぐ変えられる"
        case .knowButCant: return "わかっていてもやめられない"
        case .triesButReverts: return "変えようとするが結局戻る"
        case .ignores: return "気づいても無視する"
        }
    }
}

// MARK: - 診断質問の選択肢

/// Q4: 予定と違う作業の頻度
public enum DeviationFrequency: String, Codable, CaseIterable, Sendable {
    case daily, severalTimesWeek, occasionally, rarely

    public var displayText: String {
        switch self {
        case .daily: return "毎日"
        case .severalTimesWeek: return "週に数回"
        case .occasionally: return "たまに"
        case .rarely: return "ほぼない"
        }
    }
}

/// Q5: 最長連続作業時間
public enum MaxFocusDuration: String, Codable, CaseIterable, Sendable {
    case oneToTwo, twoToFour, fourPlus, dontKnow

    public var displayText: String {
        switch self {
        case .oneToTwo: return "1-2時間"
        case .twoToFour: return "2-4時間"
        case .fourPlus: return "4時間以上"
        case .dontKnow: return "わからない（時計を見ない）"
        }
    }

    /// 知識教育で引用するための表示テキスト
    public var quoteText: String {
        switch self {
        case .oneToTwo: return "1-2時間"
        case .twoToFour: return "2-4時間"
        case .fourPlus: return "4時間以上"
        case .dontKnow: return "時計を見ないほど"
        }
    }
}

/// Q6: 過集中後の影響（複数選択）
public enum HyperFocusConsequence: String, Codable, CaseIterable, Sendable {
    case missedTasks, lateMeeting, forgotMeals, fatigue, guilt

    public var displayText: String {
        switch self {
        case .missedTasks: return "本来のタスクが漏れた"
        case .lateMeeting: return "会議に遅刻"
        case .forgotMeals: return "食事を忘れた"
        case .fatigue: return "疲労で次の作業に支障"
        case .guilt: return "罪悪感"
        }
    }
}

/// Q7: AIツール利用時の脱線
public enum AIDeviationFrequency: String, Codable, CaseIterable, Sendable {
    case often, sometimes, never, dontUseAI

    public var displayText: String {
        switch self {
        case .often: return "よくある"
        case .sometimes: return "たまに"
        case .never: return "ない"
        case .dontUseAI: return "AIは使わない"
        }
    }
}

/// Q9: 過集中後の最初の感情
public enum PostFocusEmotion: String, Codable, CaseIterable, Sendable {
    case selfBlame, justification, craving, exhaustion

    public var displayText: String {
        switch self {
        case .selfBlame: return "「なぜこんなことに時間を使ったんだ」"
        case .justification: return "「でもいい仕事はした」"
        case .craving: return "「もう少しやりたかったのに」"
        case .exhaustion: return "「疲れた、何も考えたくない」"
        }
    }
}

/// Q10: 切り上げるまでの時間
public enum StopDelay: String, Codable, CaseIterable, Sendable {
    case immediately, fiveToTen, thirtyPlus, cantThinkOfStopping

    public var displayText: String {
        switch self {
        case .immediately: return "すぐ止められる"
        case .fiveToTen: return "5-10分"
        case .thirtyPlus: return "30分以上"
        case .cantThinkOfStopping: return "そもそも「切り上げよう」と思えない"
        }
    }
}

/// Q11: 中断への抵抗感
public enum InterruptionResistance: String, Codable, CaseIterable, Sendable {
    case veryResistant, slightlyResistant, neutral, welcome

    public var displayText: String {
        switch self {
        case .veryResistant: return "すごく嫌（フローが壊れる）"
        case .slightlyResistant: return "少し嫌"
        case .neutral: return "気にしない"
        case .welcome: return "むしろ歓迎（助かる）"
        }
    }
}

/// Q14: メタ認知の習慣
public enum MetaCognitionHabit: String, Codable, CaseIterable, Sendable {
    case hasHabit, wantButCant, neverThought

    public var displayText: String {
        switch self {
        case .hasHabit: return "ある"
        case .wantButCant: return "作りたいが続かない"
        case .neverThought: return "考えたこともなかった"
        }
    }
}

/// Q15: Blindに一番期待すること
public enum BlindExpectation: String, Codable, CaseIterable, Sendable {
    case stopRunaway, rememberPriority, regularPause, restEyes

    public var displayText: String {
        switch self {
        case .stopRunaway: return "暴走を止めてほしい"
        case .rememberPriority: return "優先順位を思い出したい"
        case .regularPause: return "定期的に立ち止まりたい"
        case .restEyes: return "目を休めたい"
        }
    }
}

/// Q27: 体験後の気づき確認
public enum TrialReflectionAnswer: String, Codable, CaseIterable, Sendable {
    case yes, notSure

    public var displayText: String {
        switch self {
        case .yes: return "はい"
        case .notSure: return "まだわからない"
        }
    }
}

// MARK: - 診断結果

/// 全診断回答を保持する構造体
public struct DiagnosisResult: Codable, Sendable {
    // Block A: 過集中の実態
    public var deviationFrequency: DeviationFrequency?       // Q4
    public var maxFocusDuration: MaxFocusDuration?            // Q5
    public var consequences: [HyperFocusConsequence]?         // Q6（複数選択）
    public var aiDeviation: AIDeviationFrequency?             // Q7

    // Block B: 内なる声のパターン
    public var innerVoiceType: InnerVoiceType?                // Q8
    public var postFocusEmotion: PostFocusEmotion?            // Q9
    public var stopDelay: StopDelay?                          // Q10
    public var interruptionResistance: InterruptionResistance? // Q11

    // Block C: 気づきと行動のギャップ
    public var selfAwareness: SelfAwarenessLevel?             // Q12
    public var selfRegulation: SelfRegulationLevel?           // Q13
    public var metaCognitionHabit: MetaCognitionHabit?        // Q14
    public var blindExpectation: BlindExpectation?             // Q15

    // 体験後の確認
    public var trialReflection: TrialReflectionAnswer?        // Q27

    // トレーニング時間帯
    public var trainingWindow: TrainingWindowChoice?

    public init() {}

    /// 推奨リマインド間隔（分）
    public var recommendedInterval: Int {
        guard let duration = maxFocusDuration else { return 30 }
        switch duration {
        case .oneToTwo: return 30
        case .twoToFour: return 20
        case .fourPlus, .dontKnow: return 15
        }
    }

    /// 推奨閉眼時間（秒）
    public var recommendedEyeCloseDuration: Int {
        guard let resistance = interruptionResistance else { return 5 }
        switch resistance {
        case .veryResistant: return 3
        case .slightlyResistant: return 5
        case .neutral, .welcome: return 5
        }
    }

    /// 推奨1日トレーニング回数目標
    public var recommendedDailyGoal: Int {
        guard let interval = maxFocusDuration else { return 8 }
        switch interval {
        case .oneToTwo: return 6
        case .twoToFour: return 8
        case .fourPlus, .dontKnow: return 10
        }
    }
}

// MARK: - パーソナライズプラン

/// 診断結果から生成されるパーソナライズプラン
public struct PersonalizedPlan: Codable, Sendable {
    /// リマインド間隔（分）
    public let reminderInterval: Int
    /// 閉眼時間（秒）
    public let eyeCloseDuration: Int
    /// 1日のトレーニング目標回数
    public let dailyGoal: Int
    /// 判定された内なる声タイプ
    public let innerVoiceType: InnerVoiceType?
    /// トレーニング時間帯
    public let trainingSchedule: TrainingSchedule

    public init(from diagnosis: DiagnosisResult) {
        self.reminderInterval = diagnosis.recommendedInterval
        self.eyeCloseDuration = diagnosis.recommendedEyeCloseDuration
        self.dailyGoal = diagnosis.recommendedDailyGoal
        self.innerVoiceType = diagnosis.innerVoiceType
        self.trainingSchedule = diagnosis.trainingWindow?.schedule ?? .standard
    }
}
