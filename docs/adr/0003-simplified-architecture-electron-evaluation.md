# ADR-0003: アーキテクチャ簡素化とElectron採否

- **Status**: Accepted
- **Date**: 2026-03-02
- **Deciders**: @hayaoo

## Context

現在のBlindは約3,800行のSwiftコードで構成され、以下の構造を持つ：

- `Packages/BlindCore/`: SwiftPMパッケージ（サービス層・モデル層）
- `App/Blind/`: AppKit/SwiftUIシェル（`main.swift` → `NSApplication.shared.run()`）
- 4フェーズセッションUX（ADR-0002）
- 6層クラッシュ防御機構

開発を進める中で、以下の課題が顕在化した：

1. **AppDelegate肥大化**: セッション管理・ウィンドウ制御・安全機構が混在（426行）
2. **双方向コールバック**: `SessionViewModel` ↔ `AppDelegate` のコールバック連鎖が複雑
3. **SwiftPMパッケージ分離の過剰さ**: この規模（31ファイル）でパッケージ分離はオーバーヘッド
4. **`main.swift`によるSwiftUI App lifecycle回避**: EXC_BAD_ACCESS対策で導入したが、SwiftUIの恩恵を制限

これを機に、アーキテクチャの簡素化を検討する。また、Web技術（Electron）での再構築が合理的かも合わせて評価する。

## Decision

### Electron: 不採用

### アーキテクチャ: macOS 14+モダンSwiftUIで簡素化

---

## Electron評価

### 概要

Electronはchromium + Node.jsベースのデスクトップアプリフレームワーク。Slack, VS Code, Figma等で採用実績あり。

### 機能ごとの実現可能性

| 機能 | 現行（Swift） | Electron代替 | 実現性 |
|------|--------------|-------------|--------|
| 目検知 | `VNDetectFaceLandmarksRequest` (Vision) | MediaPipe Face Mesh / TensorFlow.js | △ 精度・パフォーマンス劣化 |
| カメラ制御 | `AVCaptureSession` | `navigator.mediaDevices.getUserMedia()` | ○ 可能 |
| 音量制御 | `CoreAudio` 直接操作 | native addon (node-addon-api) 必須 | △ ブリッジコード必要 |
| ノッチ融合 | `NSScreen.safeAreaInsets`, `auxiliaryTopLeftArea` | **取得手段なし** | ✗ 不可能 |
| ウィンドウレベル | `.screenSaver` | `alwaysOnTop` (粒度粗い) | △ 制限あり |
| メニューバー常駐 | `NSStatusItem` + `LSUIElement` | `Tray` | ○ 可能（重い） |
| シグナルハンドラ | SIGTERM/SIGINT → 音量復帰 | `process.on('SIGTERM')` | ○ 可能 |
| コード署名・公証 | `codesign` + `notarytool` | `electron-builder` + 同ツール | ○ 可能 |

### Electronのメリット

| 項目 | 詳細 |
|------|------|
| UI開発速度 | HTML/CSS/JSでの高速プロトタイピング |
| AI親和性 | LLMがWeb技術を最も得意とする |
| リッチUI | CSSアニメーション、WebGL等 |
| ホットリロード | 開発サイクルの短縮 |
| エコシステム | npm経由の豊富なライブラリ |

### Electronのデメリット

| 項目 | 詳細 |
|------|------|
| アプリサイズ | 数MB → **150MB+**（Chromiumバンドル） |
| メモリ使用量 | 大幅増（Chromium + Node.js） |
| ノッチ融合 | **不可能**（ADR-0002の差別化ポイント喪失） |
| 目検知精度 | Vision framework → MediaPipe/TF.jsで劣化の可能性 |
| ネイティブ連携 | 音量制御等でnative addon必須 = 結局ネイティブコードが必要 |
| クロスプラットフォーム | Blindはmac専用 → Electronの最大メリットが活きない |
| パフォーマンス | 60fps Canvas描画 + カメラ処理にオーバーヘッド |

### 判断理由

1. **ノッチ融合が不可能**: ADR-0002で決定した差別化ポイント（ノッチに住む目キャラ）がElectronでは実現できない。`NSScreen.safeAreaInsets`や`auxiliaryTopLeftArea`に相当するAPIがChromiumに存在しない。

2. **ネイティブブリッジが結局必要**: 音量制御（CoreAudio）はnative addonが必須。目検知もMediaPipeに置き換え可能だが精度検証が必要。結果として「Electronのガワ + ネイティブアドオン」という最悪の構成になる。

3. **クロスプラットフォーム不要**: Blindはmac専用（ノッチ、メニューバー、コード署名・公証、将来のアクセシビリティ権限）。Electronの最大の価値が活きない。

4. **サイズ・パフォーマンスの代償が大きい**: マインドフルネスアプリが150MB+でメモリを大量消費するのは、プロダクトの思想に反する。

---

## 簡素化されたアーキテクチャ

### ディレクトリ構造

