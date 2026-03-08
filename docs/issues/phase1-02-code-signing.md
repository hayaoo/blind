# Phase 1-2: コード署名 + 公証（Notarization）

**Priority**: P0 (最優先)
**Estimate**: 1日
**Labels**: `phase-1`, `P0`, `distribution`
**Depends on**: Phase 1-1

---

## やること

macOSアプリをユーザーに配布するには、Appleの「コード署名」と「公証（Notarization）」が必須。
これがないと、ダウンロードしたユーザーのMacで「開発元を検証できないため開けません」と拒否される。

## 背景知識（初心者向け）

### コード署名とは？

アプリに「このアプリは○○が作りました」という電子署名を付けること。
Apple Developer Programに加入すると取得できる「Developer ID Application」証明書を使う。

### 公証（Notarization）とは？

署名したアプリをAppleのサーバーに送り、マルウェアチェックを受けること。
チェックを通過すると「チケット」がもらえ、これを添付（staple）するとGatekeeperを通過できる。

```
[ビルド] → [署名] → [Appleに送信] → [チェック] → [チケット添付] → [配布OK]
```

### Gatekeeperとは？

macOSの安全機構。インターネットからダウンロードしたアプリを開く際に、署名と公証をチェックする。

## 手順

### 1. Apple Developer Program加入

**費用**: 年間 $99（約15,000円）
**URL**: https://developer.apple.com/programs/

1. Apple IDでサインイン
2. 「Enroll」から申し込み
3. 本人確認（数日かかる場合あり）

> 既に加入済みの場合はスキップ。

### 2. Developer ID Application証明書の作成

Apple Developer Programに加入後：

1. Xcodeを開く
2. Xcode → Settings（⌘,）→ Accounts タブ
3. 自分のApple IDを選択 → 「Manage Certificates...」
4. 左下の「+」→「Developer ID Application」を選択
5. 証明書が作成され、キーチェーンに保存される

**確認方法**（ターミナル）:
```bash
security find-identity -v -p codesigning
```
`Developer ID Application: Your Name (TEAM_ID)` が表示されればOK。

### 3. App-specific Passwordの作成

公証にはApp-specific Passwordが必要（2FAの代替）：

1. https://appleid.apple.com にサインイン
2. 「サインインとセキュリティ」→「アプリ用パスワード」
3. 「+」でパスワードを生成（名前は「Blind Notarize」など）
4. 生成されたパスワードをメモ

### 4. 環境変数の設定

```bash
# ~/.zshrc に追加（またはCI用のsecretsに設定）
export APPLE_ID="your@email.com"
export APPLE_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-specific Password
export TEAM_ID="XXXXXXXXXX"  # Developer Portalで確認
```

Team IDの確認方法:
- https://developer.apple.com/account → Membership details → Team ID

### 5. scripts/notarize.shの更新

現在のスクリプト（`scripts/notarize.sh`）はほぼ完成している。
`"Developer ID Application: Your Name ($TEAM_ID)"` の部分を実際の名前に更新する必要がある。

```bash
# 自分の証明書名を確認
security find-identity -v -p codesigning | grep "Developer ID"
```

出力された名前をそのままスクリプトに使う。

### 6. 手動テスト

```bash
# 1. ビルド（Xcodeから or コマンドライン）
xcodebuild -project App/Blind/Blind.xcodeproj \
  -scheme Blind \
  -configuration Release \
  -archivePath build/Blind.xcarchive \
  archive

# 2. アーカイブからappを取り出す
cp -R build/Blind.xcarchive/Products/Applications/Blind.app build/

# 3. 署名 + 公証
./scripts/notarize.sh build/Blind.app

# 4. 検証
spctl -a -vvv build/Blind.app
# "accepted" と表示されればOK
```

### 7. Hardened Runtimeの確認

公証にはHardened Runtimeが必要。Xcodeで設定：

1. ターゲット「Blind」→「Signing & Capabilities」
2. 「+ Capability」→「Hardened Runtime」を追加
3. 必要なEntitlement:
   - `com.apple.security.device.camera` ✅（カメラ使用）

## 完了条件

- [ ] Apple Developer Program加入済み
- [ ] Developer ID Application証明書がキーチェーンに存在
- [ ] `./scripts/notarize.sh` が成功する
- [ ] `spctl -a -vvv build/Blind.app` で "accepted" が表示される
- [ ] 別のMacにコピーして、ダブルクリックでGatekeeperを通過して起動できる
