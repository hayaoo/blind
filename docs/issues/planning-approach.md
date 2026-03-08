# Phase 2-4 計画の進め方

## 推奨: フェーズごとにADR + 実装Issueのセット

### なぜADRがいいか

1. **意思決定の記録**: 「なぜそうしたか」が残る。後で「なんでこの実装にしたんだっけ？」を防ぐ
2. **代替案の記録**: 検討して却下した選択肢も記録 → 同じ議論を繰り返さない
3. **AIとの協働に最適**: ADRを読めばClaude Codeが文脈を理解して実装できる
4. **スコープの明確化**: ADRで決めた範囲だけをIssue化 → スコープクリープ防止

### 進め方

```
[フェーズごとのADR執筆] → [ADRレビュー] → [Issue作成] → [実装]
```

各フェーズで1つのADRを書き、そこから具体のIssueを切り出す。

---

## Phase 2: 配布可能にする

### ADR-0005（案）: 配布チャネルと自動更新

**検討事項**:
- GitHub Releases のリリースノートテンプレート
- Sparkle自動更新の統合方法（SUUpdater, appcast.xml生成）
- appcast.xmlのホスティング先（GitHub Pages? S3?）
- LP（ランディングページ）の構成と技術選択
- プライバシーポリシーの内容（カメラ使用の説明）
- README.mdの構成（スクショ、DLリンク、セットアップ手順）
- フィードバック導線（GitHub Issues? Google Forms?）

**先に調査すべきこと**:
- Sparkleの最新バージョンとSwiftPM対応状況
- appcast.xml自動生成ツール（`generate_appcast`）
- 類似アプリ（Cleanshot, Raycast等）のLP構成

---

## Phase 3: 課金可能にする

### ADR-0006（案）: ライセンス販売と検証

**検討事項**:
- 販売プラットフォーム選択（Stripe vs LemonSqueezy vs Paddle）
  - Stripe: 自由度高、Webhook実装が必要
  - LemonSqueezy: ライセンスキー生成が組み込み、手数料やや高い
  - Paddle: MoR（Merchant of Record）で税務処理不要
- ライセンスキーの形式と検証方法
  - オンライン検証 vs オフライン検証（RSA署名）
  - 検証頻度（起動時のみ? 定期?）
- Pro機能のアンロック実装
  - 現在 `isProEnabled` はハードコード → ライセンス検証と接続
- 購入フロー（アプリ内ブラウザ? 外部ブラウザ?）
- 価格設定の最終決定（$9? $14? $19?）
- 無料トライアル期間の有無

**先に調査すべきこと**:
- LemonSqueezyのライセンスAPI仕様
- 類似アプリの価格帯（Cleanshot $29, Raycast Pro $8/mo）
- macOSアプリのオフラインライセンス検証のベストプラクティス

---

## Phase 4: 初期ユーザー獲得

### ADR不要 → チェックリスト + マーケティングドキュメント

Phase 4は技術的な意思決定が少ないため、ADRではなく**マーケティングチェックリスト**が適切。

**代わりに用意するもの**:
- `docs/launch-checklist.md` — ローンチ前チェックリスト
- `docs/marketing-copy.md` — Product Hunt, HN, X用の文章案

**検討事項**:
- Product Huntの投稿タイミング（火〜木のUS朝が最適）
- HNの投稿形式（Show HN）
- X（Twitter）での開発過程共有の内容
- クローズドベータの招待方法
- フィードバック収集の仕組み

---

## まとめ: 推奨スケジュール

| タイミング | やること |
|-----------|---------|
| Phase 1実装中 | ADR-0005（配布）のドラフト開始 |
| Phase 1完了後 | ADR-0005確定 → Phase 2 Issue作成 → 実装 |
| Phase 2実装中 | ADR-0006（課金）のドラフト開始 |
| Phase 2完了後 | ADR-0006確定 → Phase 3 Issue作成 → 実装 |
| Phase 3完了後 | launch-checklist.md作成 → Phase 4実行 |

**ポイント**: 前フェーズの実装中に次フェーズのADRを書き始めることで、待ち時間をなくす。
