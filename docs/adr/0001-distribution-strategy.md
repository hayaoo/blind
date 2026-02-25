# ADR-0001: 配布戦略とアーキテクチャ

- **Status**: Accepted
- **Date**: 2026-02-25
- **Deciders**: @hayaoo

## Context

Blindの配布方法とアーキテクチャを決定する必要がある。

### 要件
- 無料版（OSS）と有料版（買い切り）の2層構造
- Mac App Storeではなく、GitHub直接配布
- 有料版は購入者にダウンロードコードを渡す形式
- AI（Claude）が開発しやすい環境
- ベンチマーク: Cleanshot（直接配布の成功事例）

### 検討した選択肢

| 選択肢 | メリット | デメリット |
|--------|----------|------------|
| A) GitHub Releases + 署名・公証 | CI自動化しやすい、AI検証向き | 署名にDeveloper ID必要（$99/年） |
| B) Homebrew cask | 開発者向けに導入が軽い | 一般ユーザーには敷居高い |
| C) Mac App Store | 一般ユーザーに信頼感 | サンドボックス制約、審査、手数料30% |

## Decision

**選択肢A: GitHub Releases（署名・公証済みDMG）+ Sparkle自動更新**を採用する。

### 理由

1. **AI開発との相性**
   - CIで「ビルド→テスト→署名→公証→リリース」まで自動化
   - 失敗時のログ・スクショをartifact化し、AIが自己修正ループを回せる

2. **Cleanshot方式との親和性**
   - 直接配布でも署名・公証でGatekeeperを通過
   - Sparkleで自動アップデート

3. **有料版の柔軟性**
   - ダウンロードコード（ライセンスキー）で有料機能をアンロック
   - App Storeの手数料なし

## Architecture

### リポジトリ構造（新）

```
blind/
├── Packages/
│   └── BlindCore/           # SwiftPM: ロジック・ドメイン
│       ├── Sources/
│       │   └── BlindCore/
│       │       ├── Services/
│       │       │   ├── CameraService.swift
│       │       │   ├── EyeDetectionService.swift
│       │       │   └── ...
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
│   └── BlindUITests/        # スモークテスト（起動・主要導線）
├── scripts/
│   ├── build.sh
│   ├── test.sh
│   ├── notarize.sh
│   └── release.sh
├── .github/
│   └── workflows/
│       ├── ci.yml           # push/PRごとのビルド・テスト
│       └── release.yml      # タグでリリース
├── docs/
│   └── adr/
├── CLAUDE.md
├── README.md
└── Package.swift            # ルートPackage（workspace的に使用）
```

### CI/CD設計

#### push/PRごと（ci.yml）
1. Build
2. Unit Test
3. Integration Test
4. UI Smoke Test（起動・主要導線）
5. 失敗時: スクショ・ログ・クラッシュレポートをartifact化

#### releaseタグ（release.yml）
1. Build (Release)
2. codesign（Developer ID）
3. notarize + staple
4. DMG作成
5. GitHub Release作成（DMG添付、SHA256ハッシュ）
6. Sparkle appcast更新（任意）
7. Homebrew cask更新（任意）

### 有料版の実装方針

```
┌─────────────────────────────────────────────────────┐
│  無料版（OSS）                                       │
│  - 基本機能すべて                                    │
│  - GitHub Releasesからダウンロード                   │
└─────────────────────────────────────────────────────┘
                      │
                      │ ライセンスキー入力
                      ▼
┌─────────────────────────────────────────────────────┐
│  有料版（Pro）                                       │
│  - 追加機能（統計、サウンドカスタマイズ等）          │
│  - 優先サポート                                      │
│  - 同一バイナリ、キーでアンロック                    │
└─────────────────────────────────────────────────────┘
```

- ライセンスキー検証: ローカル検証（RSA署名）or 軽量サーバー
- 販売: Gumroad / Paddle / LemonSqueezy 等

## Consequences

### Positive
- AI開発フレンドリー（CI artifact → AIフィードバックループ）
- 配布の摩擦が少ない（署名・公証済み）
- App Store手数料なし
- OSSとしてコミュニティ貢献を受けられる

### Negative
- Developer ID登録必要（$99/年）
- ライセンス検証の実装が必要
- サポートは自前

### Risks
- 未署名だとGatekeeperで止まる → 署名・公証は必須
- ライセンスキーのクラック → 許容（OSSなので本気で防ぐ意味が薄い）

## References

- Cleanshot: https://cleanshot.com/
- Sparkle: https://sparkle-project.org/
- Apple Developer Program: https://developer.apple.com/programs/
- Notarization: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution

## Mac App Store 販売のメリット・デメリット

### メリット

| 項目 | 詳細 |
|------|------|
| **リーチ** | 一般ユーザーへの露出、検索流入 |
| **信頼感** | Appleの審査を通過 = 安心感 |
| **決済** | Apple IDで簡単購入、返金対応もApple |
| **アップデート配信** | App Store経由で自動、ユーザー体験が統一 |
| **国際対応** | 多通貨・多言語対応が自動 |

### デメリット

| 項目 | 詳細 |
|------|------|
| **手数料** | 売上の15〜30%（Small Business Programで15%） |
| **サンドボックス制約** | 権限系機能に制限（カメラは問題なし） |
| **審査** | リジェクトリスク、リリースサイクルの遅延 |
| **価格設定** | 最低価格あり、価格変更に制約 |
| **顧客情報** | 購入者情報を直接取得できない |
| **ライセンスキー方式との相性** | Store版は別バイナリになりがち |

### 結論

**Store販売はしない（直接配布のみ）**

理由：
1. **アクセシビリティ権限が将来必要**
   - マスターボリュームの一時的な制御
   - 画面全体を覆うオーバーレイ（暗転）
   - → サンドボックスでは実現不可

2. **開発ボリュームの抑制**
   - 2ターゲット維持は避けたい
   - 1バイナリ、1リリースフローでシンプルに

3. **ターゲットユーザー**
   - クリエイター・開発者中心
   - 直接配布で十分（Cleanshot方式）

---

## 有料版の追加機能（スコープアウト）

MVP完了後に実装予定：

| 機能 | 概要 |
|------|------|
| ビジュアルカスタマイズ | セッション画面の色・スタイル変更 |
| サウンドカスタマイズ | 複数の終了音から選択 |
| スケジュール機能 | 作業時間帯のみリマインド |
| スヌーズ機能 | 「5分後に再通知」 |

## 将来機能（アクセシビリティ権限が必要）

Store販売をしない決定の背景となる将来機能：

| 機能 | 概要 | 必要な権限 |
|------|------|-----------|
| ボリューム制御 | セッション中にマスターボリュームを下げる | アクセシビリティ or CoreAudio |
| 画面暗転 | 画面全体を覆うオーバーレイで暗くする | フルスクリーンオーバーレイ |
| 復帰時リストア | セッション終了時に音量・画面を元に戻す | 上記と同様 |

**→ これらはサンドボックス環境では実現不可 → Store販売を断念**

---

## ライセンス販売（スコープアウト）

販売プラットフォーム候補: **Stripe**（直接決済）

その他候補（比較未実施）:
- Gumroad
- Paddle
- LemonSqueezy

---

## Open Questions

- [x] Storeで販売すべきか？ → MVP段階ではスコープアウト、将来検討
- [x] ライセンス販売プラットフォーム → Stripe（スコープアウト）
- [x] 有料版の追加機能 → 定義済み（スコープアウト）
