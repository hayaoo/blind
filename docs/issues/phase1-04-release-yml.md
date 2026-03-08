# Phase 1-4: release.yml（GitHub Actions CD）完成

**Priority**: P0 (最優先)
**Estimate**: 半日
**Labels**: `phase-1`, `P0`, `ci-cd`
**Depends on**: Phase 1-1, 1-2, 1-3

---

## やること

gitタグ（`v0.1.0` など）をpushしたら、GitHub Actionsが自動で以下を実行するようにする：

```
タグpush → ビルド → 署名 → 公証 → DMG作成 → GitHub Releaseにアップロード
```

現在の `release.yml` はBlindCoreのビルド/テストだけで、App側のビルド〜DMGはTODOコメントのまま。

## なぜ自動化？

- 手動でやると手順を間違えやすい（署名忘れ、公証忘れ）
- タグをpushするだけでリリースできる = 開発にフォーカスできる
- 再現性がある（「前回はどうやってビルドしたっけ？」がなくなる）

## 手順

### 1. GitHub Secretsの設定

リポジトリの Settings → Secrets and variables → Actions → New repository secret:

| Secret名 | 値 | 説明 |
|-----------|------|------|
| `APPLE_ID` | your@email.com | Apple Developer アカウントのメール |
| `APPLE_PASSWORD` | App-specific Password | Phase 1-2で作成したもの |
| `TEAM_ID` | XXXXXXXXXX | Developer Program Team ID |
| `CERTIFICATE_P12` | Base64エンコードした証明書 | 下記参照 |
| `CERTIFICATE_PASSWORD` | P12パスワード | エクスポート時に設定 |

### 2. 証明書のBase64エンコード

GitHub ActionsのmacOSランナーには自分の証明書がないので、Secretsに入れる：

```bash
# キーチェーンから証明書をP12形式でエクスポート
# Keychain Access → 証明書を右クリック → Export
# パスワードを設定してP12で保存

# Base64エンコード
base64 -i Certificates.p12 | pbcopy
# クリップボードにコピーされる → CERTIFICATE_P12に貼り付け
```

### 3. release.ymlの更新

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build-and-release:
    runs-on: macos-14

    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Install certificate
        env:
          CERTIFICATE_P12: ${{ secrets.CERTIFICATE_P12 }}
          CERTIFICATE_PASSWORD: ${{ secrets.CERTIFICATE_PASSWORD }}
        run: |
          # 一時キーチェーンに証明書をインポート
          KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
          KEYCHAIN_PASSWORD=$(uuidgen)

          security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

          echo "$CERTIFICATE_P12" | base64 --decode > $RUNNER_TEMP/certificate.p12
          security import $RUNNER_TEMP/certificate.p12 \
            -P "$CERTIFICATE_PASSWORD" \
            -A -t cert -f pkcs12 \
            -k "$KEYCHAIN_PATH"

          security list-keychain -d user -s "$KEYCHAIN_PATH"

      - name: Build & Test BlindCore
        run: |
          cd Packages/BlindCore
          swift build -c release
          swift test

      - name: Archive App
        run: |
          xcodebuild -project App/Blind/Blind.xcodeproj \
            -scheme Blind \
            -configuration Release \
            -archivePath build/Blind.xcarchive \
            archive

      - name: Export & Sign
        env:
          TEAM_ID: ${{ secrets.TEAM_ID }}
        run: |
          cp -R build/Blind.xcarchive/Products/Applications/Blind.app build/
          codesign --deep --force --verify --verbose \
            --sign "Developer ID Application" \
            --options runtime \
            build/Blind.app

      - name: Notarize
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_PASSWORD: ${{ secrets.APPLE_PASSWORD }}
          TEAM_ID: ${{ secrets.TEAM_ID }}
        run: ./scripts/notarize.sh build/Blind.app

      - name: Create DMG
        run: |
          brew install create-dmg
          create-dmg \
            --volname "Blind" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "Blind.app" 150 190 \
            --app-drop-link 450 190 \
            "build/Blind.dmg" \
            "build/Blind.app"

          # DMG署名
          codesign --sign "Developer ID Application" build/Blind.dmg

          # DMG公証
          xcrun notarytool submit build/Blind.dmg \
            --apple-id "$APPLE_ID" \
            --password "$APPLE_PASSWORD" \
            --team-id "$TEAM_ID" \
            --wait
          xcrun stapler staple build/Blind.dmg

      - name: Checksums
        run: |
          cd build
          shasum -a 256 Blind.dmg > SHA256SUMS.txt
          cat SHA256SUMS.txt

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            build/Blind.dmg
            build/SHA256SUMS.txt
          body: |
            ## Blind ${{ github.ref_name }}

            ### Installation
            1. Download `Blind.dmg`
            2. Open and drag Blind to Applications
            3. Run Blind from Applications

            ### Checksums
            See `SHA256SUMS.txt`
          draft: false
```

### 4. テストリリース

```bash
# テストタグを打って、ワークフローの動作を確認
git tag v0.1.0-beta.1
git push origin v0.1.0-beta.1

# GitHub Actions タブでワークフローの進行を確認
# 失敗したらログを読んで修正
```

### よくあるトラブル

| 問題 | 原因 | 対処 |
|------|------|------|
| `errSecInternalComponent` | 証明書のインポート失敗 | CERTIFICATE_P12が正しくBase64されているか確認 |
| `No signing identity found` | 証明書がキーチェーンにない | `security list-keychain` でパスを確認 |
| `notarytool: package invalid` | Hardened Runtimeが無効 | Xcodeで設定確認 |
| `The signature is invalid` | 署名後にファイルが変更された | 署名→DMG→DMG署名の順序を確認 |

## 完了条件

- [ ] GitHub Secretsが全て設定済み
- [ ] テストタグで `release.yml` が最後まで成功する
- [ ] GitHub ReleaseにDMGとSHA256SUMSがアップロードされている
- [ ] DMGをダウンロードして、別のMacで起動できる
