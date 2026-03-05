# ADR-0003: 初回オンボーディングフロー

## Status

Accepted

## Date

2026-03-05

## Context

現在のBlindアプリは初回起動時にカメラ権限ダイアログがいきなり表示され、ユーザーはアプリの目的を理解する前に判断を迫られる。また「目を閉じる」というユニークな操作の説明がないため、初回セッションでユーザーが戸惑うリスクがある。

Blindのブランド（コミカルでかわいい目キャラ）を活かし、既存のノッチUIを再利用したオンボーディングで、最速で「目を閉じる体験」を味わってもらう。

## Decision

### オンボーディング4ステップ

既存のノッチUI（NotchOverlayWindow + NotchSessionView）を拡張し、`OnboardingPhase`として実装する。

| Step | 名前 | 内容 | UI構成 |
|------|------|------|--------|
| 1 | Welcome | 目キャラが出現、アプリ説明 | ノッチ + 拡張テキスト帯 |
| 2 | Camera | カメラ権限の説明と要求 | ノッチ + 拡張テキスト帯 + ボタン |
| 3 | Try | お試しセッション（2秒短縮版） | 通常セッションと同じ（encounterフェーズ） |
| 4 | Done | 完了メッセージ、リマインダー説明 | ノッチ + 拡張テキスト帯 |

### Step 1: Welcome（歓迎）

- 目キャラがノッチから降りてくる（summon → encounter遷移アニメーション）
- 目キャラ状態: `.idle` → キョロキョロ
- テキスト帯を **拡張テキスト帯** に置換:
  - メインテキスト: 「はじめまして！」（16pt, bold）
  - サブテキスト: 「Blindは、画面から離れる小さな休憩を作るアプリです」（13pt）
  - 「次へ」ボタン + ×ボタン（スキップ）
- 拡張テキスト帯の高さ: 80pt（通常36ptから拡大）

### Step 2: Camera（カメラ権限）

- 目キャラ状態: `.searching`（左右を見回す）
- 拡張テキスト帯:
  - メインテキスト: 「カメラを使います」
  - サブテキスト: 「目を閉じたことを感知するために使います。映像は保存・送信しません。」（13pt）
  - 「カメラを許可する」ボタン（プライマリ） + ×ボタン（スキップ）
- ボタン押下 → `AVCaptureDevice.requestAccess` → macOS標準ダイアログ
- 許可 → Step 3へ自動遷移
- 拒否 → 「後から設定で変更できます」を表示して Step 4へスキップ

### Step 3: Try（お試しセッション）

- 通常セッションのencounterフェーズをそのまま実行
- `requiredClosedDuration`を一時的に **2秒** に短縮（最速体験）
- テキスト帯は通常表示:「目を閉じて、今を確かめよう」
- 目を閉じる → 目キャラが一緒に閉じる → 2秒後にStep 4
- バックドロップ（全画面黒）は **なし**（初回なので驚かせない）
- 音量制御も **なし**（初回なので安心感を優先）

### Step 4: Done（完了）

- 目キャラ状態: `.winking`
- 拡張テキスト帯:
  - メインテキスト: 「準備完了！」
  - サブテキスト: 「30分ごとにお知らせします。設定はメニューバーからいつでも。」
  - 「はじめる」ボタン（プライマリ）
- ボタン押下 or 3秒後 → ノッチに吸い込まれて消える（animateToDisappear）
- `UserDefaults("onboardingCompleted") = true`

### 拡張テキスト帯

通常のテキスト帯（36pt高、テキスト+×ボタン）を拡張した2行レイアウト:

```
┌─────────────────────────────────────┐
│ メインテキスト（16pt bold）      [×] │
│ サブテキスト（13pt, opacity 0.6）    │
│                        [ボタン]      │
└─────────────────────────────────────┘
```

- 高さ: 80pt
- 背景: 黒、角丸10pt（通常テキスト帯と同じスタイル）
- ボタン: 白背景 + 黒テキスト、角丸8pt、高さ28pt
- ×ボタン: 右上固定（通常テキスト帯と同じデザイン）

### 状態管理

```swift
// BlindCore/Models/OnboardingPhase.swift
public enum OnboardingPhase: Equatable, Sendable {
    case welcome
    case camera
    case trySession
    case done
}
```