```
blind/
├── Blind/
│   ├── BlindApp.swift              # @main + MenuBarExtra (macOS 13+)
│   ├── AppState.swift              # @Observable, アプリ全体の状態
│   │
│   ├── Session/
│   │   ├── SessionManager.swift    # カメラ→目検知→フェーズ遷移→音量を統合管理
│   │   ├── SessionWindow.swift     # NSPanel (.screenSaver level)
│   │   ├── SessionView.swift       # 目キャラ + テキスト (統合View)
│   │   └── EyeCharacterView.swift  # Canvas描画（現行踏襲）
│   │
│   ├── Detection/
│   │   ├── CameraService.swift     # AVFoundation（現行踏襲）
│   │   └── EyeDetectionService.swift # Vision（現行踏襲）
│   │
│   ├── Services/
│   │   ├── VolumeService.swift     # CoreAudio（現行踏襲）
│   │   ├── SoundService.swift      # SystemSound（現行踏襲）
│   │   └── NotificationService.swift
│   │
│   ├── Settings/
│   │   └── SettingsView.swift      # @AppStorage直接利用
│   │
│   └── Resources/
│       └── Assets.xcassets
│
├── Tests/
│   └── BlindTests/                 # 単一テストターゲット
│       ├── SessionPhaseTests.swift
│       ├── EyeDetectionTests.swift
│       └── ...
│
├── scripts/
│   ├── build.sh
│   ├── test.sh
│   ├── notarize.sh
│   └── release.sh
│
├── .github/workflows/
│   ├── ci.yml
│   └── release.yml
│
├── docs/adr/
├── Package.swift
├── CLAUDE.md
└── README.md
```

### 変更点の詳細

#### 1. SwiftPMパッケージ統合

**現行**: `Packages/BlindCore/` として分離
**提案**: 単一ターゲット（`Blind/` 直下にフラット配置）

理由:
- 31ファイル・3,800行の規模でパッケージ分離は過剰
- `swift build` / `swift test` の対象がBlindCore**のみ**になる問題
- Xcodeプロジェクトとの二重管理が発生
- フォルダによる論理的な分離で十分

#### 2. エントリポイント

**現行**: `main.swift` → `NSApplication.shared.run()` (SwiftUI App lifecycle回避)
**提案**: `@main struct BlindApp: App` + `MenuBarExtra`

```swift
@main
struct BlindApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("Blind", systemImage: "eye.slash") {
            MenuBarView()
        }

        Settings {
            SettingsView()
        }
    }
}
```

理由:
- `MenuBarExtra` (macOS 13+) でメニューバー管理が宣言的に
- `@NSApplicationDelegateAdaptor` でAppKit連携（シグナルハンドラ、applicationWillTerminate等）を維持
- `main.swift` 回避の根本原因（EXC_BAD_ACCESS）は`CameraService.stopCapture()`のsync化で解決済み

#### 3. 状態管理

**現行**: `SessionViewModel` (ObservableObject) + AppDelegateへのコールバック3本
```
SessionViewModel.onSessionComplete → AppDelegate
SessionViewModel.onPhaseChanged → AppDelegate
SessionViewModel.onEyesClosedChanged → AppDelegate
```

**提案**: `@Observable SessionManager` が状態とウィンドウ制御を一元管理

```swift
@Observable
final class SessionManager {
    var phase: SessionPhase = .idle
    var eyesClosed = false
    var faceDetected = true
    var closedDuration: TimeInterval = 0

    private var sessionWindow: SessionWindow?
    private var eyeDetection: EyeDetectionService?

    func startSession() { ... }
    func endSession() { ... }
}
```

理由:
- `@Observable` (macOS 14+) は `ObservableObject` より効率的（プロパティ単位の監視）
- コールバック連鎖の排除 → SessionManagerが直接ウィンドウを制御
- 「誰が何を管理するか」が明確に

#### 4. AppDelegate最小化

**現行**: 426行（セッション管理 + ウィンドウ管理 + 安全機構 + メニュー + 設定 + カメラ許可）

