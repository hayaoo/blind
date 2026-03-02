import SwiftUI

// MARK: - State

enum EyeCharacterState: Equatable {
    case searching              // .noFace: キョロキョロ探索
    case tracking               // .open: ユーザーにロックオン + 定期まばたき
    case closing(progress: Double)  // .closed: 閉じるアニメーション (0→1)
    case closed                 // 完全に閉じた状態 → ニッコリ
    case winking                // 覚醒ウインク
    case idle                   // デフォルト、中央を向いて待機
}

// MARK: - View

/// EEAAO風ギョロ目キャラクター。
/// まん丸の白目 + まん丸の黒目。移動方向に傾く。
struct EyeCharacterView: View {
    let state: EyeCharacterState
    let size: CGSize
    /// 外部からの傾き(-1..1)。正=右に傾く
    var tiltFactor: CGFloat = 0

    @State private var startDate = Date()
    @State private var winkStartDate: Date?

    /// 傾きの最大角度
    private let maxTiltDegrees: CGFloat = 8

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince(startDate)
            Canvas { context, canvasSize in
                drawEyes(context: context, size: canvasSize, time: time)
            }
        }
        .frame(width: size.width, height: size.height)
        .rotationEffect(.degrees(Double(tiltFactor * maxTiltDegrees)))
        .onChange(of: state) { oldValue, newValue in
            if case .winking = newValue, !(oldValue == .winking) {
                winkStartDate = Date()
            }
        }
    }

    // MARK: - Drawing

    private func drawEyes(context: GraphicsContext, size: CGSize, time: Double) {
        let baseDiameter = min(size.width * 0.38, size.height * 0.80)
        let eyeWidth = baseDiameter
        let eyeHeight = baseDiameter * 1.15
        let eyeGap: CGFloat = -4
        let pupilDiameter = baseDiameter * 0.40

        let (pupilOffset, lidClose, leftLidClose, rightLidClose) = computeAnimParams(
            time: time, eyeDiameter: baseDiameter
        )

        let centerY = size.height / 2
        let leftCenterX = size.width / 2 - eyeGap / 2 - eyeWidth / 2
        let rightCenterX = size.width / 2 + eyeGap / 2 + eyeWidth / 2

        let leftLid = leftLidClose ?? lidClose
        let rightLid = rightLidClose ?? lidClose

        // ニッコリ判定: 完全に閉じた目はスマイルライン描画
        let leftSmile = leftLid >= 0.95
        let rightSmile = rightLid >= 0.95

        drawGooglyEye(
            context: context,
            center: CGPoint(x: leftCenterX, y: centerY),
            eyeWidth: eyeWidth, eyeHeight: eyeHeight,
            pupilDiameter: pupilDiameter,
            pupilOffset: pupilOffset,
            lidCloseFactor: leftLid,
            smile: leftSmile
        )

        drawGooglyEye(
            context: context,
            center: CGPoint(x: rightCenterX, y: centerY),
            eyeWidth: eyeWidth, eyeHeight: eyeHeight,
            pupilDiameter: pupilDiameter,
            pupilOffset: pupilOffset,
            lidCloseFactor: rightLid,
            smile: rightSmile
        )
    }

    /// (pupilOffset, lidClose, optionalLeftLid, optionalRightLid)
    private func computeAnimParams(
        time: Double,
        eyeDiameter: CGFloat
    ) -> (CGPoint, CGFloat, CGFloat?, CGFloat?) {
        let maxPupilTravel = eyeDiameter * 0.18

        let defaultPupilOffset = CGPoint(x: maxPupilTravel * 0.5, y: -maxPupilTravel * 0.4)

        switch state {
        case .idle:
            return (defaultPupilOffset, 0, nil, nil)

        case .searching:
            let dx = saccadeLayered(time: time, axis: 0) * maxPupilTravel
            let dy = saccadeLayered(time: time, axis: 1) * maxPupilTravel * 0.7
            return (CGPoint(x: dx, y: dy), 0, nil, nil)

        case .tracking:
            let blinkFactor = computeTrackingBlink(time: time)
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
            let rightClose = max(0, 1 - min(elapsed / 0.5, 1))
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
            return CGFloat(t < 0.5 ? t * 2 : (1 - t) * 2)
        }
        return 0
    }

    private func saccadeLayered(time: Double, axis: Int) -> CGFloat {
        let primary = saccadeSegment(
            time: time,
            holdDuration: axis == 0 ? 1.8 : 2.1,
            moveDuration: 0.15,
            seed: axis == 0 ? 0.73 : 1.37
        )
        let micro = saccadeSegment(
            time: time,
            holdDuration: axis == 0 ? 0.5 : 0.6,
            moveDuration: 0.08,
            seed: axis == 0 ? 3.17 : 2.53
        ) * 0.15
        return primary + micro
    }

    private func saccadeSegment(time: Double, holdDuration: Double, moveDuration: Double, seed: Double) -> CGFloat {
        let cycleDuration = holdDuration + moveDuration
        let cycle = Int(time / cycleDuration)
        let cycleTime = time - Double(cycle) * cycleDuration

        func fixationPoint(_ index: Int) -> Double {
            let hash = sin(Double(index) * seed * 127.1 + seed * 311.7)
            return hash * 0.85
        }

        let from = fixationPoint(cycle)
        let to = fixationPoint(cycle + 1)

        if cycleTime < holdDuration {
            let tremor = sin(time * 23.0 + seed) * 0.02
            return CGFloat(from + tremor)
        } else {
            let t = (cycleTime - holdDuration) / moveDuration
            let smooth = t * t * (3.0 - 2.0 * t)
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
        lidCloseFactor: CGFloat,
        smile: Bool
    ) {
        let eyeRadiusX = eyeWidth / 2
        let eyeRadiusY = eyeHeight / 2

        if smile {
            // ニッコリ: 白目・瞳を描画せず、スマイルラインのみ
            drawSmileLine(
                context: context,
                center: center,
                eyeRadiusX: eyeRadiusX,
                eyeRadiusY: eyeRadiusY
            )
            return
        }

        // --- 白目（角丸の緩やかなスクイークル風）---
        let eyeRect = CGRect(
            x: center.x - eyeRadiusX,
            y: center.y - eyeRadiusY,
            width: eyeWidth,
            height: eyeHeight
        )
        let cornerRadius = min(eyeRadiusX, eyeRadiusY) * 0.88
        let eyePath = Path(roundedRect: eyeRect, cornerRadius: cornerRadius, style: .continuous)

        context.fill(eyePath, with: .color(.white))
        context.stroke(eyePath, with: .color(.black), lineWidth: eyeWidth * 0.04)

        // --- クリッピング: 白目の円内に制限 ---
        var clipped = context
        clipped.clipToLayer { clipCtx in
            clipCtx.fill(eyePath, with: .color(.white))
        }

        // --- 瞳 ---
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
        clipped.fill(Path(ellipseIn: pupilRect), with: .color(.black))

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

    // MARK: - Smile Line（ニッコリ）

    /// 閉じた目 → 上向き弧の白いスマイルライン
    private func drawSmileLine(
        context: GraphicsContext,
        center: CGPoint,
        eyeRadiusX: CGFloat,
        eyeRadiusY: CGFloat
    ) {
        let smileWidth = eyeRadiusX * 1.6
        let smileHeight = eyeRadiusY * 0.5  // 弧の高さ

        var path = Path()
        path.move(to: CGPoint(x: center.x - smileWidth / 2, y: center.y))
        // 上に凸のカーブ（ニッコリ = 逆U字）
        path.addQuadCurve(
            to: CGPoint(x: center.x + smileWidth / 2, y: center.y),
            control: CGPoint(x: center.x, y: center.y - smileHeight)
        )

        context.stroke(
            path,
            with: .color(.white),
            lineWidth: eyeRadiusX * 0.12
        )
    }

    // MARK: - Eyelids

    private func drawEyelids(
        context: GraphicsContext,
        center: CGPoint,
        eyeRadiusX: CGFloat,
        eyeRadiusY: CGFloat,
        closeFactor: CGFloat
    ) {
        let rx = eyeRadiusX * 1.05
        let ry = eyeRadiusY * 1.05

        // 上まぶた（閉じるにつれ上に凸 = ニッコリカーブに変化）
        let upperRestY = center.y - ry
        let upperTargetY = center.y
        let upperY = upperRestY + (upperTargetY - upperRestY) * closeFactor

        // 上まぶた（常に上向きカーブ = ニッコリ方向）
        let upBulge = ry * 0.4
        let upperControlY = upperY - upBulge

        var upperLid = Path()
        upperLid.move(to: CGPoint(x: center.x - rx, y: upperRestY - 2))
        upperLid.addLine(to: CGPoint(x: center.x + rx, y: upperRestY - 2))
        upperLid.addLine(to: CGPoint(x: center.x + rx, y: upperY))
        upperLid.addQuadCurve(
            to: CGPoint(x: center.x - rx, y: upperY),
            control: CGPoint(x: center.x, y: upperControlY)
        )
        upperLid.closeSubpath()
        context.fill(upperLid, with: .color(.black))

        // まぶたの白い線（閉じ具合に応じて不透明度UP）
        if closeFactor > 0.3 {
            let lineOpacity = min(1.0, (closeFactor - 0.3) / 0.7)
            var lidLine = Path()
            lidLine.move(to: CGPoint(x: center.x - rx * 0.8, y: upperY))
            lidLine.addQuadCurve(
                to: CGPoint(x: center.x + rx * 0.8, y: upperY),
                control: CGPoint(x: center.x, y: upperControlY - ry * 0.08)
            )
            context.stroke(
                lidLine,
                with: .color(.white.opacity(lineOpacity * 0.7)),
                lineWidth: rx * 0.06
            )
        }

        // 下まぶた
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

#Preview("Closed - Smile") {
    EyeCharacterView(state: .closed, size: CGSize(width: 300, height: 150))
        .background(Color.black)
}

#Preview("Winking") {
    EyeCharacterView(state: .winking, size: CGSize(width: 300, height: 150))
        .background(Color.black)
}

#Preview("Tilted Right") {
    EyeCharacterView(state: .idle, size: CGSize(width: 300, height: 150), tiltFactor: 0.7)
        .background(Color.black)
}
