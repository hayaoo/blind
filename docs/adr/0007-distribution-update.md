# ADR-0007: 配布基盤 — LP・自動更新・プライバシーポリシー

## Status

Proposed

## Date

2026-03-08

## Context

ADR-0005（獲得戦略）とADR-0006（課金基盤）から導出された配布要件:

1. 全チャネル（PH, HN, Reddit, X）のリンク先となるLP
2. ローンチ後のイテレーション速度を支えるSparkle自動更新
3. カメラ使用アプリとしてのプライバシーポリシー
4. GitHub経由の発見（HN→GitHub→DL）に対応するREADME
5. ユーザーフィードバック導線

## Decision

### 1. ランディングページ

#### 技術選択: GitHub Pages + 静的HTML

| 候補 | 利点 | 欠点 | 判定 |
|------|------|------|------|
| **GitHub Pages** | 無料、デプロイ簡単、カスタムドメイン対応 | デザイン自由度はフレームワーク次第 | **採用** |
| Vercel + Next.js | 高機能、アナリティクス付き | 過剰。LPに動的機能は不要 | 却下 |
| Carrd | デザイン簡単 | カスタムドメインは有料($19/yr)、制約多い | 却下 |
| Notion | 最速で作れる | ブランディング弱い、遅い | 却下 |

#### LP構成

```
blind.hayaoo.dev (仮)
├── index.html          # メインLP
├── privacy.html        # プライバシーポリシー
├── assets/
│   ├── demo.gif        # 3秒デモ（ノッチ→閉眼→完了）
│   ├── demo-full.mp4   # 30秒デモ（オンボーディング抜粋）
│   ├── og-image.png    # OGP画像（SNS共有時のサムネイル）
│   └── icon.png        # アプリアイコン
└── CNAME               # カスタムドメイン設定
```

#### LP設計思想: 問題提起型（ADR-0005参照）

Blindは**カテゴリ自体が新しい**製品。訪問者は「なぜこれが必要か」を理解していない状態で到達する。
従来の機能紹介型LPではなく、**問題に気づかせてから解決策を提示する**構成を採用。

#### LP構成（セクション順）

```
┌─────────────────────────────────────┐
│  [Logo] Blind                       │
│                                     │
│  Section 1: 問題提起（共感）          │
│  「気づいたら2時間経っていた。         │
│   やるべきことは別にあったのに。」      │
│                                     │
│  Section 2: 解決策（デモ）            │
│  [3秒GIF: ノッチ→目キャラ→閉眼→✓]    │
│  「5秒目を閉じるだけ。                │
│   それだけで、暴走に気づける。」        │
│                                     │
│  [Download Free]  [Buy Pro $19]     │
│                                     │
│  Section 3: How it works            │
│  3ステップ図解（通知→閉眼→気づき）     │
│                                     │
│  Section 4: 信頼構築                 │
│  「カメラ映像は保存・送信しません」     │
│  「BlindCoreはオープンソース」         │
│                                     │
│  Section 5: Features                │
│  無料版/Pro版の比較表                 │
│                                     │
│  Section 6: FAQ                     │
│  よくある質問3-5個                    │
│                                     │
│  Footer                             │
│  GitHub / Privacy Policy / @hayaoo  │
│                                     │
│  macOS 14+ · MacBook (notch) · OSS  │
└─────────────────────────────────────┘
```

#### チャネル別の期待値

| 流入元 | 事前教育レベル | LPでの想定行動 |
|--------|-------------|---------------|
| r/ADHD | 高（問題を自覚） | Section 1をスキップ、デモGIFで即DL |
| Ness Labs | 高（哲学的共感） | Section 2で確信、ProをCTA |
| r/macapps | 中 | Section 1-2を通過してDL |
| Product Hunt | 低 | 全セクション必要 |
| 一般検索 | 最低 | 全セクション + FAQ |

### 2. Sparkle自動更新

#### 統合方針

Sparkle 2.x をSwiftPMで追加。`SPUStandardUpdaterController` を使用。

#### 実装ファイル

| ファイル | 変更 |
|---------|------|
| `App/Blind/Blind.xcodeproj` | Sparkle SPM依存追加 |
| `App/Blind/Info.plist` | `SUFeedURL`, `SUPublicEDKey` 追加 |
| `App/Blind/AppDelegate.swift` | `SPUStandardUpdaterController` 初期化 |
| `App/Blind/Views/SettingsView.swift` | 「アップデートを確認」ボタン追加 |

#### Info.plistに追加するキー

```xml
<key>SUFeedURL</key>
<string>https://blind.hayaoo.dev/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>(generate_appcast で生成)</string>
```

#### appcast.xmlのホスティング

GitHub Pages（LP と同じリポジトリ）に配置。

