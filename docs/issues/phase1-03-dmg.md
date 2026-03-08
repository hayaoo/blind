# Phase 1-3: DMGインストーラー作成

**Priority**: P0 (最優先)
**Estimate**: 2時間
**Labels**: `phase-1`, `P0`, `distribution`
**Depends on**: Phase 1-2

---

## やること

署名・公証済みの `.app` を `.dmg`（ディスクイメージ）にパッケージングする。
ユーザーはDMGを開いて、アプリをApplicationsフォルダにドラッグ&ドロップしてインストールする。

## なぜDMG？

macOSでは `.app` は実体としてはフォルダ。ZIPでも配布できるが、DMGにはメリットがある：

- Applicationsフォルダへのショートカットを並べて「ドラッグ&ドロップ」体験を提供
- 背景画像でブランディングできる
- ダブルクリックでマウントされるため、ユーザーにとって直感的
- Appleの公証チケットを staple できる

## 手順

### 1. create-dmg のインストール

DMGをきれいに作れるCLIツール：

```bash
brew install create-dmg
```

### 2. scripts/build.sh の完成

現在のbuild.shにDMG作成を追加する：

```bash
#!/bin/bash
set -e

APP_NAME="Blind"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

echo "=== Building $APP_NAME ==="

# 1. BlindCoreビルド（テスト）
echo "Building BlindCore..."
cd Packages/BlindCore
swift build -c release
cd ../..

# 2. Xcodeビルド（Archive）
echo "Archiving app..."
xcodebuild -project App/Blind/Blind.xcodeproj \
  -scheme Blind \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  archive

# 3. Archiveからappを取り出す
echo "Exporting app..."
cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME.app" "$APP_PATH"

# 4. DMG作成
echo "Creating DMG..."
create-dmg \
  --volname "$APP_NAME" \
  --volicon "App/Blind/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "$APP_NAME.app" 150 190 \
  --app-drop-link 450 190 \
  --hide-extension "$APP_NAME.app" \
  "$DMG_PATH" \
  "$APP_PATH"

echo "=== DMG created: $DMG_PATH ==="
```

### 3. DMGにも署名 + 公証

DMG自体にも署名と公証が必要：

```bash
# DMG署名
codesign --sign "Developer ID Application: Your Name ($TEAM_ID)" build/Blind.dmg

# DMG公証
xcrun notarytool submit build/Blind.dmg \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_PASSWORD" \
  --team-id "$TEAM_ID" \
  --wait

# DMGにチケット添付
xcrun stapler staple build/Blind.dmg
```

### 4. 手動テスト

```bash
# DMGを開く
open build/Blind.dmg

# マウントされたボリュームでアプリをApplicationsにドラッグ
# → Applicationsから起動 → Gatekeeperを通過するか確認
```

### 5. SHA256チェックサム

配布時にはチェックサムも提供する（改ざん検知）：

```bash
shasum -a 256 build/Blind.dmg > build/SHA256SUMS.txt
cat build/SHA256SUMS.txt
```

## AppIconについて

DMG作成時にアイコン（`.icns`）が必要。まだない場合：

1. 1024x1024のPNG画像を用意
2. `iconutil` で `.icns` に変換：

```bash
mkdir Blind.iconset
# 各サイズのPNGを配置（16, 32, 128, 256, 512, 1024）
sips -z 16 16 icon.png --out Blind.iconset/icon_16x16.png
sips -z 32 32 icon.png --out Blind.iconset/icon_16x16@2x.png
# ... 全サイズ
iconutil -c icns Blind.iconset -o App/Blind/Resources/AppIcon.icns
```

> アイコンがまだない場合は、DMG作成時の `--volicon` オプションを省略すればOK。

## 完了条件

- [ ] `./scripts/build.sh` でDMGが生成される
- [ ] DMGをダブルクリックでマウントできる
- [ ] アプリアイコンとApplicationsショートカットが表示される
- [ ] ドラッグ&ドロップでインストール → 起動できる
- [ ] SHA256SUMSが生成される
