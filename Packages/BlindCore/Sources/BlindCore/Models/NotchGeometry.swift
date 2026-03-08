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
    /// デバッグ用: displayMode を強制上書き
    public let displayModeOverride: DisplayMode?

    public init(
        screenWidth: CGFloat,
        screenHeight: CGFloat,
        safeAreaInsetsTop: CGFloat,
        auxiliaryTopLeftWidth: CGFloat,
        auxiliaryTopRightWidth: CGFloat,
        displayModeOverride: DisplayMode? = nil
    ) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.safeAreaInsetsTop = safeAreaInsetsTop
        self.auxiliaryTopLeftWidth = auxiliaryTopLeftWidth
        self.auxiliaryTopRightWidth = auxiliaryTopRightWidth
        self.displayModeOverride = displayModeOverride
    }

    // MARK: - Display Mode

    public var displayMode: DisplayMode {
        if let override = displayModeOverride { return override }
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

    /// 上部の物理領域の高さ（ノッチ/アイランド）。View側でbezelHeightとして使用。
    public var topHardwareHeight: CGFloat {
        switch displayMode {
        case .notch: return safeAreaInsetsTop
        case .island: return Self.islandHeight
        case .noNotch: return 0
        }
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
    public static let textBarHeight: CGFloat = 36

    /// オンボーディング用拡張テキスト帯のデフォルト高さ
    public static let onboardingTextBarHeight: CGFloat = 120

    /// 拡張オンボーディングのコンテンツタイプ別テキスト帯高さ
    public enum OnboardingContentHeight: CGFloat, Sendable {
        /// ブリッジ画面（短いテキストのみ）
        case bridge = 100
        /// 情報画面（タイトル+サブテキスト+ボタン）
        case info = 140
        /// 情報画面（パーソナライズテキスト、やや長め）
        case infoLarge = 180
        /// 質問画面（4選択肢）
        case question = 240
        /// 質問画面（5選択肢、複数選択）
        case questionLarge = 280
        /// カード表示画面（4タイプ表示、プラン表示）
        case cards = 260
        /// ペイウォール画面（機能カード3つ+CTA）
        case paywall = 320
    }

    /// ノッチ〜テキスト帯間のギャップ（透明）
    public static let gapHeight: CGFloat = 12

    /// ノッチ形状の下方拡張（目キャラ表示領域確保）
    private static let notchPaddingV: CGFloat = 30

    /// 凹角丸（外向き角丸）の半径。ウィンドウフレームの水平パディングにも使用。
    public static let concaveRadius: CGFloat = 10

    /// Dynamic Island の想定高さ（将来のハードウェア用）
    public static let islandHeight: CGFloat = 30

    // MARK: - Phase Frames

    /// Phase 1: ノッチ形状のみ表示するフレーム
    /// - `.notch`: 物理ノッチ下に配置。ノッチ幅に合わせ、上部にノッチ高さ分のpadding。
    /// - `.noNotch`: 画面上部中央に280×70。上辺フラット＋凹角丸。
    /// - `.island`: 画面上部中央に360×80のピル。アイランド想定位置の下に配置。
    public var summonFrame: CGRect {
        switch displayMode {
        case .notch:
            // 物理ノッチの下に表示。上部padding = ノッチ高さ（ノッチ領域を避ける）
            let bodyH: CGFloat = 80
            let padH = Self.concaveRadius
            return CGRect(
                x: notchRect.origin.x - padH,
                y: notchRect.origin.y - bodyH,
                width: notchRect.width + padH * 2,
                height: notchHeight + bodyH
            )
        case .noNotch:
            // スクリーン上端に融合するフェイクノッチ
            let w: CGFloat = 280
            let h: CGFloat = 70
            let padH = Self.concaveRadius
            return CGRect(
                x: (screenWidth - w) / 2 - padH,
                y: screenHeight - h,
                width: w + padH * 2,
                height: h
            )
        case .island:
            // アイランドの下に拡張。アイランド領域(上端から約30pt) + 本体を下方に配置。
            // アイランドとベゼルの隙間を潰さないよう、アイランド下端から開始。
            let w: CGFloat = 360
            let bodyH: CGFloat = 80
            let islandH = Self.islandHeight
            let topGap: CGFloat = 8  // スクリーン上端〜アイランドの隙間
            let padH = Self.concaveRadius
            return CGRect(
                x: (screenWidth - w) / 2 - padH,
                y: screenHeight - topGap - islandH - bodyH,
                width: w + padH * 2,
                height: islandH + bodyH
            )
        }
    }

    /// ウィンドウ内でのノッチシェイプの高さ
    public var notchShapeHeight: CGFloat {
        summonFrame.height
    }

    /// オンボーディング: summonFrame + ギャップ(12pt) + オンボーディングテキスト帯(80pt)を下方に拡張
    public var onboardingFrame: CGRect {
        let base = summonFrame
        let ext = Self.gapHeight + Self.onboardingTextBarHeight
        return CGRect(
            x: base.origin.x,
            y: base.origin.y - ext,
            width: base.width,
            height: base.height + ext
        )
    }

    /// 拡張オンボーディング: 動的高さのテキスト帯付きフレーム
    public func onboardingFrame(contentHeight: OnboardingContentHeight) -> CGRect {
        let base = summonFrame
        let ext = Self.gapHeight + contentHeight.rawValue
        return CGRect(
            x: base.origin.x,
            y: base.origin.y - ext,
            width: base.width,
            height: base.height + ext
        )
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
