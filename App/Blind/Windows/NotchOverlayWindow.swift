import AppKit
import BlindCore

/// ノッチに融合するオーバーレイウィンドウ。
/// .screenSaverレベルで全アプリの上に表示される。
/// フェーズに応じてフレームをアニメーション付きで変更する。
class NotchOverlayWindow: NSWindow {

    private var geometry: NotchGeometry?

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isReleasedWhenClosed = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        ignoresMouseEvents = false
        isMovableByWindowBackground = false
    }

    // MARK: - Geometry

    /// 現在のスクリーンからNotchGeometryを計算してキャッシュ
    func configureGeometry() {
        guard let screen = NSScreen.main else { return }
        let frame = screen.frame
        let safeTop = screen.safeAreaInsets.top
        let auxLeft = screen.auxiliaryTopLeftArea?.width ?? 0
        let auxRight = screen.auxiliaryTopRightArea?.width ?? 0

        geometry = NotchGeometry(
            screenWidth: frame.width,
            screenHeight: frame.height,
            safeAreaInsetsTop: safeTop,
            auxiliaryTopLeftWidth: auxLeft,
            auxiliaryTopRightWidth: auxRight
        )
    }

    var currentGeometry: NotchGeometry? { geometry }

    var hasNotch: Bool { geometry?.hasNotch ?? false }

    // MARK: - Phase Frames

    /// 画面座標系でのフレームを返す（screenのoriginをオフセット）
    private func screenFrame(for rect: CGRect) -> CGRect {
        guard let screen = NSScreen.main else { return rect }
        return CGRect(
            x: screen.frame.origin.x + rect.origin.x,
            y: screen.frame.origin.y + rect.origin.y,
            width: rect.width,
            height: rect.height
        )
    }

    /// Phase 1: summonフレーム（ノッチサイズ）
    func applySummonFrame() {
        guard let geo = geometry else { return }
        setFrame(screenFrame(for: geo.summonFrame), display: true)
    }

    /// Phase 2: encounterフレーム（ノッチ + 下200pt拡張）
    func animateToEncounter(duration: TimeInterval = 0.6, completion: (() -> Void)? = nil) {
        guard let geo = geometry else { return }
        let target = screenFrame(for: geo.encounterFrame)

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().setFrame(target, display: true)
        }, completionHandler: completion)
    }

    /// Phase 3: フルスクリーンへ拡大
    func animateToFullscreen(duration: TimeInterval = 0.8, completion: (() -> Void)? = nil) {
        guard let geo = geometry else { return }
        let target = screenFrame(for: geo.fullscreenFrame)

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().setFrame(target, display: true)
        }, completionHandler: completion)
    }

    /// Phase 4: フルスクリーンからencounterサイズへ縮小
    func animateToShrink(duration: TimeInterval = 0.8, completion: (() -> Void)? = nil) {
        guard let geo = geometry else { return }
        let target = screenFrame(for: geo.encounterFrame)

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().setFrame(target, display: true)
        }, completionHandler: completion)
    }

    /// summonフレームへ縮小して消滅
    func animateToDisappear(duration: TimeInterval = 0.4, completion: (() -> Void)? = nil) {
        guard let geo = geometry else { return }
        let target = screenFrame(for: geo.summonFrame)

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().setFrame(target, display: true)
        }, completionHandler: completion)
    }

    // MARK: - Safe Close

    /// EXC_BAD_ACCESS防止: 次のRunLoopサイクルでclose
    func safeClose() {
        DispatchQueue.main.async { [weak self] in
            self?.contentView = nil
            self?.close()
        }
    }

    // MARK: - Key handling

    /// ESCキーをこのウィンドウレベルでも受け取れるようにする
    override var canBecomeKey: Bool { true }

    /// ノッチなしの場合に角丸を適用
    func applyRoundedCorners(radius: CGFloat = 16) {
        guard let geo = geometry, !geo.hasNotch else { return }
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = radius
        contentView?.layer?.masksToBounds = true
    }
}
