import Foundation

/// ディスプレイのノッチ形状モード
public enum DisplayMode: Equatable, Sendable {
    case notch      // MacBook Pro 2021+ (物理ノッチあり)
    case noNotch    // iMac, 旧MacBook, 外部ディスプレイ
    case island     // 将来のカメラアイランドMac
}

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

    // MARK: - Display Mode

    public var displayMode: DisplayMode {
        // TODO: island検知は将来のハードウェアで判定ロジックを追加
        if safeAreaInsetsTop > 0 {
            return .notch
        } else {
            return .noNotch
        }
    }

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

    // MARK: - Layout Constants

    /// テキスト帯の高さ
    public static let textBarHeight: CGFloat = 54

    /// ノッチ〜テキスト帯間のギャップ（透明）
    public static let gapHeight: CGFloat = 12

    /// ノッチ形状の下方拡張（目キャラ表示領域確保）
    private static let notchPaddingV: CGFloat = 30

    // MARK: - Phase Frames

    /// Phase 1: ノッチ形状のみ表示するフレーム
    /// - `.notch`: 物理ノッチ幅に合わせ、下方30pt拡張（目キャラ表示用）
    /// - `.noNotch`: 画面上部中央に280×70のフェイクノッチ
    /// - `.island`: 360×70の横長ピル
    public var summonFrame: CGRect {
        switch displayMode {
        case .notch:
            let padV = Self.notchPaddingV
            return CGRect(
                x: notchRect.origin.x,
                y: notchRect.origin.y - padV,
                width: notchRect.width,
                height: notchRect.height + padV
            )
        case .noNotch:
            let w: CGFloat = 280
            let h: CGFloat = 70
            return CGRect(
                x: (screenWidth - w) / 2,
                y: screenHeight - h,
                width: w,
                height: h
            )
        case .island:
            let w: CGFloat = 360
            let h: CGFloat = 70
            return CGRect(
                x: (screenWidth - w) / 2,
                y: screenHeight - h,
                width: w,
                height: h
            )
        }
    }

    /// ウィンドウ内でのノッチシェイプの高さ
    public var notchShapeHeight: CGFloat {
        summonFrame.height
    }

    /// Phase 2: summonFrame + ギャップ(12pt) + テキスト帯(54pt)を下方に拡張
    public var encounterFrame: CGRect {
        let base = summonFrame
        let ext = Self.gapHeight + Self.textBarHeight
        return CGRect(
            x: base.origin.x,
            y: base.origin.y - ext,
            width: base.width,
            height: base.height + ext
        )
    }

    /// Phase 3: 画面全体
    public var fullscreenFrame: CGRect {
        CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
    }
}
