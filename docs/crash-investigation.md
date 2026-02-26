# EXC_BAD_ACCESS クラッシュ調査記録

- **Status**: OPEN（未解決）
- **Date**: 2026-02-26
- **環境**: macOS 15.6.1 (24G90), Xcode 16.x, Swift 6.2.3, arm64

---

## 症状

セッション完了（目を5秒閉じた後）にアプリがクラッシュし、メニューバーからアイコンが消える。

## クラッシュスタックトレース（全ケース共通）

```
libobjc.A.dylib: objc_release              ← 0x20 のアドレスを release しようとして SIGSEGV
libobjc.A.dylib: AutoreleasePoolPage::releaseUntil(objc_object**)
libobjc.A.dylib: objc_autoreleasePoolPop
CoreFoundation: _CFAutoreleasePoolPop
CoreFoundation: __CFRunLoopPerCalloutARPEnd
CoreFoundation: __CFRunLoopRun
...
AppKit: -[NSApplication run]
```

- アドレス: `0x0000000000000020`（nilポインタ + offset 0x20）
- RunLoopのautorelease pool drainで発生
- **アプリ固有コードがスタックに出ない**

---

## 重大な発見: NSZombie で検出されなかった

```bash
OBJC_DEBUG_ZOMBIE_OBJECTS=YES MallocStackLogging=1 ./Blind
```

**結果**: Zombieメッセージなし。Exit code 139 (SIGSEGV)。

### これが意味すること

- **NOT** 解放済みObjCオブジェクトへのメッセージ送信
- **IS** autorelease poolに格納されたポインタ自体が不正（corrupt）
- → **cross-thread autorelease pool corruption** が最有力

### 直前のログ

```
AVCaptureDeviceTypeExternal is deprecated for Continuity Cameras...
FBBA: creating VNFaceBBoxAligner from VNFaceDetectorRevision2
```

Vision frameworkの `VNFaceBBoxAligner` が生成された直後にクラッシュ。

---

## 根本原因の最有力仮説

### **Cross-thread autorelease pool corruption（VNImageRequestHandler由来）**

1. `EyeDetectionService.processFrame()` が `sessionQueue`（バックグラウンド）で実行
2. `VNImageRequestHandler.perform()` がVisionの内部オブジェクトをautorelease
3. `notifyEyeState()` が `DispatchQueue.main.async` でメインスレッドにディスパッチ
4. セッション完了 → `stopSession()` → `EyeDetectionService.stop()` → `CameraService.stopCapture()`
5. **`stopCapture()` は `sessionQueue.async` で非同期停止** → stopが完了する前にメインスレッドのRunLoopのautorelease poolがdrain
6. Vision内部のautoreleasedオブジェクトがスレッド間で不整合 → SIGSEGV

**根拠**:
- NSZombieで検出されない = ObjCメッセージではなく、ポインタ自体が不正
- Vision frameworkのログが直前に出力される
- `sessionQueue.async` でstopが非同期 → 停止完了前にオブジェクト解放の可能性
- クラッシュがアプリ固有コードなし → Framework内部の問題

---

## 試みた解決策と結果（時系列）

| # | 解決策 | 効果 | 理由 |
|---|--------|------|------|
| 1 | `applicationShouldTerminateAfterLastWindowClosed → false` | ✗ | クラッシュは正常終了ではなくSIGSEGV |
| 2 | `closeSession`を`DispatchQueue.main.async`で遅延 | ✗ | 問題はRunLoopレベルで発生 |
| 3 | `completeSession`にguard + callback capture | ✗ | 問題はVM解放ではなくVision framework |
| 4 | Settings を手動NSWindow管理に変更 | ✗ | 設定画面は無関係 |
| 5 | `@MainActor`をAppDelegateに追加 | △ | ビルドエラー修正のみ |
| 6 | SwiftUI App → 純粋AppKit (`main.swift`) に移行 | ✗ | SwiftUI Appプロトコルは原因ではない |
| 7 | NSEvent monitor をSessionViewから排除 | ✗ | event monitorは原因ではない |
| 8 | `window.contentView = nil` でNSHostingView先行解除 | ✗ | 問題はView解放ではない |
| 9 | NSZombie + MallocStackLogging | 情報 | **検出されず** = ポインタ破損 |

### 反省点

1. **仮説の検証順序が非効率だった**: 5回もUI/ウィンドウ管理を変更したが、問題はそこではなかった。先にNSZombieで切り分けるべきだった。
2. **スタックトレースの「アプリ固有コードなし」を軽視した**: Framework内部の問題 = スレッド安全性の問題である可能性をもっと早く考慮すべきだった。
3. **非同期停止の危険性を過小評価**: `sessionQueue.async { stopRunning() }` が根本原因の可能性が高いが、着手が遅かった。

---

## 推奨する次のステップ（優先順）

### 1. CameraService.stopCapture() を同期停止に変更（最優先）

```swift
public func stopCapture() {
    // sync で完全停止を待つ（バックグラウンドスレッドから呼ばない）
    sessionQueue.sync {
        self.captureSession?.stopRunning()
        self.captureSession = nil
        self.videoOutput = nil
    }
}
```

**理由**: Vision request の in-flight 処理をすべて完了させてからメインスレッドに戻る。

### 2. EyeDetectionService.stop() でコールバックを先に切断

```swift
public func stop() {
    isRunning = false
    onEyeStateChanged = nil       // コールバック先に切断
    cameraService.onFrameCaptured = nil  // フレーム処理を即座に停止
    cameraService.stopCapture()   // 同期停止
}
```

### 3. SessionViewModel の Timer を stopSession 内で確実に停止

```swift
func stopSession() {
    isActive = false
    closedTimer?.invalidate()
    closedTimer = nil
    eyeDetectionService?.stop()   // 同期停止を待つ
    eyeDetectionService = nil
}
```

### 4. Address Sanitizer でさらなる検証

Xcodeの Scheme > Run > Diagnostics > Address Sanitizer を有効にしてデバッグ。
メモリ破損の正確な箇所を特定できる。

### 5. Thread Sanitizer で競合検出

Xcodeの Scheme > Run > Diagnostics > Thread Sanitizer を有効にして、
スレッド間の不正アクセスを検出。

---

## macOSカメラ修正（解決済み）

### 問題
`AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)` が
macOSでは `nil` を返す。

### 解決
```swift
AVCaptureDevice.default(for: .video)  // macOS対応
```

---

## ファイル構成（現在）

- `App/Blind/main.swift` — 純粋AppKit起動（SwiftUI App不使用）
- `App/Blind/BlindApp.swift` — 空ファイル（無効化済み）
- `App/Blind/AppDelegate.swift` — メインのアプリ制御 + ESCキー処理
- `App/Blind/ViewModels/SessionViewModel.swift` — セッション状態管理
- `App/Blind/Views/SessionView.swift` — セッションUI（event monitor なし）
- `Packages/BlindCore/Sources/BlindCore/Services/CameraService.swift` — カメラ制御
- `Packages/BlindCore/Sources/BlindCore/Services/EyeDetectionService.swift` — 目検知
