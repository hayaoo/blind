import AppKit
import SwiftUI
import BlindCore

/// シグナルハンドラからアクセスするためのグローバル参照
private var _sharedAppDelegate: AppDelegate?

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var sessionWindow: NotchOverlayWindow?
    private var backdropWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var timerService: TimerService?
    private var sessionViewModel: SessionViewModel?
    private var escMonitor: Any?
    private var watchdog: WatchdogService?
    private var sessionTimeoutTimer: Timer?

    /// セッションタイムアウト（秒）
    private let sessionMaxDuration: TimeInterval = 120

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        _sharedAppDelegate = self

        UserDefaults.standard.register(defaults: [
            "reminderInterval": 30,
            "eyeCloseDuration": 5,
            "soundEnabled": true,
            "launchAtLogin": false
        ])

        // クラッシュリカバリ: 前回のセッションが未クリーン終了していれば音量復帰
        if VolumeControlService.shared.hasSavedVolume {
            VolumeControlService.shared.emergencyRestore()
        }

        setupSignalHandlers()
        NotificationService.shared.requestPermission()

        setupStatusItem()
        setupTimer()
        requestCameraPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 層4: 終了時に音量復帰 + ウィンドウ非表示
        emergencyCleanup()
    }

    // MARK: - Status Item (Menu Bar)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "Blind")
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        let startItem = NSMenuItem(title: "セッション開始", action: #selector(startSession), keyEquivalent: "s")
        startItem.target = self
        menu.addItem(startItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "設定...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "終了", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Session

    @MainActor
    @objc func startSession() {
        guard sessionWindow == nil else { return }

        let viewModel = SessionViewModel()
        viewModel.onSessionComplete = { [weak self] completed in
            self?.closeSession(completed: completed)
        }
        viewModel.onPhaseChanged = { [weak self] phase in
            self?.handlePhaseChange(phase)
        }
        viewModel.onEyesClosedChanged = { [weak self] closed in
            self?.handleEyesClosedChanged(closed)
        }
        sessionViewModel = viewModel

        // NotchOverlayWindow: ノッチに融合するオーバーレイ
        let window = NotchOverlayWindow()
        window.configureGeometry()

        let notchHeight = window.currentGeometry?.notchShapeHeight ?? 67
        var sessionView = NotchSessionView(
            viewModel: viewModel,
            displayMode: window.displayMode,
            notchZoneHeight: notchHeight
        )
        sessionView.onDismiss = { [weak self] in
            self?.closeSession(completed: false)
        }
        window.contentView = NSHostingView(rootView: sessionView)

        // Phase 1: summonフレームで表示開始
        window.applySummonFrame()
        window.makeKeyAndOrderFront(nil)
        sessionWindow = window

        // ESC key monitor (managed here, not in SwiftUI view)
        // .screenSaverレベルでも addLocalMonitorForEvents は動作する
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.closeSession(completed: false)
                return nil
            }
            return event
        }

        // 層1: Watchdog — メインスレッドハング検知
        let wd = WatchdogService()
        wd.onMainThreadHung = { [weak self] in
            // バックグラウンドスレッドから呼ばれる
            VolumeControlService.shared.emergencyRestore()
            DispatchQueue.main.async {
                self?.sessionWindow?.orderOut(nil)
                self?.closeSession(completed: false)
            }
        }
        wd.start()
        watchdog = wd

        // 層2: セッションタイムアウト
        sessionTimeoutTimer = Timer.scheduledTimer(withTimeInterval: sessionMaxDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.closeSession(completed: false)
            }
        }

        viewModel.startSession()
    }

    // MARK: - Eyes Closed → Fullscreen

    @MainActor
    private func handleEyesClosedChanged(_ closed: Bool) {
        guard sessionWindow != nil else { return }
        if closed {
            // 目を閉じた → バックドロップフェードイン + 音量フェードダウン
            VolumeControlService.shared.saveCurrentVolume()
            showBackdrop(duration: 2.0)
            Task {
                await VolumeControlService.shared.fadeDown(to: 0.02, duration: 2.0)
            }
        } else {
            // 目を開いた → バックドロップフェードアウト + 音量即時復帰
            hideBackdrop(duration: 0.4)
            VolumeControlService.shared.emergencyRestore()
        }
    }

    // MARK: - Phase Change Handler

    @MainActor
    private func handlePhaseChange(_ phase: SessionPhase) {
        guard let window = sessionWindow else { return }

        switch phase {
        case .summon:
            // Summon → Encounter アニメーション
            window.animateToEncounter(duration: 0.6) { [weak self] in
                self?.sessionViewModel?.onSummonAnimationComplete()
            }

        case .immersion:
            // encounter中に既にフルスクリーン拡大済み。音量も下げ済み。
            break

        case .awakening:
            // 音量を即時復帰してから完了音を鳴らす
            VolumeControlService.shared.emergencyRestore()
            SoundService.shared.playCompletionSound()
            hideBackdrop(duration: 0.8)
            // 覚醒アニメーション後に完了
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.sessionViewModel?.onAwakeningAnimationComplete()
            }

        case .completed:
            // ウィンドウを縮小して消す
            window.animateToDisappear(duration: 0.4) { [weak self] in
                self?.closeSession(completed: true)
            }

        case .cancelled:
            // 即座に音量復帰
            VolumeControlService.shared.emergencyRestore()

        default:
            break
        }
    }

    @MainActor
    private func closeSession(completed: Bool) {
        // Guard against double-close
        guard sessionWindow != nil || sessionViewModel != nil else { return }

        // 1. Stop safety mechanisms
        watchdog?.stop()
        watchdog = nil
        sessionTimeoutTimer?.invalidate()
        sessionTimeoutTimer = nil

        // 2. Remove event monitor
        if let monitor = escMonitor {
            NSEvent.removeMonitor(monitor)
            escMonitor = nil
        }

        // 3. Detach callbacks immediately to prevent re-entry
        let vm = sessionViewModel
        sessionViewModel = nil
        vm?.onSessionComplete = nil
        vm?.onPhaseChanged = nil
        vm?.onEyesClosedChanged = nil

        // 4. Stop session (camera/eye detection)
        vm?.stopSession()

        // 4.5. 安全ネット: 音量が下がったまま残っていれば復帰
        VolumeControlService.shared.emergencyRestore()

        // 5. Timer reset (sound is handled by phase transitions)
        timerService?.reset()

        // 6. Close backdrop
        backdropWindow?.orderOut(nil)
        backdropWindow = nil

        // 7. Close window safely (EXC_BAD_ACCESS防止: 次RunLoopサイクルで破棄)
        let window = sessionWindow
        sessionWindow = nil
        window?.safeClose()
    }

    // MARK: - Settings

    @objc private func openSettings() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
        } else {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 350, height: 250),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "設定"
            window.contentView = NSHostingView(rootView: SettingsView())
            window.center()
            window.isReleasedWhenClosed = false
            window.makeKeyAndOrderFront(nil)
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Timer

    private func setupTimer() {
        timerService = TimerService()
        timerService?.onTimerFired = { [weak self] in
            self?.showReminderNotification()
        }
        timerService?.start()
    }

    private func showReminderNotification() {
        NotificationService.shared.showReminder { [weak self] in
            DispatchQueue.main.async {
                self?.startSession()
            }
        }
    }

    // MARK: - Camera Permission

    private func requestCameraPermission() {
        CameraService.shared.requestPermission { [weak self] granted in
            if !granted {
                DispatchQueue.main.async {
                    self?.showCameraPermissionAlert()
                }
            }
        }
    }

    private func showCameraPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "カメラへのアクセスが必要です"
        alert.informativeText = "Blindは目の状態を検知するためにカメラを使用します。システム設定でカメラへのアクセスを許可してください。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "設定を開く")
        alert.addButton(withTitle: "キャンセル")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    // MARK: - URL Scheme (blind://)

    @MainActor
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard url.scheme == "blind" else { continue }
            switch url.host {
            case "start-session":
                startSession()
            case "settings":
                openSettings()
            default:
                break
            }
        }
    }

    // MARK: - Backdrop Window（全画面黒フェード）

    @MainActor
    private func showBackdrop(duration: TimeInterval = 0.3) {
        guard let screen = NSScreen.main, let sessionWin = sessionWindow else { return }

        if backdropWindow == nil {
            let w = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            w.backgroundColor = .black
            w.isOpaque = false
            w.hasShadow = false
            w.level = .screenSaver  // ノッチウィンドウと同レベル
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            w.ignoresMouseEvents = true
            w.isReleasedWhenClosed = false
            w.alphaValue = 0
            backdropWindow = w
        }

        backdropWindow?.setFrame(screen.frame, display: true)
        // ノッチウィンドウの真後ろに配置
        backdropWindow?.order(.below, relativeTo: sessionWin.windowNumber)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.backdropWindow?.animator().alphaValue = 1
        }
    }

    @MainActor
    private func hideBackdrop(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.backdropWindow?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.backdropWindow?.orderOut(nil)
            completion?()
        })
    }

    // MARK: - Safety: Emergency Cleanup

    /// 音量復帰 + ウィンドウ非表示（applicationWillTerminate / シグナルから呼ぶ）
    private func emergencyCleanup() {
        VolumeControlService.shared.emergencyRestore()
        backdropWindow?.orderOut(nil)
        sessionWindow?.orderOut(nil)
        watchdog?.stop()
    }

    // MARK: - Safety: Signal Handlers (層5)

    private func setupSignalHandlers() {
        // SIGTERM: Force Quit (Cmd+Opt+Esc) で送られる
        signal(SIGTERM) { _ in
            VolumeControlService.shared.emergencyRestore()
            _sharedAppDelegate?.sessionWindow?.orderOut(nil)
            exit(0)
        }
        // SIGINT: Ctrl+C
        signal(SIGINT) { _ in
            VolumeControlService.shared.emergencyRestore()
            _sharedAppDelegate?.sessionWindow?.orderOut(nil)
            exit(0)
        }
    }

    // MARK: - Quit

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