```swift
// AppDelegate側
let isFirstLaunch = !UserDefaults.standard.bool(forKey: "onboardingCompleted")
if isFirstLaunch {
    startOnboarding()  // オンボーディングフロー
} else {
    // 通常動作（タイマー開始のみ）
}
```

### ディスプレイモード対応

3モード（`.notch` / `.noNotch` / `.island`）すべてで同じフローが動作する。既存のNotchGeometryとNotchOverlayWindowを再利用するため、モード差は自動吸収。

拡張テキスト帯のウィンドウフレーム計算:
- `encounterFrame`の代わりに`onboardingFrame`を新設
- `summonFrame + gapHeight + 拡張テキスト帯高さ(80pt)`

### スキップ・再表示

- ×ボタンでいつでもスキップ可能 → `onboardingCompleted = true`
- 設定画面に「チュートリアルを再表示」ボタン → `onboardingCompleted = false` + 即座にオンボーディング開始

## Implementation Plan

### ファイル構成

**BlindCore（新規）**:
- `Models/OnboardingPhase.swift` — Phase enum

**App層（新規）**:
- `Views/OnboardingTextBar.swift` — 拡張テキスト帯View

**App層（変更）**:
- `Views/NotchSessionView.swift` — オンボーディングモード対応（拡張テキスト帯表示）
- `Models/NotchGeometry.swift` — `onboardingFrame`追加
- `AppDelegate.swift` — 初回起動判定 + `startOnboarding()`
- `ViewModels/SessionViewModel.swift` — オンボーディングモード対応
- `Windows/NotchOverlayWindow.swift` — `animateToOnboarding()` 追加
- `Views/SettingsView.swift` — 「チュートリアルを再表示」追加

### タスク分割

| # | タスク | 依存 |
|---|--------|------|
| 1 | `OnboardingPhase` enum作成 | なし |
| 2 | `NotchGeometry`に`onboardingFrame`追加 + テスト | 1 |
| 3 | `OnboardingTextBar` View作成 | 1 |
| 4 | `NotchSessionView`にオンボーディングモード統合 | 2, 3 |
| 5 | `SessionViewModel`にオンボーディングフロー追加 | 1 |
| 6 | `NotchOverlayWindow`にアニメーション追加 | 2 |
| 7 | `AppDelegate`に初回判定 + startOnboarding | 4, 5, 6 |
| 8 | 設定画面に再表示ボタン追加 | 7 |
| 9 | 統合テスト + 手動検証 | 全て |

## Risks and Mitigations

### Risk 1: 拡張テキスト帯のサイズがフォントに対して小さい

テキスト帯の幅がノッチ幅（.noNotchで280pt）に制約される。長い文章は2行に折り返すか、フォントサイズを調整。

対策: メインテキストは短く（8文字以内）、サブテキストは1-2行に収める。必要なら拡張テキスト帯の幅だけノッチより広くする。

### Risk 2: カメラ拒否後のUX

カメラを拒否してもオンボーディングは完了するが、セッション開始時にはカメラが必要。

対策: セッション開始時の権限チェック（今回実装済み）で案内する。オンボーディングStep 2で拒否した場合はStep 3をスキップして完了。

### Risk 3: お試しセッション中のクラッシュ

通常セッションと同じ6層防御が適用される。ただしバックドロップなし・音量制御なしなので、リスクは通常より低い。

## Alternatives Considered

### A) 別ウィンドウでの説明画面

macOS設定アシスタント風の独立ウィンドウ。確実だが、Blindの体験（ノッチに住むキャラクター）との一貫性がない。

### B) 通知ベースのガイド

UserNotificationで段階的にガイド。実装は簡単だが、ユーザーが通知を見逃す可能性が高い。

### C) ウェブページへの誘導

初回起動時にブラウザでガイドページを開く。オフラインで動かない、体験が分断される。

## Consequences

- **Positive**: 初回体験の質向上、カメラ権限の自然な導入、ブランド一貫性
- **Negative**: NotchSessionViewの複雑さ増加、テスト困難（初回状態の再現）
- **Neutral**: 既存UIの再利用により追加コードは最小限
