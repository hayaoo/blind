import AppKit
import SwiftUI
import BlindCore

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var sessionWindow: NSWindow?
    private var timerService: TimerService?
    private var sessionViewModel: SessionViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupTimer()
        requestCameraPermission()
    }

    // MARK: - Status Item (Menu Bar)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "Blind")
            button.action = #selector(statusItemClicked)
            button.target = self
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

    @objc private func statusItemClicked() {
        // Menu will be shown automatically
    }

    // MARK: - Session

    @objc func startSession() {
        guard sessionWindow == nil else { return }

        let viewModel = SessionViewModel()
        viewModel.onSessionComplete = { [weak self] in
            self?.closeSession()
        }
        sessionViewModel = viewModel

        let sessionView = SessionView(viewModel: viewModel)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 120),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.contentView = NSHostingView(rootView: sessionView)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Position below notch (center top of screen)
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let windowFrame = window.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.maxY - windowFrame.height - 50 // Below notch area
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.makeKeyAndOrderFront(nil)
        sessionWindow = window

        // Start camera detection
        viewModel.startSession()
    }

    private func closeSession() {
        sessionWindow?.close()
        sessionWindow = nil
        sessionViewModel?.stopSession()
        sessionViewModel = nil

        // Play completion sound
        SoundService.shared.playCompletionSound()

        // Reset timer for next reminder
        timerService?.reset()
    }

    // MARK: - Settings

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
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
            self?.startSession()
        }
    }

    // MARK: - Camera Permission

    private func requestCameraPermission() {
        CameraService.shared.requestPermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    self.showCameraPermissionAlert()
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

    // MARK: - Quit

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
