# ADR-0004: 拡張オンボーディング・トレーニングサイクル・スマートリマインド

## Status

Accepted

## Date

2026-03-08

## Context

ADR-0003の4ステップオンボーディングは「最速で体験を味わってもらう」設計だった。しかし以下の課題が浮上した：

1. **離脱**: ユーザーが最初の数日でBlindを忘れてしまう（生活に溶け込む反面、見えなくなる）
2. **スキップの連鎖**: 通知が来ても「後で」を押し続け、トレーニングが形骸化する
3. **価値の不明確さ**: なぜ5秒目を閉じることが有効なのか、ユーザーが腹落ちしないまま使い始める
4. **Pro機能の価値提案不在**: 無料版だけでは深いトレーニングにならない
5. **固定30分間隔**: ユーザーの生活リズムを無視した通知タイミング

これらを解決するために、オンボーディングの拡張、セッションのトレーニングサイクル化、スマートリマインドの3つを設計・実装した。

## Decision

### 1. 拡張オンボーディング（Day 1: 33画面フロー）

ADR-0003の4ステップを**33画面**に拡張。ただし1画面あたり3-5秒で完了するため、全体で約5分。

#### 構成

| セクション | 画面数 | 目的 |
|-----------|--------|------|
| 導入（welcome/hook/promise） | 3 | 共感と約束 |
| 診断 Block A（働き方の実態） | 4+1 | Q4-Q7 + ブリッジ |
| 診断 Block B（内なる声のパターン） | 4+1 | Q8-Q11 + ブリッジ |
| 診断 Block C（気づきの力） | 4 | Q12-Q15 |
| 知識教育 | 9 | 象使いメタファー、内なる声4タイプ、5秒の構造 |
| 体験（camera/trySession/reflection） | 3 | 実際に目を閉じる |
| プラン提示 | 5 | 処方箋、時間帯選択、声タイプ、Pro予告 |
| ソフトペイウォール | 1 | 軽い導入 |
| 完了 | 1 | 「準備完了！」 |

#### 診断から導かれるパーソナライズ

```
Q5（最長集中時間）→ リマインド間隔（15/20/30分）
Q8（内なる声タイプ）→ 暴走パターンの理解
Q11（中断への抵抗感）→ 閉眼時間（3/5秒）
Q12/Q13 → 知識教育セクションのパーソナライズテキスト
トレーニング時間帯 → TimerServiceの発火制御
```

#### 動的フレーム高さ

33画面はコンテンツ量が異なるため、ノッチUIのフレーム高さをフェーズごとに動的変更する：

| コンテンツタイプ | 高さ | 用途 |
|----------------|------|------|
| bridge | 100pt | ブリッジテキスト |
| info | 140pt | 情報画面 |
| infoLarge | 180pt | パーソナライズテキスト |
| question | 240pt | 4選択肢 |
| questionLarge | 280pt | 5選択肢/複数選択 |
| cards | 260pt | 4タイプカード表示 |
| paywall | 320pt | 機能カード+CTA |

`NotchGeometry.OnboardingContentHeight` enumで管理し、`NotchOverlayWindow.animateToOnboarding(contentHeight:)` で0.3秒アニメーションで遷移。

#### Day 2-6: デイリーTips

セッション完了後に1日1つのTipを表示。メタファーの定着と習慣化を促進。

#### Day 7: 成果レポート + ハードペイウォール

5画面構成：
1. **トレーニング記録**: セッション数、閉眼時間、スキップ率
2. **暴走パターン**: 内なる声の分布、スキップが多い曜日×時間帯
3. **気づきの成長**: 軌道修正回数、初日回答との比較
4. **Pro価値提案**: スキップ率に連動したデータ駆動の訴求
5. **選択画面**: Pro購入 or 無料継続

### 2. トレーニングサイクル（Pro機能: Pre-close / Post-close）

通常のセッション（summon → encounter → immersion → awakening → completed）に2つのフェーズを追加：

```
summon → [preClose] → encounter → immersion → awakening → [postClose] → completed
```

#### Pre-close（目を閉じる前）

「今、どの声が聞こえていますか？」

- 4タイプの内なる声から選択 + 「静か」オプション
- **目的**: 暴走の「気づき」をトレーニング。ラベリングすることで声を客体化する

#### Post-close（目を開けた後）

「象使いの判断——今から何をしますか？」

- 4つの行動: 続ける / 方向転換 / 意図的 / まだ必要
- **目的**: メタ認知を行動に接続する。「方向転換」を選ぶ = 軌道修正カウント

#### データ記録

`SessionLogEntry`に`preCloseVoice`と`postCloseAction`を記録。Day 7レポートの素材になる。

### 3. スマートリマインド

#### トレーニング時間帯（コミットメント設計）

オンボーディングのプラン提示後に「いつトレーニングしますか？」と聞く：

