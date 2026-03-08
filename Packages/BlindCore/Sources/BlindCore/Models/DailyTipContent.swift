import Foundation

/// Day 2-6 のデイリーTipコンテンツ
public struct DailyTipContent: Sendable {
    public let day: Int
    public let theme: String
    public let message: String
    public let proTeaser: String

    /// Day 2-6 の全Tipコンテンツ
    public static func tip(for day: Int, sessionCount: Int = 0) -> DailyTipContent? {
        switch day {
        case 2:
            return DailyTipContent(
                day: 2,
                theme: "内なる声を聞く",
                message: "今日のセッションで目を閉じた瞬間、頭の中でどんな声が聞こえましたか？\n「あと少しだけ...」ならそれが内なる声です。\n聞こえたら、トレーニング成功です。",
                proTeaser: "Proなら、セッションごとにどの声が聞こえたかを記録して振り返れます"
            )
        case 3:
            return DailyTipContent(
                day: 3,
                theme: "気づきの筋肉",
                message: "「気づく力」は筋肉です。\n昨日より今日、今日より明日。\n毎回のセッションが1レップ。\nすでに\(sessionCount)回トレーニングしました。",
                proTeaser: "Proなら気づきの筋力の成長をグラフで追跡できます"
            )
        case 4:
            return DailyTipContent(
                day: 4,
                theme: "象使いの地図",
                message: "目を閉じた5秒間——\n「今、正しいことをしているか？」と自分に問いかけてみてください。\n象使いが地図を広げる瞬間です。",
                proTeaser: "Proなら目を閉じる前に今日の優先事項を表示。地図を毎回見せます"
            )
        case 5:
            return DailyTipContent(
                day: 5,
                theme: "AIと内なる声",
                message: "AIとの作業中、「もう少し深掘りしよう」の声が聞こえたら——\nそれは内なる声かもしれません。\n5秒目を閉じて、象使いに確認してみてください。",
                proTeaser: "Proならスキップが続いた時（=象が暴走中）に強めに介入します"
            )
        case 6:
            return DailyTipContent(
                day: 6,
                theme: "明日の予告",
                message: "6日間で\(sessionCount)回の「気づきのトレーニング」を行いました。\n明日、あなたの成長をデータでお見せします。",
                proTeaser: "明日、7日間のレポートをお届けします"
            )
        default:
            return nil
        }
    }
}

/// Day 7 成果レポートの画面コンテンツ
public struct Day7ReportContent: Sendable {
    /// トレーニング記録
    public let totalSessions: Int
    public let totalClosedDuration: TimeInterval
    public let skippedSessions: Int
    public let skipRate: Double

    /// 暴走パターン
    public let dominantVoiceType: InnerVoiceType?
    public let peakSkipDayHour: (weekday: Int, hour: Int)?

    /// 気づきの成長
    public let courseCorrections: Int
    public let initialSelfRegulation: SelfRegulationLevel?

    public init(
        stats: OnboardingDataStore.WeeklyStats,
        diagnosis: DiagnosisResult?
    ) {
        self.totalSessions = stats.totalSessions
        self.totalClosedDuration = stats.totalClosedDuration
        self.skippedSessions = stats.skippedSessions
        self.skipRate = stats.skipRate
        self.courseCorrections = stats.courseCorrections
        self.initialSelfRegulation = diagnosis?.selfRegulation

        // 最も多い内なる声タイプ
        self.dominantVoiceType = stats.voiceDistribution
            .max(by: { $0.value < $1.value })?.key

        // スキップが最も多い曜日×時間帯
        self.peakSkipDayHour = stats.skipsByDayHour.first.map {
            (weekday: $0.weekday, hour: $0.hour)
        }
    }

    /// 曜日番号→日本語表示
    public static func weekdayName(_ weekday: Int) -> String {
        let names = ["", "日", "月", "火", "水", "木", "金", "土"]
        guard weekday >= 1 && weekday <= 7 else { return "" }
        return names[weekday]
    }
}
