# Blind — CLAUDE.md

## プロジェクト概要

macOSメニューバーに常駐するマインドフルネスリマインダーアプリ。
「目を閉じる」という身体的アクションを通じて、意図的な中断を作り、
「今、正しいことをしているか？」を確認する機会を提供する。

## 技術スタック

- Swift 5.9+
- SwiftUI / AppKit
- Vision framework（目検知）
- AVFoundation（カメラ制御）
- macOS 14.0+ (Sonoma)

## ディレクトリ構造

```
Blind/
├── BlindApp.swift           # エントリーポイント
├── AppDelegate.swift        # メニューバー・セッション管理
├── Views/
│   ├── SessionView.swift    # セッション画面
│   └── SettingsView.swift   # 設定画面
├── ViewModels/
│   └── SessionViewModel.swift
├── Services/
│   ├── CameraService.swift      # カメラ制御
│   ├── EyeDetectionService.swift # 目検知（Vision）
│   ├── NotificationService.swift # 通知
│   ├── TimerService.swift        # タイマー
│   └── SoundService.swift        # サウンド
├── Models/
│   └── BlindSettings.swift
├── Resources/
│   └── Sounds/
└── Info.plist
```

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

## ビルド・実行

```bash
# Xcodeで開く
open Blind.xcodeproj

# コマンドラインビルド
xcodebuild -project Blind.xcodeproj -scheme Blind build
```

## 関連ドキュメント

- 要件書: `/Users/m/src/github.com/hayaoo/pomm/03_projects/blind/requirements.md`
- コンセプト: `/Users/m/src/github.com/hayaoo/pomm/03_projects/blind/concept.md`
- 競合調査: `/Users/m/src/github.com/hayaoo/pomm/03_projects/blind/competitors.md`
- MVP定義: `/Users/m/src/github.com/hayaoo/pomm/03_projects/blind/mvp.md`