**提案**: 安全機構のみ残す（~50行）

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // クラッシュリカバリ
        VolumeService.shared.restoreIfNeeded()
        // シグナルハンドラ
        setupSignalHandlers()
    }

    func applicationWillTerminate(_ notification: Notification) {
        VolumeService.shared.emergencyRestore()
    }
}
```

残りの責務は：
- メニューバー → `MenuBarExtra` (SwiftUI)
- セッション管理 → `SessionManager`
- 設定 → `Settings` scene (SwiftUI)
- カメラ許可 → `SessionManager.startSession()` 内で遅延要求

#### 5. クラッシュ防御の簡素化

**現行**: 6層

| 層 | 対策 |
|----|------|
| 1 | WatchdogService（BGスレッドからメインスレッド監視） |
| 2 | セッションタイムアウト（120秒） |
| 3 | ESCキー常時有効 |
| 4 | applicationWillTerminate |
| 5 | シグナルハンドラ (SIGTERM/SIGINT) |
| 6 | 永続化ファイル（起動時チェック） |

**提案**: 4層（層2を層1に統合、層3は維持、層6は層4/5で十分）

| 層 | 対策 |
|----|------|
| 1 | Watchdog + タイムアウト統合（SessionManager内、120秒 or メインスレッド10秒無応答） |
| 2 | ESCキー（NSEvent monitor） |
| 3 | applicationWillTerminate → 音量復帰 + ウィンドウ非表示 |
| 4 | シグナルハンドラ (SIGTERM/SIGINT) → 音量復帰 |

永続化ファイル（層6）を削除する理由:
- 層3（applicationWillTerminate）と層4（シグナルハンドラ）で正常終了・Force Quitの両方をカバー
- カーネルパニック等での音量残留リスクは、起動時の音量チェック（UserDefaults）で対応可能（現行と同等）

#### 6. 設定管理

**現行**: `BlindSettings` モデル + `UserDefaults.standard.register(defaults:)` + 手動バインディング

**提案**: `@AppStorage` 直接利用

```swift
struct SettingsView: View {
    @AppStorage("reminderInterval") private var interval = 30
    @AppStorage("eyeCloseDuration") private var duration = 5
    @AppStorage("soundEnabled") private var sound = true
}
```

理由:
- `BlindSettings` モデルクラスが不要に
- SwiftUIのバインディングと自然に統合
- デフォルト値が宣言箇所で明示的

### 維持する設計

以下は現行のまま維持する：

1. **4フェーズセッションUX** (ADR-0002): 差別化ポイント。実装の簡素化はするが、フェーズ設計自体は変えない
2. **`SessionPhase` + `SessionPhaseTransition`**: 純粋関数ベースの状態遷移ルール。テストしやすく正確
3. **`EyeCharacterView`**: Canvas描画の目キャラクター。現行の実装品質が高い
4. **`CameraService` / `EyeDetectionService`**: Vision frameworkの利用パターン。`autoreleasepool`による安全性も維持
5. **`VolumeControlService`**: CoreAudio直接操作。フェード処理・緊急復帰のロジック
6. **ノッチ融合ウィンドウ**: NSWindow/NSPanelベース。SwiftUIでは`.screenSaver`レベルの制御ができないため

### ファイル数・行数の見込み

| 指標 | 現行 | 提案 |
|------|------|------|
| Swiftファイル数 | 31 | ~18 |
| 総行数（ソース） | ~2,600 | ~1,800 |
| 総行数（テスト） | ~1,200 | ~800 |
| パッケージ数 | 2 (root + BlindCore) | 1 |

## Consequences

### Positive

- **認知負荷の低減**: パッケージ分離・コールバック連鎖の排除で、コード全体の見通しが改善
- **SwiftUIの恩恵**: `MenuBarExtra`、`@Observable`、`@AppStorage`、`Settings` sceneの活用
- **AI開発効率**: ファイル数削減により、AIがコンテキストを把握しやすくなる
- **メンテナンス性**: 二重管理（SwiftPM + Xcode）の解消

### Negative

- **移行コスト**: 既存コードのリファクタリングが必要（ただし段階的に可能）
- **macOS 14+固定**: `@Observable`がmacOS 14+。現行と同じだが、将来の下方展開の選択肢を失う
- **テスト分離の緩み**: パッケージ分離がなくなることで、UIなしテストの境界が曖昧になる可能性

### Risks

- **`@main` + SwiftUI App lifecycle回帰**: EXC_BAD_ACCESS再発の可能性。`CameraService.stopCapture()`のsync化が前提条件
- **SessionManagerの肥大化**: 統合しすぎると新たなGod Object化のリスク。フェーズ遷移ロジックは`SessionPhaseTransition`に委譲し続けること

## Migration Strategy

段階的に移行可能：

1. **Phase 1**: `Packages/BlindCore/` → `Blind/` 直下にフラット化（テスト含む）
2. **Phase 2**: `main.swift` → `@main BlindApp` + `MenuBarExtra` に移行
3. **Phase 3**: `SessionViewModel` + AppDelegateコールバック → `SessionManager` に統合
4. **Phase 4**: `ObservableObject` → `@Observable` に置換
5. **Phase 5**: クラッシュ防御の整理（6層 → 4層）

各フェーズ後にビルド・テストが通ることを確認し、段階的にコミットする。

## References

- [MenuBarExtra - Apple Developer](https://developer.apple.com/documentation/swiftui/menubarextra)
- [Observable macro - Apple Developer](https://developer.apple.com/documentation/observation/observable())
- [Electron - Official](https://www.electronjs.org/)
- [MediaPipe Face Mesh](https://developers.google.com/mediapipe/solutions/vision/face_landmarker)
- ADR-0001: `docs/adr/0001-distribution-strategy.md`
- ADR-0002: `docs/adr/0002-notch-character-ux.md`
