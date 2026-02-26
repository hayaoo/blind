import SwiftUI

// MARK: - State

enum EyeCharacterState: Equatable {
    case searching              // .noFace: キョロキョロ探索
    case tracking               // .open: ユーザーにロックオン + 定期まばたき
    case closing(progress: Double)  // .closed: 閉じるアニメーション (0→1)
    case closed                 // 完全に閉じた状態
    case winking                // 覚醒ウインク
    case idle                   // デフォルト、中央を向いて待機
}

// MARK: - View

/// EEAAO風ギョロ目キャラクター。
/// まん丸の白目 + まん丸の黒目。
struct EyeCharacterView: View {
    let state: EyeCharacterState
    let size: CGSize

    @State private var startDate = Date()
    @State private var winkStartDate: Date?

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince(startDate)
            Canvas { context, canvasSize in
                drawEyes(context: context, size: canvasSize, time: time)
            }
        }
        .frame(width: size.width, height: size.height)
        .onChange(of: state) { oldValue, newValue in
            if case .winking = newValue, !(oldValue == .winking) {
                winkStartDate = Date()
            }
        }
    }

    // MARK: - Drawing

    private func drawEyes(context: GraphicsContext, size: CGSize, time: Double) {
        // ギョロ目: わずかに縦長（1:1.15）
        let baseDiameter = min(size.width * 0.38, size.height * 0.80)
        let eyeWidth = baseDiameter
        let eyeHeight = baseDiameter * 1.15  // 縦長比率
        let eyeGap = baseDiameter * 0.15
        let pupilDiameter = baseDiameter * 0.55  // 大きな黒目

        let centerY = size.height / 2
        let leftCenterX = size.width / 2 - eyeGap / 2 - eyeWidth / 2
        let rightCenterX = size.width / 2 + eyeGap / 2 + eyeWidth / 2

        // アニメーションパラメータ計算
        let (pupilOffset, lidClose, leftLidClose, rightLidClose) = computeAnimParams(
            time: time, eyeDiameter: baseDiameter
        )

        // 左目
        drawGooglyEye(
            context: context,
            center: CGPoint(x: leftCenterX, y: centerY),
            eyeWidth: eyeWidth,
            eyeHeight: eyeHeight,
            pupilDiameter: pupilDiameter,
            pupilOffset: pupilOffset,
            lidCloseFactor: leftLidClose ?? lidClose
        )

        // 右目
        drawGooglyEye(
            context: context,
            center: CGPoint(x: rightCenterX, y: centerY),
            eyeWidth: eyeWidth,
            eyeHeight: eyeHeight,
            pupilDiameter: pupilDiameter,
            pupilOffset: pupilOffset,
            lidCloseFactor: rightLidClose ?? lidClose
        )
    }

    /// (pupilOffset, lidClose, optionalLeftLid, optionalRightLid)
    private func computeAnimParams(
        time: Double,
        eyeDiameter: CGFloat
    ) -> (CGPoint, CGFloat, CGFloat?, CGFloat?) {
        let maxPupilTravel = eyeDiameter * 0.18  // 白目内での移動範囲

        switch state {
        case .idle:
            return (.zero, 0, nil, nil)

        case .searching:
            // サッケード風: 注視点に留まり→急速移動→次の注視点に留まる
            // 複数のレイヤーを合成して自然な不規則性を出す
            let dx = saccadeLayered(time: time, axis: 0) * maxPupilTravel
            let dy = saccadeLayered(time: time, axis: 1) * maxPupilTravel * 0.7
            return (CGPoint(x: dx, y: dy), 0, nil, nil)

        case .tracking:
            let blinkFactor = computeTrackingBlink(time: time)
            // 微かに揺れる（生きてる感じ）
            let dx = sin(time * 0.3) * eyeDiameter * 0.02
            let dy = cos(time * 0.5) * eyeDiameter * 0.01
            return (CGPoint(x: dx, y: dy), blinkFactor, nil, nil)

        case .closing(let progress):
            let clamped = min(max(progress, 0), 1)
            return (.zero, clamped, nil, nil)

        case .closed:
            return (.zero, 1, nil, nil)

        case .winking:
            let elapsed: Double
            if let ws = winkStartDate {
                elapsed = Date().timeIntervalSince(ws)
            } else {
                elapsed = 0
            }
            // 右目が先に開く: 0→0.5s (1→0)
            let rightClose = max(0, 1 - min(elapsed / 0.5, 1))
            // 左目は0.2s遅れ: 0.2→0.7s (1→0)
            let leftElapsed = max(0, elapsed - 0.2)
            let leftClose = max(0, 1 - min(leftElapsed / 0.5, 1))
            return (.zero, 0, CGFloat(leftClose), CGFloat(rightClose))
        }
    }

    /// 3〜5秒周期のまばたき
    private func computeTrackingBlink(time: Double) -> CGFloat {
        let blinkDuration = 0.12
        let interval = 3.5
        let cycleTime = time.truncatingRemainder(dividingBy: interval)
        let blinkStart = interval - blinkDuration

        if cycleTime >= blinkStart {
            let t = (cycleTime - blinkStart) / blinkDuration
            // 三角波: 0→1→0
            return CGFloat(t < 0.5 ? t * 2 : (1 - t) * 2)
        }
        return 0
    }

    /// サッケード風の有機的な動き生成。
    /// 注視点間をsmoothstepで急速に移動し、注視点では長く留まる。
    /// 複数の周波数レイヤーを合成して繰り返し感を排除。
    private func saccadeLayered(time: Double, axis: Int) -> CGFloat {
        // 主レイヤー: 大きな移動（1.8〜3.2秒周期）
        let primary = saccadeSegment(
            time: time,
            holdDuration: axis == 0 ? 1.8 : 2.1,
            moveDuration: 0.15,
            seed: axis == 0 ? 0.73 : 1.37
        )
        // 副レイヤー: 微かな揺らぎ（0.4〜0.8秒周期）
        let micro = saccadeSegment(
            time: time,
            holdDuration: axis == 0 ? 0.5 : 0.6,
            moveDuration: 0.08,
            seed: axis == 0 ? 3.17 : 2.53
        ) * 0.15
        return primary + micro
    }

    /// 1つのサッケードセグメント。
    /// holdDuration秒注視 → moveDuration秒で次の位置へsmoothstep遷移。
    /// seedで疑似乱数的に注視位置を決定。
    private func saccadeSegment(time: Double, holdDuration: Double, moveDuration: Double, seed: Double) -> CGFloat {
        let cycleDuration = holdDuration + moveDuration
        let cycle = Int(time / cycleDuration)
        let cycleTime = time - Double(cycle) * cycleDuration

        // 疑似乱数で注視位置を生成（sinのハッシュ的利用）
        func fixationPoint(_ index: Int) -> Double {
            let hash = sin(Double(index) * seed * 127.1 + seed * 311.7)
            return hash * 0.85  // -0.85 ~ 0.85
        }

        let from = fixationPoint(cycle)
        let to = fixationPoint(cycle + 1)

        if cycleTime < holdDuration {
            // 注視中: 微細な震え（マイクロサッケード）
            let tremor = sin(time * 23.0 + seed) * 0.02
            return CGFloat(from + tremor)
        } else {
            // 移動中: smoothstepで加速→減速
            let t = (cycleTime - holdDuration) / moveDuration
            let smooth = t * t * (3.0 - 2.0 * t)  // smoothstep
            return CGFloat(from + (to - from) * smooth)
        }
    }

    // MARK: - Single Googly Eye

    private func drawGooglyEye(
        context: GraphicsContext,
        center: CGPoint,
        eyeWidth: CGFloat,
        eyeHeight: CGFloat,
        pupilDiameter: CGFloat,
        pupilOffset: CGPoint,
        lidCloseFactor: CGFloat
    ) {
        let eyeRadiusX = eyeWidth / 2
        let eyeRadiusY = eyeHeight / 2

        // --- 白目（わずかに縦長の楕円）---
        let eyeRect = CGRect(
            x: center.x - eyeRadiusX,
            y: center.y - eyeRadiusY,
            width: eyeWidth,
            height: eyeHeight
        )
        let eyePath = Path(ellipseIn: eyeRect)

        // 白目
        context.fill(eyePath, with: .color(.white))

        // 黒ボーダー（アイコニックな輪郭）
        context.stroke(eyePath, with: .color(.black), lineWidth: eyeWidth * 0.04)

        // --- クリッピング: 白目の円内に制限 ---
        var clipped = context
        clipped.clipToLayer { clipCtx in
            clipCtx.fill(eyePath, with: .color(.white))
        }

        // --- 瞳（まん丸の黒目 — 背景と同じ黒）---
        let pupilCenter = CGPoint(
            x: center.x + pupilOffset.x,
            y: center.y + pupilOffset.y
        )
        let pupilRadius = pupilDiameter / 2
        let pupilRect = CGRect(
            x: pupilCenter.x - pupilRadius,
            y: pupilCenter.y - pupilRadius,
            width: pupilDiameter,
            height: pupilDiameter
        )
        let pupilPath = Path(ellipseIn: pupilRect)
        clipped.fill(pupilPath, with: .color(.black))

        // --- 瞳のハイライト（白い点、生命感）---
        let highlightSize = pupilDiameter * 0.18
        let highlightOffset = pupilDiameter * 0.2
        let highlightRect = CGRect(
            x: pupilCenter.x - highlightOffset - highlightSize / 2,
            y: pupilCenter.y - highlightOffset - highlightSize / 2,
            width: highlightSize,
            height: highlightSize
        )
        clipped.fill(Path(ellipseIn: highlightRect), with: .color(.white.opacity(0.9)))

        // 小さなサブハイライト
        let subHighlightSize = highlightSize * 0.5
        let subHighlightRect = CGRect(
            x: pupilCenter.x + highlightOffset * 0.5 - subHighlightSize / 2,
            y: pupilCenter.y + highlightOffset * 0.3 - subHighlightSize / 2,
            width: subHighlightSize,
            height: subHighlightSize
        )
        clipped.fill(Path(ellipseIn: subHighlightRect), with: .color(.white.opacity(0.5)))

        // --- まぶた ---
        if lidCloseFactor > 0.001 {
            drawEyelids(
                context: context,
                center: center,
                eyeRadiusX: eyeRadiusX,
                eyeRadiusY: eyeRadiusY,
                closeFactor: lidCloseFactor
            )
        }
    }

    // MARK: - Eyelids

    private func drawEyelids(
        context: GraphicsContext,
        center: CGPoint,
        eyeRadiusX: CGFloat,
        eyeRadiusY: CGFloat,
        closeFactor: CGFloat
    ) {
        let rx = eyeRadiusX * 1.05  // 少しはみ出してエッジを隠す
        let ry = eyeRadiusY * 1.05

        // 上まぶた: 半円が上から降りてくる
        let upperRestY = center.y - ry
        let upperTargetY = center.y
        let upperY = upperRestY + (upperTargetY - upperRestY) * closeFactor

        var upperLid = Path()
        upperLid.move(to: CGPoint(x: center.x - rx, y: upperRestY - 2))
        upperLid.addLine(to: CGPoint(x: center.x + rx, y: upperRestY - 2))
        upperLid.addLine(to: CGPoint(x: center.x + rx, y: upperY))
        // 閉じるときは丸みを帯びたカーブ
        let upperBulge = ry * 0.35 * (1 - closeFactor)
        upperLid.addQuadCurve(
            to: CGPoint(x: center.x - rx, y: upperY),
            control: CGPoint(x: center.x, y: upperY + upperBulge)
        )
        upperLid.closeSubpath()
        context.fill(upperLid, with: .color(.black))

        // 下まぶた: 下から上がってくる
        let lowerRestY = center.y + ry
        let lowerTargetY = center.y
        let lowerY = lowerRestY + (lowerTargetY - lowerRestY) * closeFactor
        let lowerBulge = ry * 0.35 * (1 - closeFactor)

        var lowerLid = Path()
        lowerLid.move(to: CGPoint(x: center.x - rx, y: lowerRestY + 2))
        lowerLid.addLine(to: CGPoint(x: center.x + rx, y: lowerRestY + 2))
        lowerLid.addLine(to: CGPoint(x: center.x + rx, y: lowerY))
        lowerLid.addQuadCurve(
            to: CGPoint(x: center.x - rx, y: lowerY),
            control: CGPoint(x: center.x, y: lowerY - lowerBulge)
        )
        lowerLid.closeSubpath()
        context.fill(lowerLid, with: .color(.black))
    }
}

// MARK: - Previews

#Preview("Idle") {
    EyeCharacterView(state: .idle, size: CGSize(width: 300, height: 150))
        .background(Color.black)
}

#Preview("Searching") {
    EyeCharacterView(state: .searching, size: CGSize(width: 300, height: 150))
        .background(Color.black)
}

#Preview("Tracking") {
    EyeCharacterView(state: .tracking, size: CGSize(width: 300, height: 150))
        .background(Color.black)
}

#Preview("Closing 50%") {
    EyeCharacterView(state: .closing(progress: 0.5), size: CGSize(width: 300, height: 150))
        .background(Color.black)
}

#Preview("Closed") {
    EyeCharacterView(state: .closed, size: CGSize(width: 300, height: 150))
        .background(Color.black)
}

#Preview("Winking") {
    EyeCharacterView(state: .winking, size: CGSize(width: 300, height: 150))
        .background(Color.black)
}
