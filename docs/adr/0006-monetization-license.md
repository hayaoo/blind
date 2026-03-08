# ADR-0006: 課金基盤 — LemonSqueezy + ライセンスキー検証

## Status

Proposed

## Date

2026-03-08

## Context

ADR-0005（獲得戦略）から導出された課金要件:

1. ライセンスキーによるPro機能アンロック（App Store不使用のため）
2. 買い切り$19
3. 国際通貨対応（日本円含む）
4. プライバシー重視ユーザーへの配慮（オフライン検証）
5. 開発工数の最小化（一人開発）

## Decision

### 1. 販売プラットフォーム: LemonSqueezy

| 候補 | 利点 | 欠点 | 判定 |
|------|------|------|------|
| **LemonSqueezy** | ライセンスキー生成組み込み、MoR（税務不要）、Swift SDK有り | 手数料5%+50¢ | **採用** |
| Stripe | 自由度高、手数料安い(2.9%+30¢) | キー生成自前実装、税務自己処理 | 却下 |
| Paddle | MoR、Desktop SDK有り | macOS SDK古い、最低手数料$0.50 | 却下 |
| Gumroad | 簡単 | 手数料10%、機能少ない | 却下 |

### 2. ライセンスキー検証フロー

```
[ユーザー]                    [Blind App]                [LemonSqueezy]
    |                              |                           |
    |-- LP/アプリからPro購入 ------>|                           |
    |                              |---- Checkout URL -------->|
    |                              |                           |
    |<------- メールでキー送付 ------|<-- Webhook: order.created |
    |                              |                           |
    |-- アプリにキー入力 ---------->|                           |
    |                              |---- POST /v1/licenses/activate -->|
    |                              |<--- 200 OK (license_key object) --|
    |                              |                           |
    |                              |-- KeychainにActivation保存 |
    |                              |                           |
    |    [次回起動時]               |                           |
    |                              |---- POST /v1/licenses/validate ->|
    |                              |<--- 200 OK or offline fallback --|
```

### 3. 検証戦略: オンライン優先 + オフラインフォールバック

```swift
// 検証の優先順位
// 1. オンライン検証（起動時、1日1回）
// 2. オフラインフォールバック（最後の検証から30日以内なら有効）
// 3. 30日超過 → 再検証要求（ネット接続時に自動検証）
```

**設計判断**:
- 買い切りライセンスなので厳密なDRM不要
- HNユーザーへの配慮: オフラインで普通に使える
- 30日のグレースピリオド: 出張・旅行中でも問題ない
- クラックされてもOSS部分は無料。Pro機能のアンロックのみ

### 4. Swift実装方針

#### 依存パッケージ

```swift
// Package.swift (BlindCore)
.package(url: "https://github.com/kevinhermawan/swift-lemon-squeezy-license", from: "1.0.0")
```

`swift-lemon-squeezy-license` を採用（軽量、ライセンス検証のみに特化）。

#### 新規ファイル

| ファイル | 責務 |
|---------|------|
| `BlindCore/Services/LicenseService.swift` | キー入力 → activate → validate → Keychain保存 |
| `BlindCore/Models/LicenseState.swift` | free / pro / expired / validating の状態管理 |

#### 既存ファイル変更

| ファイル | 変更 |
|---------|------|
| `SessionViewModel.swift` | `isProEnabled` → `LicenseService.shared.isPro` に接続 |
| `ExtendedOnboardingTextBar.swift` | hardPaywallChoiceのCTA → LemonSqueezy Checkout URL |
| `BlindSettings.swift` | ライセンスキー入力UI用のプロパティ追加 |
| `AppDelegate.swift` | 起動時のライセンス検証トリガー |

### 5. LemonSqueezy設定

#### 商品設定

| 項目 | 値 |
|------|-----|
| Product Name | Blind Pro |
| Price | $19 (one-time) |
| License Key | 有効化（自動生成） |
| Activation Limit | 3（Mac 3台まで） |
| Checkout URL | `https://blind.lemonsqueezy.com/checkout/buy/xxx` |

#### Webhook設定

| Event | 用途 |
|-------|------|
| `order_created` | メールでキーを送付（LemonSqueezy自動） |
| `license_key_created` | ログ記録（任意） |

Webhookサーバーは不要 — LemonSqueezyがメール送付とキー管理を全て行う。
アプリ側はLicense APIでactivate/validateするだけ。

### 6. 購入導線

#### アプリ内から

```
設定画面 → 「Proにアップグレード」ボタン
    → NSWorkspace.shared.open(checkoutURL) で外部ブラウザ
    → LemonSqueezy Checkoutページ
    → 購入完了 → メールでキー受信
    → アプリの設定画面でキー入力
```

#### Day 7 ハードペイウォールから

```
Day 7レポート → hardPaywallChoice画面
    → 「Proにアップグレード」ボタン
    → 同上の外部ブラウザフロー
```

#### LPから

```
LP → 「Download Free」→ GitHub Releases DMG
LP → 「Buy Pro ($19)」→ LemonSqueezy Checkout
```

### 7. 価格の根拠（ADR-0005から）

| ベンチマーク | 価格 |
|------------|------|
| CleanShot X | $29 |
| Session (Pomodoro) | $4.99 |
| Be Focused Pro | $4.99 |
| **Blind Pro** | **$19** |

$19の位置づけ:
- Pomodoro系($5)より高い → 「5秒タイマーではない、行動変容ツール」
- Headspace/Calm($70/年)より圧倒的に安い → 「買い切りでマイクロマインドフルネス」
- CleanShot($29)より安い → 「気軽に試せる」
- コーヒー3杯分 → ADHD層の衝動購入の閾値内
- サーバーコストゼロ → 永久ライセンスに矛盾がない

### 8. 収益チャネルの多層化

| チャネル | モデル | 予想単価 | 備考 |
|---------|--------|---------|------|
| **直販（LemonSqueezy）** | $19 買い切り | $17.55/件（手数料控除後） | 主収益。LP + アプリ内から |
| **Setapp** | 月額レベニューシェア | $0.50-2.00/月/ユーザー | 副収益 + 発見性。利用時間ベース |

Setapp版はPro機能を全開放（Setappユーザーは定額に含まれるため）。
直販のライセンスキー検証とは別のパスで、Setapp SDKによるサブスクリプション検証を実装。

## Alternatives Considered

### A) App内課金（StoreKit）

却下。App Storeを使わない配布方針（ADR-0001）と矛盾。
GitHub Releases配布のアプリでStoreKitは使えない。

### B) 自前ライセンスサーバー

却下。開発・運用コストが高い。LemonSqueezyのAPIで十分。

### C) RSA署名によるオフライン専用検証

却下。オフライン検証は魅力的だが、キーの流出時に無効化できない。
オンライン優先 + 30日オフラインフォールバックで十分なバランス。

### D) サブスクリプション

却下（ADR-0005で決定済み）。「習慣化して自立する」というBlindのコンセプトと矛盾。

## Consequences

### Positive
- LemonSqueezyでライセンス管理の開発がほぼゼロ
- Swift SDKが既存 → SwiftPMで追加するだけ
- Webhookサーバー不要 → インフラ運用ゼロ
- 買い切りはユーザーの信頼を得やすい

### Negative
- LemonSqueezy手数料: $19 × 5% + $0.50 = $1.45/件（純利益$17.55）
- オフライン30日制限がパワーユーザーに不評の可能性
- LemonSqueezyの障害時は購入不可（ただし既存ユーザーはオフラインフォールバックで影響なし）

### Neutral
- Activation Limit 3台は一般的。家族共有は想定外
