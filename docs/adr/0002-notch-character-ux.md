# ADR-0002: ノッチキャラクター没入型セッションUX

## Status

Accepted

## Date

2026-02-26

## Context

現在のセッションUIは200x120の小さなフローティングウィンドウに色付き丸とテキストを表示するだけで、機能的ではあるがマインドフルネス体験としての感情的共鳴がない。

「ノッチに住む目のキャラクターとの対話」という新UXによって、MacBookのノッチ（物理的な黒い領域）をデザインに取り込み、他にないマインドフルネス体験を作る。

## Decision

セッションUXを4フェーズ構成に刷新する。

### 4フェーズ設計

| Phase | 名前 | 時間 | 概要 |
|-------|------|------|------|
| 1 | Summon（召喚） | ~0.6s | ノッチから黒UIが拡張、目キャラ出現 |
| 2 | Encounter（邂逅） | ユーザー依存 | 目キャラがEyeStateに反応、メッセージ表示 |
| 3 | Immersion（没入） | 5s（設定可） | 画面全体を覆う黒 + 音量フェードダウン |
| 4 | Awakening（覚醒） | ~2.0s | 森林音 + 黒縮小 + 音量復帰 + ウインク |

### ノッチ検出

macOS 12+ APIを使用:

```swift
NSScreen.safeAreaInsets.top > 0           // ノッチあり
NSScreen.auxiliaryTopLeftArea             // ノッチ左の空き領域
NSScreen.auxiliaryTopRightArea            // ノッチ右の空き領域
```

- **ノッチあり**: ノッチの黒と融合するUIを表示
- **ノッチなし**（iMac/外部ディスプレイ/旧Mac）: 画面上部中央に黒い丸角ピルとして表示。フェーズ動作は同一、起点の形状だけ異なる

### 音量制御

CoreAudio直接操作（外部依存なし、アクセシビリティ権限不要）:

- `AudioObjectGetPropertyData` / `AudioObjectSetPropertyData`
- `kAudioHardwareServiceDeviceProperty_VirtualMainVolume`
- フェード: 16ms間隔タイマーで線形補間
- `emergencyRestore()`: クラッシュ時即座に音量復帰
- 最低音量0.02（完全無音にしない）

### 目キャラクター

SwiftUI `Canvas` + `TimelineView(.animation)` で60fps描画:

- 白目（楕円）+ 虹彩（円）+ 瞳孔（小円）+ 上下まぶた（ベジエ曲線）
- コード描画 → 解像度非依存＋アニメーション自在

EyeState連動:

| EyeState | キャラ挙動 |
|----------|-----------|
| `.noFace` | キョロキョロ探索（正弦波的に左右上下） |
| `.open` | ユーザーにロックオン、定期まばたき、メッセージ表示 |
| `.closed` | まぶたが閉じるアニメーション → Phase 3へ |

Phase 4 覚醒時: 右目が先に開き、左目が0.2s遅れて開く（ウインク）

### アーキテクチャ

**BlindCore（新規）**:
- `Models/SessionPhase.swift` — Phase enum + 遷移ルール（純粋ロジック）
- `Models/NotchGeometry.swift` — ノッチ寸法計算（NSScreen非依存）
- `Services/VolumeControlService.swift` — CoreAudio音量制御
- `Services/WatchdogService.swift` — メインスレッド監視

**App層（新規）**:
- `Windows/NotchOverlayWindow.swift` — NSWindowサブクラス（.screenSaverレベル）
- `Views/NotchSessionView.swift` — 4フェーズ統合View
- `Views/EyeCharacterView.swift` — Canvas描画の目キャラ

**App層（変更）**:
- `ViewModels/SessionViewModel.swift` — currentPhase追加
- `AppDelegate.swift` — NotchOverlayWindow使用

**既存維持**:
- `Views/SessionView.swift` — レガシーフォールバック

## Risks and Mitigations

### Risk 1: フルスクリーン黒 + クラッシュ = Mac操作不能 【最重要】

6層の防御:

| 層 | 対策 | 詳細 |
|----|------|------|
| 1 | Watchdogタイマー | BGキューから2秒ごとにメインスレッド監視。10秒応答なし→音量復帰+ウィンドウ非表示+終了 |
| 2 | セッションタイムアウト | 最大120秒。超過で強制終了 |
| 3 | ESCキー常時有効 | 既存のNSEvent monitor。.screenSaverレベルでも動作確認済み |
| 4 | applicationWillTerminate | 音量復帰 + ウィンドウ非表示 |
| 5 | シグナルハンドラ | SIGTERM/SIGINT で音量復帰。Force Quit (Cmd+Opt+Esc) 対応 |
| 6 | 永続化ファイル | Phase 3突入時に `{volumeBefore, sessionActive}` 書込み。起動時チェック→未クリーンなら音量復帰 |

### Risk 2: 音量が0のまま戻らない

- Risk 1の層4-6でカバー
- 最低音量0.02制限（完全無音にしない）
- フェードダウンに2秒かけ、ユーザーがESCできる猶予

### Risk 3: カメラスレッドのクラッシュ（EXC_BAD_ACCESS前歴あり）

- 既存の `autoreleasepool` + `isReleasedWhenClosed=false` + 遅延close を維持
- NotchOverlayWindowも同パターン適用
- Watchdogがハングを検知

### Risk 4: ノッチサイズがモデルで異なる

- `NSScreen.safeAreaInsets` + `auxiliaryTopLeftArea/Right` でセッション開始時に動的計算
- ハードコード値なし

### Risk 5: 60fpsアニメーション + Vision処理のパフォーマンス

- Canvas描画（単一drawコール）
- Phase 3中は目キャラ静止（描画コスト最小）
- Phase 1/4のウィンドウアニメーションはCore Animation（GPU）
- 必要に応じてVision処理を15fpsに落とす

### Risk 6: アクセシビリティ

- `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` → アニメーションスキップ
- VoiceOver: フェーズ遷移をアクセシビリティ通知
- 目を閉じられないユーザー向け: Phase 2に手動完了ボタン

## Alternatives Considered

### A) 既存UIの改良のみ

フローティングウィンドウの色やアニメーションを改善するだけ。リスクは低いが、差別化ポイントがない。

### B) Lottieアニメーション

事前制作のアニメーションを使う。デザイン品質は高いが、EyeStateへのリアルタイム連動が困難。ファイルサイズも増加。

### C) SceneKit 3Dキャラクター

3Dの目キャラクター。リッチだがGPU負荷が高く、Vision処理との競合リスク。開発コストも高い。

## Consequences

- **Positive**: ユニークなUX体験、ノッチを活かしたデザイン、マインドフルネスの没入感向上
- **Negative**: 複雑さの増加（6層防御が必要）、開発コスト増、テスト困難（フルスクリーン+音量制御）
- **Neutral**: レガシーUIをフォールバックとして維持するため、新UIに問題があっても即座にロールバック可能
