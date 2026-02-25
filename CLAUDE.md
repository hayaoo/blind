# Blind — CLAUDE.md

## プロジェクト概要

macOSメニューバーに常駐するマインドフルネスリマインダーアプリ。
「目を閉じる」という身体的アクションを通じて、意図的な中断を作り、
「今、正しいことをしているか？」を確認する機会を提供する。

## ビジネスモデル

| 版 | 形態 | 配布 | 価格 |
|----|------|------|------|
| 無料版 | OSS | GitHub Releases | 無料 |
| 有料版（Pro） | 同一バイナリ、キーでアンロック | GitHub Releases | 買い切り（未定） |

**方針**:
- Mac App Storeではなく**GitHub直接配布**
- 署名・公証（notarize）でGatekeeperを通過
- 有料版は購入者にライセンスキー（ダウンロードコード）を渡す
- ベンチマーク: Cleanshot

**ライセンス販売候補**: Gumroad / Paddle / LemonSqueezy

## 配布戦略（ADR-0001）

詳細: `docs/adr/0001-distribution-strategy.md`

```
GitHub Releases（署名・公証済みDMG）
    + Sparkle自動更新
    + ライセンスキーで有料機能アンロック
```

## 技術スタック

- Swift 5.9+
- SwiftUI / AppKit
- Vision framework（目検知）
- AVFoundation（カメラ制御）
- macOS 14.0+ (Sonoma)
- Sparkle（自動アップデート）

## ディレクトリ構造（新アーキテクチャ）

```
blind/
├── Packages/
│   └── BlindCore/           # SwiftPM: ロジック・ドメイン
│       ├── Sources/
│       │   └── BlindCore/
│       │       ├── Services/
│       │       └── Models/
│       └── Tests/
│           └── BlindCoreTests/
├── App/
│   └── Blind/               # SwiftUI/AppKit シェル（薄く）
│       ├── BlindApp.swift
│       ├── AppDelegate.swift
│       ├── Views/
│       ├── Resources/
│       └── Info.plist
├── Tests/
│   ├── UnitTests/
│   └── IntegrationTests/
├── UITests/
│   └── BlindUITests/        # スモークテスト
├── scripts/
│   ├── build.sh
│   ├── test.sh
│   ├── notarize.sh
│   └── release.sh
├── .github/
│   └── workflows/
│       ├── ci.yml           # push/PR: ビルド・テスト
│       └── release.yml      # タグ: 署名・公証・リリース
├── docs/
│   └── adr/
├── Package.swift
├── CLAUDE.md
└── README.md
```

**設計意図**:
- `Packages/BlindCore`: ロジックをSwiftPMで分離 → テストしやすい、AIが扱いやすい
- `App/Blind`: UIシェルは薄く
- `scripts/`: ビルド・署名・公証・リリースを自動化
- `.github/workflows/`: CI/CDでAI自己検証ループを回す

## CI/CD（AI開発フレンドリー）

### push/PRごと（ci.yml）
1. Build
2. Unit Test（Packages/BlindCore）
3. Integration Test
4. UI Smoke Test（起動・主要導線）
5. **失敗時: スクショ・ログをartifact化 → AIがフィードバック**

### releaseタグ（release.yml）
1. Build (Release)
2. codesign（Developer ID）
3. notarize + staple
4. DMG作成
5. GitHub Release（DMG + SHA256）
6. Sparkle appcast更新

## 主要な機能フロー

1. **メニューバー常駐**: NSStatusItem
2. **タイマーリマインド**: Timer + UserNotifications
3. **セッション開始**: NSWindow (floating) + SwiftUI
4. **カメラ検知**: AVFoundation + Vision framework
5. **目検知**: VNDetectFaceLandmarksRequest + Eye Aspect Ratio
6. **セッション完了**: 5秒間目を閉じたら終了

## 開発時の注意点

- LSUIElement = true でDockに表示しない
- カメラ使用許可が必要（NSCameraUsageDescription）
- 映像は保存・送信しない（プライバシー配慮）
- Eye Aspect Ratio の閾値（0.2）は要調整
- **署名・公証は必須**（未署名だとGatekeeperで止まる）

## ビルド・実行

```bash
# SwiftPMでビルド
swift build

# テスト
swift test

# Xcodeで開く（App）
open App/Blind/Blind.xcodeproj

# リリースビルド（スクリプト）
./scripts/build.sh
./scripts/notarize.sh
./scripts/release.sh
```

## 関連ドキュメント

### リポジトリ内
- ADR: `docs/adr/`

### pomm（経営管理リポジトリ）
- 要件書: `03_projects/blind/requirements.md`
- コンセプト: `03_projects/blind/concept.md`
- 競合調査: `03_projects/blind/competitors.md`
- MVP定義: `03_projects/blind/mvp.md`

## スコープアウト（MVP後）

### Store販売
MVP段階ではスコープアウト。将来的に検討。
詳細: `docs/adr/0001-distribution-strategy.md`

### ライセンス販売
プラットフォーム: Stripe（直接決済）

### 有料版の追加機能
| 機能 | 概要 |
|------|------|
| ビジュアルカスタマイズ | セッション画面の色・スタイル変更 |
| サウンドカスタマイズ | 複数の終了音から選択 |
| スケジュール機能 | 作業時間帯のみリマインド |
| スヌーズ機能 | 「5分後に再通知」 |
