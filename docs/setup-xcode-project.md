# Xcodeプロジェクト作成手順

このドキュメントでは、Blind Appの Xcodeプロジェクトを作成し、BlindCoreパッケージと連携させる手順を説明します。

---

## 前提条件

- macOS 14.0 (Sonoma) 以上
- Xcode 15.0 以上
- Apple Developer ID（署名・公証用、後で設定可）

---

## 手順

### 1. Xcodeでプロジェクト作成

1. Xcodeを起動
2. **File → New → Project** (⌘⇧N)
3. **macOS** タブを選択
4. **App** を選択して **Next**

### 2. プロジェクト設定

| 項目 | 値 |
|------|-----|
| Product Name | `Blind` |
| Team | 自分のApple Developer ID（または None） |
| Organization Identifier | `com.hayaoo` |
| Bundle Identifier | `com.hayaoo.blind`（自動生成） |
| Interface | **SwiftUI** |
| Language | **Swift** |
| Storage | None |
| Include Tests | ✓ チェック |

**Next** をクリック

### 3. 保存先の選択

1. 保存先: `/Users/m/src/github.com/hayaoo/blind/App/Blind/`
2. **Create** をクリック

⚠️ 既存の `App/Blind/` フォルダに保存することで、既存ファイルと統合します。

### 4. 既存ファイルの統合

Xcodeが開いたら、既存のSwiftファイルをプロジェクトに追加：

1. **File → Add Files to "Blind"** (⌥⌘A)
2. 以下のファイルを選択（⌘クリックで複数選択）:
   - `AppDelegate.swift`
   - `Views/SessionView.swift`
   - `Views/SettingsView.swift`
   - `ViewModels/SessionViewModel.swift`
   - `Info.plist`
3. **Options**:
   - ✓ Copy items if needed: **オフ**
   - ✓ Create groups: **オン**
   - Add to targets: **Blind** にチェック
4. **Add** をクリック

### 5. 自動生成ファイルの削除

Xcodeが自動生成した以下のファイルを削除（既存ファイルと重複するため）:

1. プロジェクトナビゲーターで右クリック → **Delete**
   - `ContentView.swift`（自動生成）
   - `BlindApp.swift`（自動生成、既存を使用）

### 6. BlindCoreパッケージの追加

1. **File → Add Package Dependencies** (⌃⇧⌘D)
2. **Add Local** をクリック
3. `/Users/m/src/github.com/hayaoo/blind/Packages/BlindCore` を選択
4. **Add Package** をクリック
5. Target: **Blind** にチェックして **Add Package**

### 7. Info.plist の設定

1. プロジェクトナビゲーターで **Blind** プロジェクトを選択
2. **TARGETS → Blind → Info** タブ
3. 以下の項目を追加/確認:

| Key | Value |
|-----|-------|
| Application is agent (UIElement) | YES |
| Privacy - Camera Usage Description | Blindは目の状態を検知するためにカメラを使用します。 |
| Bundle display name | Blind |

または、既存の `Info.plist` を使用：
1. **Build Settings** で検索: `Info.plist`
2. **Info.plist File** を `App/Blind/Info.plist` に変更

### 8. App Delegate の設定

1. `BlindApp.swift` を開く
2. 以下の内容になっていることを確認:

```swift
import SwiftUI

@main
struct BlindApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
```

### 9. Signing の設定

1. **TARGETS → Blind → Signing & Capabilities**
2. Team: 自分のApple Developer ID を選択
3. Signing Certificate: **Development**（開発用）または **Developer ID Application**（配布用）

⚠️ Developer IDがない場合は「None」でも開発・テストは可能。配布時に必要。

### 10. ビルド・実行

1. スキームを **Blind** に設定
2. **Product → Build** (⌘B)
3. エラーがないことを確認
4. **Product → Run** (⌘R)

---

## トラブルシューティング

### BlindCoreが見つからない

```
No such module 'BlindCore'
```

**解決方法**:
1. **File → Packages → Reset Package Caches**
2. **Product → Clean Build Folder** (⌘⇧K)
3. 再ビルド

### カメラ権限のエラー

```
This app has crashed because it attempted to access privacy-sensitive data
```

**解決方法**:
Info.plistに `NSCameraUsageDescription` が設定されていることを確認。

### メニューバーにアイコンが表示されない

**解決方法**:
1. `Info.plist` に `LSUIElement = YES` が設定されていることを確認
2. AppDelegateの `setupStatusItem()` が呼ばれていることを確認

---

## 確認チェックリスト

- [ ] ビルドが成功する
- [ ] メニューバーにアイコンが表示される
- [ ] 「セッション開始」をクリックでセッション画面が表示される
- [ ] カメラ権限のダイアログが表示される
- [ ] 目を閉じると赤色、開くと緑色になる
- [ ] 5秒間目を閉じるとセッションが終了する

---

## 次のステップ

1. [ ] 自分で1週間使ってみる
2. [ ] UIの調整
3. [ ] 署名・公証の設定
4. [ ] リリース準備
