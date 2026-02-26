import Foundation

public struct NotchGeometry: Equatable, Sendable {
    public let screenWidth: CGFloat
    public let screenHeight: CGFloat
    public let safeAreaInsetsTop: CGFloat
    public let auxiliaryTopLeftWidth: CGFloat
    public let auxiliaryTopRightWidth: CGFloat

    public init(
        screenWidth: CGFloat,
        screenHeight: CGFloat,
        safeAreaInsetsTop: CGFloat,
        auxiliaryTopLeftWidth: CGFloat,
        auxiliaryTopRightWidth: CGFloat
    ) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.safeAreaInsetsTop = safeAreaInsetsTop
        self.auxiliaryTopLeftWidth = auxiliaryTopLeftWidth
        self.auxiliaryTopRightWidth = auxiliaryTopRightWidth
    }

    // MARK: - Notch Detection

    public var hasNotch: Bool {
        safeAreaInsetsTop > 0
    }

    public var notchWidth: CGFloat {
        screenWidth - auxiliaryTopLeftWidth - auxiliaryTopRightWidth
    }

    public var notchHeight: CGFloat {
        safeAreaInsetsTop
    }

    /// ノッチ領域の矩形（macOS座標系: 左下原点）
    public var notchRect: CGRect {
        CGRect(
            x: auxiliaryTopLeftWidth,
            y: screenHeight - safeAreaInsetsTop,
            width: notchWidth,
            height: safeAreaInsetsTop
        )
    }

    // MARK: - Phase Frames

    /// Phase 1: ノッチにぴったり収まる初期フレーム
    /// ノッチなしの場合は画面上部中央に幅200x高さ32のピル
    public var summonFrame: CGRect {
        if hasNotch {
            return notchRect
        } else {
            let pillWidth: CGFloat = 200
            let pillHeight: CGFloat = 32
            return CGRect(
                x: (screenWidth - pillWidth) / 2,
                y: screenHeight - pillHeight,
                width: pillWidth,
                height: pillHeight
            )
        }
    }

    /// Phase 2: ノッチから下に200pt拡張
    public var encounterFrame: CGRect {
        let base = summonFrame
        let extensionHeight: CGFloat = 200
        return CGRect(
            x: base.origin.x,
            y: base.origin.y - extensionHeight,
            width: base.width,
            height: base.height + extensionHeight
        )
    }

    /// Phase 3: 画面全体
    public var fullscreenFrame: CGRect {
        CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
    }
}