| 選択肢 | 時間帯 |
|--------|--------|
| 朝型 | 9:00-18:00 |
| 標準 | 10:00-19:00 |
| 遅め | 11:00-20:00 |
| ロング | 9:00-21:00 |

**ユーザー自身が宣言する**ことでコミットメントを引き出す。時間帯外はリマインドをスキップ。

#### 5分猶予（スヌーズの代替）

- 通知に「5分だけ猶予」アクションを追加
- **1リマインドにつき1回だけ**使用可能（2回目は猶予ボタンが消える）
- 従来のスヌーズ（15分/30分/1時間）ではなく、短い猶予+回数制限で先延ばしの連鎖を構造的に防止
- 猶予使用回数を累計記録（Day 7レポートの素材）

#### 暴走エスカレーション

`OnboardingDataStore.consecutiveSkips`を活用：

| 連続スキップ | 間隔変更 | 通知テキスト |
|------------|----------|------------|
| 0-1回 | 通常 | 「目を休めよう」 |
| 2回 | 半分に短縮 | 「象が走り出しています」 |
| 3回以上 | 1/3に短縮 | 「象が暴走しています」 |

セッション完了で`consecutiveSkips`リセット。

## Implementation

### 新規ファイル

| ファイル | 責務 |
|---------|------|
| `BlindCore/Models/TrainingSchedule.swift` | 時間帯モデル、プリセット、GraceState |
| `BlindCore/Models/DailyTipContent.swift` | Day 2-6 Tip、Day7ReportContent |
| `BlindCore/Models/SessionLog.swift` | セッションログ、PostCloseAction、DailyTipStatus |

### 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `BlindCore/Models/OnboardingPhase.swift` | 33画面+Day7の全フェーズ enum、contentHeight、day1Sequence/day7Sequence |
| `BlindCore/Models/DiagnosisModels.swift` | 12問の診断enum群、DiagnosisResult、PersonalizedPlan（trainingSchedule追加） |
| `BlindCore/Models/SessionPhase.swift` | preClose/postClose追加、proEnabled引数 |
| `BlindCore/Models/NotchGeometry.swift` | OnboardingContentHeight enum、動的onboardingFrame() |
| `BlindCore/Models/BlindSettings.swift` | trainingSchedule保存/読込 |
| `BlindCore/Services/TimerService.swift` | 時間帯制御、猶予、エスカレーション |
| `BlindCore/Services/NotificationService.swift` | エスカレーション対応テキスト、猶予アクション |
| `BlindCore/Services/OnboardingDataStore.swift` | セッションログ、WeeklyStats、consecutiveSkips |
| `App/ViewModels/ExtendedOnboardingViewModel.swift` | 33画面フロー管理、Day7フロー |
| `App/ViewModels/SessionViewModel.swift` | preClose/postClose、Pro判定 |
| `App/Views/ExtendedOnboardingTextBar.swift` | 33画面+Day7レポートの全UI |
| `App/Views/NotchSessionView.swift` | proTrainingBar（Pre-close/Post-close UI） |
| `App/Windows/NotchOverlayWindow.swift` | animateToOnboarding(contentHeight:) |
| `App/AppDelegate.swift` | Day7トリガー、セッションログ記録、エスカレーション通知 |

## Risks and Mitigations

### Risk 1: 33画面は長すぎる

各画面3-5秒、全体5分。スキップ機能あり（診断ブロック単位/全体）。知識教育セクションはパーソナライズテキストで退屈させない。

### Risk 2: Pre-close/Post-closeがセッションを煩雑にする

Pro機能のため無料版には影響なし。Pre-closeは4タップ+「静か」、Post-closeは1タップ。合計2-3秒の追加。

### Risk 3: エスカレーションがユーザーを不快にする

テキストはメタファー（象）を使い、直接的な非難ではなく「気づき」の文脈で表現。間隔短縮もセッション完了で即リセット。

### Risk 4: カレンダー連携の不在

EventKit連携はPro機能として後回し。現時点ではアプリ内のトレーニング時間帯設定で十分。将来的にはトレーニング枠（1ブロック）をカレンダーに登録する設計を検討。

## Alternatives Considered

### A) スヌーズ（15分/30分/1時間）

却下。先延ばしの連鎖を生む。「5分猶予×1回」のほうが行動変容に効く。

### B) 固定時間帯（9-18時ハードコード）

却下。ユーザーの生活リズムは多様。選択させることでコミットメントを引き出す。

### C) 診断なしのデフォルトプラン

却下。診断はパーソナライズの根拠を作るだけでなく、「自分の問題を言語化する」プロセス自体がトレーニングの一部。

## Consequences

- **Positive**: 初回体験の質向上、離脱防止、Pro価値の体感、データ駆動のペイウォール
- **Negative**: コードベースの複雑さ増加（OnboardingPhase 33ケース）、ExtendedOnboardingTextBarの行数
- **Neutral**: 既存のノッチUIを再利用しているため、視覚的一貫性は維持