```
blind.hayaoo.dev/appcast.xml
```

#### リリースフロー（release.ymlに追加）

```
1. xcodebuild archive
2. codesign + notarize
3. DMG作成
4. generate_appcast でappcast.xml更新
5. GitHub Releaseにアップロード
6. GitHub Pages（LPリポジトリ）にappcast.xmlをpush
```

#### EdDSA鍵の管理

```bash
# 初回: 鍵ペア生成
./bin/generate_keys

# 公開鍵 → Info.plist の SUPublicEDKey
# 秘密鍵 → GitHub Secrets (SPARKLE_PRIVATE_KEY)
```

### 3. プライバシーポリシー

#### 必須記載事項

| 項目 | 内容 |
|------|------|
| 収集するデータ | なし（カメラ映像はリアルタイム処理のみ、保存・送信しない） |
| カメラ使用目的 | 目の開閉検知（Vision framework）のみ |
| データの送信先 | なし（全処理はローカル） |
| ライセンス検証 | LemonSqueezy APIへのHTTPS通信（キーハッシュのみ送信） |
| 自動更新 | Sparkleがappcast.xmlを取得（IPアドレスがサーバーログに記録される可能性） |
| アナリティクス | なし（MVP時点） |
| 第三者共有 | なし |

#### HN対策

HNではプライバシーへの指摘が必ず来る。先手を打つ：

- LP上で「カメラ映像は保存・送信しません」を目立つ位置に
- Show HN投稿文に「All processing is local. No data leaves your Mac.」を明記
- BlindCore（ロジック部分）はOSS → コードで証明可能

### 4. README.md

#### 構成

```markdown
# Blind — 5秒の閉眼で暴走に気づく

[3秒デモGIF]

## Features
- MacBookのノッチを活用したセッションUI
- カメラで目の開閉を検知（Vision framework）
- 「象と象使い」メタファーによる行動変容
- カスタマイズ可能なトレーニング時間帯

## Download
[DMGダウンロードリンク]

## Privacy
カメラ映像は保存・送信しません。全処理はローカルで完結します。

## Pro
$19の買い切りで追加機能をアンロック（Pre-close/Post-closeトレーニング、週次レポート等）

## Build from Source
swift build (BlindCore)
open App/Blind/Blind.xcodeproj (Full app)

## License
MIT (BlindCore) / Proprietary (App)
```

### 5. フィードバック導線

| チャネル | 用途 | 設定 |
|---------|------|------|
| GitHub Issues | バグ報告、機能要望 | Issue templates（bug, feature request） |
| LP上のフォーム | 非技術者向け | Google Forms → スプレッドシート |
| アプリ内 | 「フィードバックを送る」→ GitHub Issues or メール | 設定画面にリンク |

### 6. アナリティクス（MVP最小構成）

MVP時点ではサーバーサイドアナリティクスは不要。

| 指標 | 計測方法 |
|------|---------|
| ダウンロード数 | GitHub Releases APIのdownload_count |
| DAU | アプリ内ローカル記録（OnboardingDataStore） |
| オンボーディング完了率 | アプリ内ローカル記録 |
| Day 7到達率 | アプリ内ローカル記録 |
| Pro転換率 | LemonSqueezyダッシュボード |

将来的にopt-inの匿名テレメトリを検討（TelemetryDeck等）。

## Alternatives Considered

### A) Vercel + Next.js LP

却下。LPに動的機能は不要。GitHub PagesならCI/CDなしで`git push`だけでデプロイ。

### B) Sparkleの代わりに手動更新

却下。ローンチ後は週1-2回のリリースが想定される。手動更新ではユーザーが古いバージョンに留まる。

### C) アプリ内アナリティクス（Mixpanel等）

却下（MVP時点）。プライバシー方針（データ送信しない）と矛盾する。
LemonSqueezyの売上データ + GitHub Releasesのダウンロード数で十分。

### D) 別リポジトリでLP管理

却下。LP用のリポジトリを分けると管理が煩雑。
`docs/` ディレクトリまたは `gh-pages` ブランチで本体リポジトリと一元管理。

## Consequences

### Positive
- GitHub Pages: 無料、デプロイ簡単、カスタムドメイン対応
- Sparkle: macOSの標準的な更新フレームワーク、ユーザーに馴染み深い
- プライバシーファースト: HN/Redditでの批判を先手で防げる
- OSSコア: BlindCoreが公開されていることで信頼構築

### Negative
- GitHub Pagesのデザイン制約（テンプレート or 自前CSS）
- Sparkle EdDSA鍵の管理が必要（GitHub Secretsに保管）
- appcast.xml更新の自動化がrelease.ymlに追加の複雑さ

### Neutral
- READMEがマーケティング素材を兼ねるのはOSS文化と親和性が高い
