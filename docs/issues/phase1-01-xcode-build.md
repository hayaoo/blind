# Phase 1-1: Xcodeでビルドを通す

**Priority**: P0 (最優先)
**Estimate**: 半日
**Labels**: `phase-1`, `P0`, `build`

---

## やること

現在のコードはSwiftPMの `swift build` では通るが、Xcodeでの完全ビルド（App側含む）が未確認。
実際にMac上でアプリとして動かすには、Xcode上でビルドが通る必要がある。

## なぜ必要？

- `swift build` はBlindCoreパッケージだけをビルドしている
- App側（`App/Blind/`）にはAppKit/SwiftUIのコードがあり、これはXcode経由でないとビルドできない
- 実機で動かすには `.app` バンドルが必要 → Xcodeビルド必須

## 手順（初心者向け）

### 1. Xcodeプロジェクトを開く

```bash
open App/Blind/Blind.xcodeproj
```

Xcodeが起動し、プロジェクトが開く。

### 2. スキームとターゲットの確認

左上のスキーム選択（再生ボタンの右隣）で「Blind」スキームが選ばれていることを確認。
ターゲットOSは「My Mac」を選択。

### 3. BlindCoreパッケージの依存設定

Xcodeプロジェクトが `Packages/BlindCore` をローカルパッケージとして参照しているか確認：

1. プロジェクトナビゲーター（左パネル）でプロジェクトルート「Blind」をクリック
2. 「Blind」ターゲット → 「General」タブ → 「Frameworks, Libraries, and Embedded Content」
3. 「BlindCore」が一覧にあるか確認。なければ「+」で追加

**ローカルパッケージの追加方法**（もしまだの場合）:
1. File → Add Package Dependencies...
2. 左下の「Add Local...」をクリック
3. `Packages/BlindCore` フォルダを選択

### 4. ビルド実行

`⌘B`（Command + B）でビルド。

### 5. エラーの解消

よくあるエラーと対処:

| エラー | 原因 | 対処 |
|--------|------|------|
| `No such module 'BlindCore'` | パッケージ依存が設定されていない | 手順3を実施 |
| `Cannot find 'xxx' in scope` | import漏れ or 型名の不一致 | `import BlindCore` の確認、型名の確認 |
| `Type 'xxx' has no member 'yyy'` | BlindCoreの変更がApp側に反映されていない | Clean Build (⌘⇧K) → 再ビルド |
| `Signing requires a development team` | 開発チーム未設定 | 手順6参照 |

### 6. 署名設定（ビルド確認用の一時設定）

ビルド確認だけなら、自分のApple IDで署名すればOK：

1. ターゲット「Blind」→「Signing & Capabilities」
2. 「Team」で自分のApple ID（Personal Team）を選択
3. 「Signing Certificate」は「Sign to Run Locally」でOK

> **注意**: これは開発用の設定。配布用の署名はPhase 1-2（コード署名+公証）で別途設定する。

### 7. 実行テスト

`⌘R`（Command + R）で実行。メニューバーにBlindアイコンが表示されれば成功。

## 完了条件

- [ ] `⌘B` でエラーなくビルドが通る
- [ ] `⌘R` でアプリが起動し、メニューバーにアイコンが表示される
- [ ] オンボーディングフローが開始される（初回起動時）
